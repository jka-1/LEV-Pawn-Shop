// src/pages/ResetPasswordPage.tsx
import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import NavBar from "../components/NavBar";

const API_BASE = import.meta.env.VITE_API_BASE || "";

function useQueryToken() {
  const { search } = useLocation();
  const params = new URLSearchParams(search);
  return params.get("token") || "";
}

export default function ResetPasswordPage() {
  const navigate = useNavigate();
  const token = useQueryToken();

  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);

  const [missingToken, setMissingToken] = useState(false);
  useEffect(() => {
    if (!token) setMissingToken(true);
  }, [token]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setDone(false);

    if (!token) {
      setError("Reset link is missing or invalid.");
      return;
    }
    if (password.length < 6) {
      setError("Please choose a password at least 6 characters long.");
      return;
    }
    if (password !== confirm) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/reset-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ token, password }),
      });

      if (!res.ok) {
        const payload = await res.json().catch(() => null);
        const code = payload?.error || "";
        let msg = "This reset link is invalid or has expired.";
        if (code !== "InvalidOrExpiredToken") {
          msg = "Unable to reset password. Please request a new link.";
        }
        throw new Error(msg);
      }

      setDone(true);
      // optional: auto-redirect after a delay
      // setTimeout(() => navigate("/login"), 2000);
    } catch (err: any) {
      setError(err?.message || "Unable to reset password. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page page--auth">
      <NavBar />

      <main className="login-neon">
        <section className="neon-stack">
          {/* Hero text */}
          <div className="neon-hero__inner">
            <div className="neon-logo" aria-hidden />
            <h1 className="neon-title">
              LEV
              <span className="neon-title__accent"> • choose new password</span>
            </h1>
            <p className="neon-subtitle">
              Enter a new password for your account. After saving, you&apos;ll be able
              to sign in with it right away.
            </p>
            <ul className="neon-points">
              <li>Reset links can only be used once</li>
              <li>Old reset links are invalidated automatically</li>
              <li>Your new password is stored using strong hashing</li>
            </ul>
          </div>

          {/* Card */}
          <div className="neon-card">
            {missingToken ? (
              <div className="auth__form">
                <div className="auth__legend">Invalid link</div>
                <p style={{ marginBottom: "1rem" }}>
                  This reset link is missing or invalid. Please request a new link from
                  the{" "}
                  <Link to="/forgot-password" className="neon-link">
                    Forgot password
                  </Link>{" "}
                  page.
                </p>
                <Link to="/login" className="neon-link">
                  Back to sign in
                </Link>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="auth__form">
                <div className="auth__legend">Set a new password</div>

                <div className="form__group">
                  <label htmlFor="newPassword">New password</label>
                  <input
                    id="newPassword"
                    type="password"
                    className="input"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                </div>

                <div className="form__group">
                  <label htmlFor="confirmPassword">Confirm password</label>
                  <input
                    id="confirmPassword"
                    type="password"
                    className="input"
                    placeholder="••••••••"
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                </div>

                {error && (
                  <div
                    style={{
                      color: "#f6b3b3",
                      fontSize: ".9rem",
                      marginBottom: ".5rem",
                    }}
                  >
                    {error}
                  </div>
                )}

                {done && (
                  <div
                    style={{
                      color: "#bbf7d0",
                      fontSize: ".9rem",
                      marginBottom: ".5rem",
                    }}
                  >
                    Your password has been updated. You can now sign in with your new
                    password.
                  </div>
                )}

                <button
                  type="submit"
                  className="btn btn--gold btn--block"
                  disabled={loading}
                >
                  {loading ? "Saving…" : "Save new password"}
                </button>

                <p className="neon-card__meta" style={{ marginTop: "0.75rem" }}>
                  Ready to sign in?{" "}
                  <Link to="/login" className="neon-link">
                    Back to sign in
                  </Link>
                </p>
              </form>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}
