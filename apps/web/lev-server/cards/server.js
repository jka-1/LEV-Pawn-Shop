// server.js (users + urls + iOS key + password reset + Gemini pricing)
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const { MongoClient, ObjectId } = require('mongodb');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Resend } = require('resend');
const crypto = require('crypto');

// Optional: built-in fetch is available on Node 18+. If not, add node-fetch.
const hasFetch = typeof fetch === 'function';

//------ RESEND -------
const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;
console.log('Resend configured:', !!process.env.RESEND_API_KEY);
const EMAIL_FROM = process.env.EMAIL_FROM || 'no-reply@bibe.stream';
const VERIFY_TOKEN_TTL_HOURS = parseInt(process.env.VERIFY_TOKEN_TTL_HOURS || '24', 10);

// how long password-reset links are valid (in hours)
const RESET_TOKEN_TTL_HOURS = parseInt(process.env.RESET_TOKEN_TTL_HOURS || '1', 10);

const app = express();
app.set('trust proxy', 1);

// ----- ENV -----
const {
  PORT = 5000,
  APP_BASE_URL = 'https://app.yourdomain.com',

  MONGODB_URI,
  MONGODB_DB = 'SafePawnShop',
  MONGODB_USERS_COLL = 'storefront_users',
  MONGODB_URLS_COLL = 'storefront_urls',

  JWT_ACCESS_SECRET,
  JWT_REFRESH_SECRET,
  ACCESS_TOKEN_TTL = '15m',
  REFRESH_TOKEN_TTL = '30d',

  COOKIE_DOMAIN = 'app.yourdomain.com',
  COOKIE_SECURE = 'true',
  COOKIE_SAME_SITE = 'lax'
} = process.env;

// ----- MIDDLEWARE -----
app.use(cors({ origin: APP_BASE_URL, credentials: true }));
//app.use(express.json());
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ limit: '10mb', extended: true }))

app.use(cookieParser());

/* --------------- SWIFT / iOS --------------- */
// Require a valid iOS mobile key on specific endpoints
function requireAuthOrIos(req, res, next) {
  const got = req.header('x-ios-key');
  const ok = got && got === process.env.IOS_API_KEY;
  if (ok) {
    console.log('AUTH: iOS key path →', req.method, req.path);
    return next();
  }
  console.log(
    'AUTH: cookie path →',
    req.method,
    req.path,
    'cookies?',
    !!req.cookies?.accessToken
  );
  return requireAuth(req, res, next);
}

// ----- JWT helpers -----
const signAccess = (p) => jwt.sign(p, JWT_ACCESS_SECRET, { expiresIn: ACCESS_TOKEN_TTL });
const signRefresh = (p) => jwt.sign(p, JWT_REFRESH_SECRET, { expiresIn: REFRESH_TOKEN_TTL });

function setAuthCookies(res, accessToken, refreshToken) {
  const base = {
    httpOnly: true,
    sameSite: COOKIE_SAME_SITE,
    secure: COOKIE_SECURE === 'true',
    domain: COOKIE_DOMAIN || undefined,
    path: '/'
  };
  res.cookie('accessToken', accessToken, base);
  res.cookie('refreshToken', refreshToken, base);
}

function clearAuthCookies(res) {
  const base = {
    httpOnly: true,
    sameSite: COOKIE_SAME_SITE,
    secure: COOKIE_SECURE === 'true',
    domain: COOKIE_DOMAIN || undefined,
    path: '/'
  };
  res.clearCookie('accessToken', base);
  res.clearCookie('refreshToken', base);
}

function requireAuth(req, res, next) {
  const t = req.cookies?.accessToken;
  if (!t) return res.status(401).json({ error: 'AccessTokenMissing' });
  try {
    req.user = jwt.verify(t, JWT_ACCESS_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'AccessTokenExpired' });
  }
}

// ----- DB CONNECT (once) -----
let db, Users, Urls, EmailTokens, PasswordTokens;
(async () => {
  try {
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(MONGODB_DB);
    Users = db.collection(MONGODB_USERS_COLL);
    Urls = db.collection(MONGODB_URLS_COLL);
    await Urls.createIndex({ createdAt: -1 });

    EmailTokens = db.collection('email_tokens');
    await EmailTokens.createIndex({ token: 1 }, { unique: true });
    await EmailTokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    // for 6-digit code lookup
    await EmailTokens.createIndex({ userId: 1, code: 1 });

    PasswordTokens = db.collection('password_tokens');
    await PasswordTokens.createIndex({ token: 1 }, { unique: true });
    await PasswordTokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

    console.log(
      `Mongo OK → db=${MONGODB_DB}, users=${MONGODB_USERS_COLL}, urls=${MONGODB_URLS_COLL}`
    );
  } catch (err) {
    console.error('Mongo connection error:', err);
    process.exit(1);
  }
})();

/* ---------------- Gemini price estimation ---------------- */
async function fetchImageAsBase64(url) {
  try {
    const resp = await (hasFetch ? fetch(url) : null);
    if (!resp || !resp.ok) return null;
    const buf = await resp.arrayBuffer();
    const b = Buffer.from(buf);
    const mime = url.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    return { mimeType: mime, data: b.toString('base64') };
  } catch (e) {
    console.error('fetchImageAsBase64 error:', e);
    return null;
  }
}

async function estimatePriceWithGemini({ name, description, imageUrl, imageBase64, location }) {
  const apiKey = process.env.GOOGLE_API_KEY || process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('Missing GOOGLE_API_KEY (or GEMINI_API_KEY) in environment');
  }

  let imagePart = null;
  if (imageBase64 && imageBase64.data) {
    imagePart = {
      inline_data: {
        mime_type: imageBase64.mimeType || 'image/jpeg',
        data: imageBase64.data
      }
    };
  } else if (imageUrl) {
    const fetched = await fetchImageAsBase64(imageUrl);
    if (fetched) imagePart = { inline_data: fetched };
  }

  const locText =
    location &&
    (location.city || location.state || location.country || (location.lat && location.lng))
      ? `User location: ${
          [location.city, location.state, location.country].filter(Boolean).join(', ') ||
          `${location.lat},${location.lng}`
        }.`
      : 'User location not provided.';

  const prompt = [
    'Role: You are a pricing assistant for a pawn shop. Task: Given an item name, description, and an image and maybe user location, estimate a fair CASH OFFER price in USD for immediate purchase and a typical LOCAL LISTING range. Price should be around the msrp range if item is new, and in mint condition. take penalties on the price based on damages listed in the description.',
    'Method: Prioritize valid local searches near the provided location (Craigslist, Facebook Marketplace, OfferUp, eBay local, Amazon, etc.). Find at least 2 valid listings of the item through the websites given. If no location is available, use U.S. national averages. Consider brand/model, condition, age, accessories, provenance, and demand.',
    'Output: Return STRICT JSON only: { "price": number, "low": number, "high": number, "currency": "USD", "confidence": number (0-1), "explanation": string, "comparables"?: [{"title": string, "source": string, "link": string, "price": number}] }',
    'Style: No additional text, no markdown, no units except the currency string. Do not include disclaimers; keep explanation concise and factual.',
    `Item name: ${name || ''}`,
    `Description: ${description || ''}`,
    locText
  ].join('\n');

  const body = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }, ...(imagePart ? [imagePart] : [])]
      }
    ],
    generationConfig: {
      temperature: 0.4
    }
  };

  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
  const url = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${encodeURIComponent(
    apiKey
  )}`;

  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });

  if (!resp.ok) {
    const errText = await resp.text().catch(() => '');
    throw new Error(`Gemini error HTTP ${resp.status}: ${errText}`);
  }

  const data = await resp.json();
  if (!data) throw new Error('Gemini request failed');

  const text =
    data?.candidates?.[0]?.content?.parts?.[0]?.text ||
    data?.candidates?.[0]?.content?.parts?.[0]?.data ||
    '';

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    const m = typeof text === 'string' ? text.match(/\{[\s\S]*\}/) : null;
    parsed = m ? JSON.parse(m[0]) : null;
  }

  if (!parsed || typeof parsed.price !== 'number') {
    throw new Error('Invalid response from Gemini');
  }
  return parsed;
}

// NOTE: currently open to unauthenticated callers.
// If you want to lock it down, change to: app.post('/api/estimate-price', requireAuthOrIos, ...)
app.post('/api/estimate-price', async (req, res) => {
  try {
    const apiKeyPresent = !!(process.env.GOOGLE_API_KEY || process.env.GEMINI_API_KEY);
    if (!apiKeyPresent) {
      return res
        .status(503)
        .json({ error: 'ai_not_configured', message: 'Gemini API key not set' });
    }
    const { name, description, imageUrl, imageBase64, location } = req.body || {};
    if (!name && !description && !imageUrl && !imageBase64) {
      return res.status(400).json({ error: 'Missing item data' });
    }
    const result = await estimatePriceWithGemini({
      name,
      description,
      imageUrl,
      imageBase64,
      location
    });
    return res.status(200).json({ ok: true, ...result });
  } catch (e) {
    console.error('estimate-price error:', e);
    return res.status(500).json({ error: e?.message || 'server_error' });
  }
});

/* ---------------- Storefront APIs (public list/view) ---------------- */
app.get('/api/storefront', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 24, 60);
    const afterId = req.query.afterId;

    const baseFilter = { active: true };
    const filter = afterId
      ? { ...baseFilter, _id: { $lt: new ObjectId(afterId) } }
      : baseFilter;

    const items = await Urls.find(filter, {
      projection: { name: 1, price: 1, description: 1, imageUrl: 1, createdAt: 1, ownerId: 1 }
    })
      .sort({ _id: -1 })
      .limit(limit)
      .toArray();

    const nextCursor = items.length ? String(items[items.length - 1]._id) : null;
    return res.status(200).json({ ok: true, items, nextCursor });
  } catch (e) {
    console.error('storefront list error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

app.get('/api/storefront/:id', async (req, res) => {
  try {
    const item = await Urls.findOne(
      { _id: new ObjectId(req.params.id), active: true },
      { projection: { name: 1, price: 1, description: 1, imageUrl: 1, createdAt: 1 } }
    );
    if (!item) return res.status(404).json({ error: 'not_found' });
    return res.status(200).json({ ok: true, item });
  } catch (e) {
    console.error('storefront item error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

// DELETE storefront item (only the owner can soft-delete; require logged-in user)
// DELETE storefront item
// - Web: must be owner
// - iOS with valid x-ios-key: can delete any item (admin-style), no owner check
app.delete('/api/storefront/:id', requireAuthOrIos, async (req, res) => {
  try {
    const id = req.params.id;
    if (!id) {
      return res.status(400).json({ ok: false, error: 'IdRequired' });
    }

    const _id = new ObjectId(id);

    const doc = await Urls.findOne({ _id });
    if (!doc || doc.active === false) {
      return res.status(404).json({ ok: false, error: 'NotFound' });
    }

    const iosKey = req.header('x-ios-key') || null;
    const isIos = iosKey && iosKey === process.env.IOS_API_KEY;

    console.log('DELETE /api/storefront/:id', {
      id,
      isIos,
      ownerId: doc.ownerId,
      userId: req.user?.uid
    });

    // If this is NOT the iOS key path, enforce owner check (web user)
    if (!isIos) {
      const ownerId = doc.ownerId && String(doc.ownerId);
      const currentUserId = req.user?.uid && String(req.user.uid);

      if (!ownerId || ownerId !== currentUserId) {
        console.log('❌ NotOwner', { ownerId, currentUserId });
        return res.status(403).json({ ok: false, error: 'NotOwner' });
      }
    }

    // Either iOS (with key) or the owner reached here
    await Urls.updateOne({ _id }, { $set: { active: false } });

    console.log('✅ Deleted storefront item', { id });
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('storefront delete error:', e);
    return res.status(500).json({ ok: false, error: 'server_error' });
  }
});

/* ---------------- Email helpers ---------------- */
function renderVerifyEmailHTML({ name, verifyUrl, brand = 'QuickPawn', verificationCode }) {
  const preheader = `Verify your email for ${brand}`;
  return `
  <!doctype html>
  <html>
  <body style="margin:0;padding:0;background:#111827;">
    <div style="display:none;opacity:0;visibility:hidden;overflow:hidden;height:0;width:0;max-height:0;max-width:0;">
      ${preheader}
    </div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#111827;padding:24px 0;">
      <tr>
        <td align="center">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:96%;background:#ffffff;border-radius:12px;border:1px solid #e5e7eb;" bgcolor="#ffffff">
            <tr>
              <td style="padding:28px 28px 8px 28px; text-align:left;">
                <div style="font:600 18px system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">${brand}</div>
              </td>
            </tr>
            <tr>
              <td style="padding:0 28px 8px 28px;">
                <h1 style="margin:0;font:700 22px system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">Verify your email</h1>
              </td>
            </tr>
            <tr>
              <td style="padding:0 28px;">
                <p style="margin:0 0 16px 0;font:400 16px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">
                  Hello ${name || 'there'}, click the button below to verify your email for <strong>${brand}</strong>.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:8px 28px 20px 28px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0"
                       style="border-collapse:separate;" bgcolor="#D97706">
                  <tr>
                    <td align="center" bgcolor="#D97706"
                        style="background:#D97706;background-color:#D97706;border:1px solid #111111;border-radius:8px;">
                      <a href="${verifyUrl}" target="_blank" role="button"
                         style="display:block;min-width:220px;padding:12px 18px;border-radius:8px;
                                font:700 16px system-ui,Segoe UI,Roboto,Arial,sans-serif;text-decoration:none;
                                color:#111111; background:transparent; background-color:transparent; border:0; -webkit-text-size-adjust:none;">
                        <span style="color:#111111 !important; text-decoration:none !important;">Verify Email</span>
                      </a>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

            ${
              verificationCode
                ? `
            <tr>
              <td style="padding:0 28px 14px 28px;">
                <p style="margin:0 0 8px 0;font:400 14px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#374151;">
                  Or enter this verification code in the app:
                </p>
                <p style="margin:0 0 16px 0;font:700 20px/1.6 ui-monospace,Consolas,Menlo,monospace;color:#111827;letter-spacing:0.18em;">
                  ${verificationCode}
                </p>
              </td>
            </tr>
                `
                : ''
            }

            <tr>
              <td style="padding:0 28px 14px 28px;">
                <p style="margin:0 0 8px 0;font:400 14px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#374151;">
                  Or copy &amp; paste this link:
                </p>
                <p style="word-break:break-all;margin:0 0 16px 0;font:400 13px/1.6 ui-monospace,Consolas,Menlo,monospace;color:#1f2937;">
                  ${verifyUrl}
                </p>
                <p style="margin:0 0 20px 0;font:400 13px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#6b7280;">
                  This link and code expire in ${VERIFY_TOKEN_TTL_HOURS} hour(s).
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 28px 28px 28px;border-top:1px solid #e5e7eb;">
                <p style="margin:0;font:400 12px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#6b7280;">
                  If you didn’t create an account, you can safely ignore this email.
                </p>
              </td>
            </tr>
          </table>
          <div style="color:#9ca3af;font:400 12px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;margin-top:12px;">
            © ${new Date().getFullYear()} ${brand}
          </div>
        </td>
      </tr>
    </table>
  </body>
  </html>`;
}

function renderResetEmailHTML({ name, resetUrl, brand = 'QuickPawn' }) {
  const safeName = name || 'there';
  return `
  <!doctype html>
  <html>
  <body style="margin:0;padding:0;background:#111827;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#111827;padding:24px 0;">
      <tr>
        <td align="center">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="width:600px;max-width:96%;background:#ffffff;border-radius:12px;border:1px solid #e5e7eb;" bgcolor="#ffffff">
            <tr>
              <td style="padding:24px 24px 8px 24px;font:600 18px system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">
                ${brand}
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 8px 24px;">
                <h1 style="margin:0;font:700 22px system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">
                  Reset your password
                </h1>
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 16px 24px;font:400 15px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#111827;">
                Hello ${safeName}, click the button below to choose a new password for your ${brand} account.
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 20px 24px;">
                <a href="${resetUrl}" target="_blank"
                   style="display:inline-block;padding:10px 18px;border-radius:8px;
                          background:#D97706;color:#111111;font:600 15px system-ui,Segoe UI,Roboto,Arial,sans-serif;
                          text-decoration:none;border:1px solid #111111;">
                  Reset password
                </a>
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 14px 24px;font:400 13px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#4b5563;">
                Or copy and paste this link into your browser:<br />
                <span style="word-break:break-all;font-family:ui-monospace,Consolas,Menlo,monospace;">
                  ${resetUrl}
                </span>
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 20px 24px;font:400 12px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#6b7280;">
                This link will expire in ${RESET_TOKEN_TTL_HOURS} hour(s). If you didn't request this, you can ignore this email.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>`;
}

async function sendEmail({ to, subject, html, text }) {
  if (!resend) throw new Error('RESEND_NOT_CONFIGURED');
  const result = await resend.emails.send({
    from: EMAIL_FROM,
    to,
    subject,
    html,
    text
  });
  if (result?.error) throw new Error('RESEND_ERROR: ' + JSON.stringify(result.error));
  console.log('Resend id:', result?.data?.id || '(no id)');
  return result;
}

async function createAndSendVerifyToken(user) {
  const token = crypto.randomBytes(32).toString('hex');
  const now = Date.now();
  const expiresAt = new Date(now + VERIFY_TOKEN_TTL_HOURS * 3600 * 1000);

  // 6-digit numeric verification code
  const code = String(Math.floor(100000 + Math.random() * 900000));

  await EmailTokens.insertOne({
    userId: user._id,
    token,
    code,
    createdAt: new Date(now),
    expiresAt
  });

  const webBase =
    process.env.PUBLIC_WEB_BASE_URL || process.env.APP_BASE_URL || 'https://bibe.stream';
  const apiBase = process.env.PUBLIC_API_BASE_URL || webBase;
  const verifyUrl = `${apiBase}/api/verify-email?token=${token}`;

  const html = renderVerifyEmailHTML({
    name: user.FirstName || user.Login || '',
    verifyUrl,
    brand: 'QuickPawn',
    verificationCode: code
  });

  const text =
    `Verify your email for QuickPawn\n\n` +
    `Hello ${user.FirstName || user.Login || 'there'},\n\n` +
    `Click the link below to verify your email:\n${verifyUrl}\n\n` +
    `Or enter this verification code in the app: ${code}\n\n` +
    `This link and code expire in ${VERIFY_TOKEN_TTL_HOURS} hour(s).`;

  return sendEmail({
    to: user.Email,
    subject: 'Verify your QuickPawn email',
    html,
    text
  });
}

async function createAndSendPasswordResetToken(user) {
  const token = crypto.randomBytes(32).toString('hex');
  const now = Date.now();
  const expiresAt = new Date(now + RESET_TOKEN_TTL_HOURS * 3600 * 1000);

  await PasswordTokens.insertOne({
    userId: user._id,
    token,
    createdAt: new Date(now),
    expiresAt
  });

  const webBase =
    process.env.PUBLIC_WEB_BASE_URL || process.env.APP_BASE_URL || 'https://bibe.stream';
  const resetUrl = `${webBase}/reset-password?token=${token}`;

  const html = renderResetEmailHTML({
    name: user.FirstName || user.Login || '',
    resetUrl,
    brand: 'QuickPawn'
  });

  await sendEmail({
    to: user.Email,
    subject: 'Reset your QuickPawn password',
    html
  });
}

/* ---------------- Username / email recovery ---------------- */
app.post('/api/recover-identity', async (req, res) => {
  try {
    const { value } = req.body || {};
    if (!value || typeof value !== 'string') {
      return res.status(400).json({ error: 'ValueRequired' });
    }

    const query = value.trim();
    if (!query) {
      return res.status(400).json({ error: 'ValueRequired' });
    }

    const user = await Users.findOne(
      { $or: [{ Email: query }, { Login: query }] },
      { projection: { Email: 1, Login: 1 } }
    );

    if (!user) {
      return res.status(200).json({ ok: false });
    }

    return res.status(200).json({
      ok: true,
      email: user.Email || '',
      username: user.Login || ''
    });
  } catch (e) {
    console.error('recover-identity error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

/* ================= USERS (Auth) ================= */

app.post('/api/register', async (req, res) => {
  try {
    const { login, email, password, firstName = '', lastName = '' } = req.body;
    if (!login || !email || !password)
      return res.status(400).json({ error: 'Missing required fields' });

    const exists = await Users.findOne({ $or: [{ Login: login }, { Email: email }] });
    if (exists) return res.status(400).json({ error: 'UserExists' });

    const hash = await bcrypt.hash(password, 10);
    const user = {
      Login: login,
      Email: email,
      PasswordHash: hash,
      FirstName: firstName,
      LastName: lastName,
      Verified: false,
      CreatedAt: new Date()
    };
    const ins = await Users.insertOne(user);

    try {
      await createAndSendVerifyToken({ ...user, _id: ins.insertedId });
    } catch (e) {
      console.warn('verify email error:', e.toString());
    }

    return res.status(200).json({ message: 'Registered', id: ins.insertedId.toString() });
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { loginOrEmail, password } = req.body;
    if (!loginOrEmail || !password)
      return res.status(400).json({ error: 'Missing credentials' });

    const user = await Users.findOne({
      $or: [{ Login: loginOrEmail }, { Email: loginOrEmail }]
    });
    if (!user) return res.status(401).json({ error: 'InvalidCredentials' });

    const ok = await bcrypt.compare(password, user.PasswordHash || '');
    if (!ok) return res.status(401).json({ error: 'InvalidCredentials' });

    if (!user.Verified) return res.status(403).json({ error: 'EMAIL_NOT_VERIFIED' });

    const base = { uid: user._id.toString(), login: user.Login };
    const at = signAccess(base);
    const rt = signRefresh(base);
    setAuthCookies(res, at, rt);

    return res.status(200).json({
      id: user._id.toString(),
      email: user.Email || '',
      username: user.Login || '',
      login: user.Login || '',
      firstName: user.FirstName || '',
      lastName: user.LastName || '',
      error: ''
    });
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});

app.post('/api/refresh', (req, res) => {
  const rt = req.cookies?.refreshToken;
  if (!rt) return res.status(401).json({ error: 'RefreshTokenMissing' });
  try {
    const p = jwt.verify(rt, JWT_REFRESH_SECRET);
    const at = signAccess({ uid: p.uid, login: p.login });
    setAuthCookies(res, at, rt);
    return res.status(200).json({ message: 'AccessTokenRefreshed' });
  } catch {
    clearAuthCookies(res);
    return res.status(401).json({ error: 'RefreshTokenInvalid' });
  }
});

app.post('/api/logout', (_req, res) => {
  clearAuthCookies(res);
  return res.status(200).json({ message: 'LoggedOut' });
});

app.get('/api/profile', requireAuth, async (req, res) => {
  const user = await Users.findOne(
    { _id: new ObjectId(req.user.uid) },
    { projection: { PasswordHash: 0 } }
  );
  if (!user) return res.status(404).json({ error: 'UserNotFound' });

  return res.status(200).json({
    user: {
      id: user._id.toString(),
      email: user.Email || '',
      username: user.Login || '',
      login: user.Login || '',
      firstName: user.FirstName || '',
      lastName: user.LastName || '',
      verified: !!user.Verified,
      createdAt: user.CreatedAt
    }
  });
});

/* ---------------- Verify & resend routes ---------------- */

// Browser link verify (token)
app.get('/api/verify-email', async (req, res) => {
  try {
    const { token } = req.query;
    if (!token || typeof token !== 'string') return res.status(400).send('Missing token');

    const rec = await EmailTokens.findOne({ token });
    if (!rec) return res.status(400).send('Invalid or expired token');

    if (rec.expiresAt && rec.expiresAt < new Date()) {
      await EmailTokens.deleteOne({ _id: rec._id });
      return res.status(400).send('Token expired');
    }

    await Users.updateOne({ _id: rec.userId }, { $set: { Verified: true } });

    // Invalidate all tokens for this user
    await EmailTokens.deleteMany({ userId: rec.userId });

    const dest =
      (process.env.PUBLIC_WEB_BASE_URL ||
        process.env.APP_BASE_URL ||
        'https://bibe.stream') + '/login?verified=1';
    return res.redirect(dest);
  } catch (e) {
    console.error('verify-email error:', e);
    return res.status(500).send('Server error');
  }
});

// verify with 6-digit code (iOS)
app.post('/api/verify-email-code', async (req, res) => {
  try {
    const { email, code } = req.body || {};
    if (!email || !code) {
      return res.status(400).json({ error: 'MissingFields' });
    }

    const user = await Users.findOne({ Email: email });
    if (!user) {
      // Avoid leaking whether the email exists
      return res.status(400).json({ error: 'InvalidCode' });
    }

    const codeStr = String(code).trim();
    if (!codeStr) {
      return res.status(400).json({ error: 'InvalidCode' });
    }

    const rec = await EmailTokens.findOne({
      userId: user._id,
      code: codeStr
    });

    if (!rec || (rec.expiresAt && rec.expiresAt < new Date())) {
      if (rec?._id) {
        await EmailTokens.deleteOne({ _id: rec._id });
      }
      return res.status(400).json({ error: 'InvalidOrExpiredCode' });
    }

    await Users.updateOne({ _id: user._id }, { $set: { Verified: true } });

    // Invalidate all outstanding verification tokens for this user
    await EmailTokens.deleteMany({ userId: user._id });

    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('verify-email-code error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

app.post('/api/resend-verification', async (req, res) => {
  try {
    const { email } = req.body || {};
    if (!email) return res.status(400).json({ error: 'EmailRequired' });

    const user = await Users.findOne({ Email: email });
    if (!user) return res.status(404).json({ error: 'UserNotFound' });
    if (user.Verified) return res.status(200).json({ ok: true, message: 'AlreadyVerified' });

    await EmailTokens.deleteMany({ userId: user._id });
    await createAndSendVerifyToken(user);
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('resend-verification error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

/* ---------------- Password reset routes ---------------- */
app.post('/api/forgot-password', async (req, res) => {
  try {
    const { email } = req.body || {};
    if (!email) {
      return res.status(400).json({ error: 'EmailRequired' });
    }

    const user = await Users.findOne({ Email: email });

    // if user not found or not verified, respond ok anyway (no leak)
    if (!user || !user.Verified) {
      return res.status(200).json({ ok: true });
    }

    try {
      await createAndSendPasswordResetToken(user);
    } catch (err) {
      console.error('forgot-password send error:', err);
    }

    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('forgot-password error:', e);
    return res.status(200).json({ ok: true });
  }
});

app.post('/api/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body || {};
    if (!token || !password) {
      return res.status(400).json({ error: 'MissingFields' });
    }

    const rec = await PasswordTokens.findOne({ token });
    if (!rec || (rec.expiresAt && rec.expiresAt < new Date())) {
      if (rec?._id) {
        await PasswordTokens.deleteOne({ _id: rec._id });
      }
      return res.status(400).json({ error: 'InvalidOrExpiredToken' });
    }

    const hash = await bcrypt.hash(password, 10);
    await Users.updateOne({ _id: rec.userId }, { $set: { PasswordHash: hash } });

    await PasswordTokens.deleteMany({ userId: rec.userId });

    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('reset-password error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});

/* ---------------- Cloudinary + protected storefront create ---------------- */
app.post('/api/uploads/sign', requireAuthOrIos, (req, res) => {
  try {
    const timestamp = Math.floor(Date.now() / 1000);
    const folder = process.env.CLOUDINARY_FOLDER || 'storefront';

    const paramsToSign = { timestamp, folder };
    const signature = require('cloudinary').v2.utils.api_sign_request(
      paramsToSign,
      process.env.CLOUDINARY_API_SECRET
    );

    res.json({
      ok: true,
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      timestamp,
      folder,
      signature
    });
  } catch (e) {
    console.error('cloudinary sign error:', e);
    res.status(500).json({ ok: false, error: 'sign_error' });
  }
});

app.post('/api/storefront', requireAuthOrIos, async (req, res) => {
  try {
    const { name, price, description, imageUrl, tags = [], active = true } = req.body || {};
    if (!name || typeof name !== 'string')
      return res.status(400).json({ ok: false, error: 'NameRequired' });
    const p = Number(price);
    if (!Number.isFinite(p) || p < 0)
      return res.status(400).json({ ok: false, error: 'BadPrice' });
    if (!imageUrl || typeof imageUrl !== 'string')
      return res.status(400).json({ ok: false, error: 'ImageRequired' });

    // add ownerId when request is from cookie-auth user
    const ownerId = req.user?.uid || null;

    const doc = {
      name: name.trim(),
      price: p,
      description: (description && String(description).trim()) || null,
      imageUrl: imageUrl.trim(),
      tags: Array.isArray(tags) ? tags.slice(0, 20) : [],
      active: !!active,
      createdAt: new Date(),
      ownerId
    };

    const ins = await Urls.insertOne(doc);
    return res.status(200).json({ ok: true, id: ins.insertedId.toString() });
  } catch (e) {
    console.error('storefront create error:', e);
    return res.status(500).json({ ok: false, error: 'server_error' });
  }
});

/* ---------------- Start server ---------------- */
app.listen(PORT, () => {
  const base =
    process.env.PUBLIC_API_BASE_URL || process.env.APP_BASE_URL || 'http://localhost:' + PORT;
  console.log(`API listening on ${base}`);
});
