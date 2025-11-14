// src/components/Login.tsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { notifyAuthChange } from "../auth";  // ✅ NEW

const API_BASE = import.meta.env.VITE_API_BASE || ""; // e.g. "http://localhost:5000"

type NormalUser = {
  id: string;
  email?: string;
  username?: string;
  login?: string;
  firstName?: string;
  lastName?: string;
};

export default function Login() {
  const [loginName, setLoginName] = useState("");
  const [loginPassword, setLoginPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const navigate = useNavigate();

  async function doLogin(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setLoading(true);

    try {
      const id = (loginName || "").trim();
      const pwd = (loginPassword || "").trim();

      const res = await fetch(`${API_BASE}/api/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ loginOrEmail: id, password: pwd }),
      });

      if (!res.ok) {
        const ct = res.headers.get("content-type") || "";
        const payload = ct.includes("application/json")
          ? await res.json()
          : await res.text();
        const code = typeof payload === "string" ? payload : payload?.error || "";

        let message = "Login failed. Please try again.";
        if (code === "Missing credentials") message = "Please enter your email/username and password.";
        else if (code === "InvalidCredentials") message = "Incorrect email/username or password.";
        else if (code === "EMAIL_NOT_VERIFIED") message = "Please verify your email before logging in.";
        throw new Error(message);
      }

      // Server returns at least: { id, firstName?, lastName? }
      const data = await res.json();

      // Build a normalized user object right away from what we KNOW.
      const isEmail = id.includes("@");
      const immediate: NormalUser = {
        id: data.id,
        email: isEmail ? id : "",
        username: !isEmail ? id : "",
        login: !isEmail ? id : "",
        firstName: data.firstName || "",
        lastName: data.lastName || "",
      };

      // Save immediately so the app can react to "authed"
      localStorage.setItem("user_data", JSON.stringify(immediate));
      notifyAuthChange(); // ✅ tell the app auth changed right now

      // Try to ENRICH from /api/profile (may overwrite user_data)
      try {
        const profRes = await fetch(`${API_BASE}/api/profile`, { credentials: "include" });
        if (profRes.ok) {
          const prof = await resafeJson(profRes); // helper below to avoid throw if body empty
          const p = prof?.user || {};
          const merged: NormalUser = {
            id: immediate.id,
            email: immediate.email || p.Email || p.email || "",
            username: immediate.username || p.Login || p.login || "",
            login: immediate.login || p.Login || p.login || "",
            firstName: immediate.firstName || p.FirstName || p.firstName || "",
            lastName: immediate.lastName || p.LastName || p.lastName || "",
          };
          localStorage.setItem("user_data", JSON.stringify(merged));
          notifyAuthChange(); // ✅ notify again since we overwrote user_data
        }
      } catch {
        // ignore enrichment errors
      }

      navigate("/storefront", { replace: true });
    } catch (e: any) {
      setErr(e?.message || "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={doLogin} className="auth__form">
      <div className="auth__legend">Sign in</div>

      <div className="form__group">
        <label htmlFor="loginName">Email or Username</label>
        <input
          id="loginName"
          className="input"
          type="text"
          placeholder="you@example.com"
          value={loginName}
          onChange={(e) => setLoginName(e.target.value)}
          autoComplete="username"
          required
        />
      </div>

      <div className="form__group">
        <label htmlFor="loginPassword">Password</label>
        <input
          id="loginPassword"
          className="input"
          type="password"
          placeholder="••••••••"
          value={loginPassword}
          onChange={(e) => setLoginPassword(e.target.value)}
          autoComplete="current-password"
          required
        />
      </div>

      {err && (
        <div style={{ color: "#f6b3b3", fontSize: ".9rem", marginBottom: ".5rem" }}>
          {err}
        </div>
      )}

      <button type="submit" className="btn btn--gold btn--block" disabled={loading}>
        {loading ? "Logging in…" : "Login"}
      </button>
    </form>
  );
}

/** Optional tiny helper so a 204/empty body doesn't throw JSON parse error */
async function resafeJson(res: Response) {
  const text = await res.text();
  if (!text) return null;
  try { return JSON.parse(text); } catch { return null; }
}
