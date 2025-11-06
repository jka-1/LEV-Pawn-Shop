// server.js (production-ready; users + urls only)
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const { MongoClient, ObjectId } = require('mongodb');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Resend } = require('resend');
const crypto = require('crypto');

const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;
console.log('Resend configured:', !!process.env.RESEND_API_KEY);
const EMAIL_FROM = process.env.EMAIL_FROM || 'no-reply@bibe.stream';
const VERIFY_TOKEN_TTL_HOURS = parseInt(process.env.VERIFY_TOKEN_TTL_HOURS || '24', 10);

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
app.use(express.json());
app.use(cookieParser());

// ----- DB CONNECT (once) -----
let db, Users, Urls, EmailTokens;
(async () => {
  const client = new MongoClient(MONGODB_URI);
  await client.connect();
  db = client.db(MONGODB_DB);
  Users = db.collection(MONGODB_USERS_COLL);
  Urls = db.collection(MONGODB_URLS_COLL);
  await Urls.createIndex({ createdAt: -1 });

  EmailTokens = db.collection('email_tokens');
  await EmailTokens.createIndex({ token: 1 }, { unique: true });
  await EmailTokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

  console.log(`Mongo OK → db=${MONGODB_DB}, users=${MONGODB_USERS_COLL}, urls=${MONGODB_URLS_COLL}`);
})().catch(err => {
  console.error('Mongo connection error:', err);
  process.exit(1);
});

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

/* ---------------- Storefront APIs (unchanged) ---------------- */
app.get('/api/storefront', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 24, 60);
    const afterId = req.query.afterId;

    const baseFilter = { active: true };
    const filter = afterId
      ? { ...baseFilter, _id: { $lt: new ObjectId(afterId) } }
      : baseFilter;

    const items = await Urls.find(filter, {
      projection: { name: 1, price: 1, description: 1, imageUrl: 1, createdAt: 1 }
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

/* ---------------- iOS demo endpoints (unchanged) ---------------- */
// ... (keep your iOS endpoints as-is)

/* ---------------- Email helpers (drop-in) ---------------- */
function renderVerifyEmailHTML({ name, verifyUrl, brand = "QuickPawn" }) {
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
                  Hello ${name || "there"}, click the button below to verify your email for <strong>${brand}</strong>.
                </p>
              </td>
            </tr>
          <tr>
  <td style="padding:8px 28px 20px 28px;">
    <!--[if mso]>
    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word"
      href="${verifyUrl}" style="height:44px;v-text-anchor:middle;width:220px;"
      arcsize="12%" stroke="t" strokecolor="#111111" fillcolor="#D97706">
      <w:anchorlock/>
      <center style="color:#111111;font-family:Segoe UI,Arial,sans-serif;font-size:16px;font-weight:700;">
        Verify Email
      </center>
    </v:roundrect>
    <![endif]-->

    <!--[if !mso]><!-- -->
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
    <!--<![endif]-->
  </td>
</tr>


            <tr>
              <td style="padding:0 28px 14px 28px;">
                <p style="margin:0 0 8px 0;font:400 14px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#374151;">
                  Or copy &amp; paste this link:
                </p>
                <p style="word-break:break-all;margin:0 0 16px 0;font:400 13px/1.6 ui-monospace,Consolas,Menlo,monospace;color:#1f2937;">
                  ${verifyUrl}
                </p>
                <p style="margin:0 0 20px 0;font:400 13px/1.6 system-ui,Segoe UI,Roboto,Arial,sans-serif;color:#6b7280;">
                  This link expires in 24 hours.
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





async function sendEmail({ to, subject, html }) {
  if (!resend) throw new Error('RESEND_NOT_CONFIGURED');
  const result = await resend.emails.send({
    from: EMAIL_FROM,           // e.g. "QuickPawn <noreply@bibe.stream>"
    to, subject, html
  });
  if (result?.error) throw new Error('RESEND_ERROR: ' + JSON.stringify(result.error));
  console.log('Resend id:', result?.data?.id || '(no id)');
  return result;
}

async function createAndSendVerifyToken(user) {
  const token = crypto.randomBytes(32).toString('hex');
  const now = Date.now();
  const expiresAt = new Date(now + VERIFY_TOKEN_TTL_HOURS * 3600 * 1000);

  await EmailTokens.insertOne({
    userId: user._id,
    token,
    createdAt: new Date(now),
    expiresAt
  });

  const webBase = process.env.PUBLIC_WEB_BASE_URL || process.env.APP_BASE_URL || 'https://bibe.stream';
  const apiBase = process.env.PUBLIC_API_BASE_URL || webBase;
  const verifyUrl = `${apiBase}/api/verify-email?token=${token}`;

  const html = renderVerifyEmailHTML({
    name: user.FirstName || user.Login || "",
    verifyUrl,
    brand: "QuickPawn"
  });

  const text =
    `Verify your email for QuickPawn\n\n` +
    `Hello ${user.FirstName || user.Login || "there"},\n\n` +
    `Click the link below to verify your email:\n${verifyUrl}\n\n` +
    `This link expires in ${VERIFY_TOKEN_TTL_HOURS} hour(s).`;

  if (!resend) throw new Error('RESEND_NOT_CONFIGURED');
  const result = await resend.emails.send({
    from: EMAIL_FROM,               // e.g. "QuickPawn <no-reply@bibe.stream>"
    to: user.Email,
    subject: "Verify your QuickPawn email",
    html,
    text
  });
  if (result?.error) throw new Error('RESEND_ERROR: ' + JSON.stringify(result.error));
  console.log('Resend id:', result?.data?.id || '(no id)');
  return result;
}



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

    const user = await Users.findOne({ $or: [{ Login: loginOrEmail }, { Email: loginOrEmail }] });
    if (!user) return res.status(401).json({ error: 'InvalidCredentials' });

    const ok = await bcrypt.compare(password, user.PasswordHash || '');
    if (!ok) return res.status(401).json({ error: 'InvalidCredentials' });

    if (!user.Verified) return res.status(403).json({ error: 'EMAIL_NOT_VERIFIED' });

    // auth cookies
    const base = { uid: user._id.toString(), login: user.Login };
    const at = signAccess(base);
    const rt = signRefresh(base);
    setAuthCookies(res, at, rt);

    // *** IMPORTANT: return normalized fields so the client can show a name ***
    return res.status(200).json({
      id:        user._id.toString(),
      email:     user.Email || '',
      username:  user.Login || '',
      login:     user.Login || '',    // duplicate for convenience
      firstName: user.FirstName || '',
      lastName:  user.LastName || '',
      error:     ''
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

  // return normalized shape here too
  return res.status(200).json({
    user: {
      id:        user._id.toString(),
      email:     user.Email || '',
      username:  user.Login || '',
      login:     user.Login || '',
      firstName: user.FirstName || '',
      lastName:  user.LastName || '',
      verified:  !!user.Verified,
      createdAt: user.CreatedAt
    }
  });
});

/* ---------------- Verify & resend routes ---------------- */
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
    await EmailTokens.deleteOne({ _id: rec._id });

    const dest = (process.env.PUBLIC_WEB_BASE_URL || process.env.APP_BASE_URL || 'https://bibe.stream') + '/login?verified=1';
    return res.redirect(dest);
  } catch (e) {
    console.error('verify-email error:', e);
    return res.status(500).send('Server error');
  }
});

app.post('/api/resend-verification', async (req, res) => {
  try {
    const { email } = req.body || {};
    if (!email) return res.status(400).json({ error: 'EmailRequired' });

    const user = await Users.findOne({ Email: email });
    if (!user) return res.status(404).json({ error: 'UserNotFound' });
    if (user.Verified) return res.status(200).json({ ok: true, message: 'AlreadyVerified' });

    await EmailTokens.deleteMany({ userId: user._id }); // clean old tokens
    await createAndSendVerifyToken(user);
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('resend-verification error:', e);
    return res.status(500).json({ error: 'server_error' });
  }
});


// --- Cloudinary: short-lived signature for direct uploads ---
app.post('/api/uploads/sign', /* requireAuth, */ (req, res) => {
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

// CREATE storefront item
app.post('/api/storefront', async (req, res) => {
  try {
    const { name, price, description, imageUrl, tags = [], active = true } = req.body || {};
    if (!name || typeof name !== 'string') return res.status(400).json({ ok:false, error:'NameRequired' });
    const p = Number(price);
    if (!Number.isFinite(p) || p < 0) return res.status(400).json({ ok:false, error:'BadPrice' });
    if (!imageUrl || typeof imageUrl !== 'string') return res.status(400).json({ ok:false, error:'ImageRequired' });

    const doc = {
      name: name.trim(),
      price: p,
      description: (description && String(description).trim()) || null,
      imageUrl: imageUrl.trim(),
      tags: Array.isArray(tags) ? tags.slice(0, 20) : [],
      active: !!active,
      createdAt: new Date()
    };

    const ins = await Urls.insertOne(doc);
    return res.status(200).json({ ok:true, id: ins.insertedId.toString() });
  } catch (e) {
    console.error('storefront create error:', e);
    return res.status(500).json({ ok:false, error:'server_error' });
  }
});
app.listen(PORT, () => {
  console.log(`API listening on ${process.env.API_BASE_URL || 'http://localhost:' + PORT}`);
});
