// src/pages/ForgotPasswordPage.tsx
import { useState } from "react";
import { Link } from "react-router-dom";
import NavBar from "../components/NavBar";

const API_BASE = import.meta.env.VITE_API_BASE || "";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setDone(false);
    setLoading(true);

    try {
      const res = await fetch(`${API_BASE}/api/forgot-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email: email.trim() }),
      });

      if (!res.ok) {
        throw new Error("Unable to send reset email. Please try again.");
      }

      setDone(true);
    } catch (err: any) {
      setError(err?.message || "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page page--auth">
      <NavBar />

      <main className="login-neon">
        <section className="neon-stack">
          {/* Hero, same vibe as login */}
          <div className="neon-hero__inner">
            <div className="neon-logo" aria-hidden />
            <h1 className="neon-title">
              LEV
              <span className="neon-title__accent"> • password reset</span>
            </h1>
            <p className="neon-subtitle">
              Enter your email and we&apos;ll send a secure link to reset your password.
            </p>
            <ul className="neon-points">
              <li>Links expire after a short time for safety</li>
              <li>You can request a new link anytime</li>
              <li>Your password is stored using strong hashing</li>
            </ul>
          </div>

          {/* Card */}
          <div className="neon-card">
            <form onSubmit={handleSubmit} className="auth__form">
              <div className="auth__legend">Forgot password</div>

              <div className="form__group">
                <label htmlFor="fpEmail">Email</label>
                <input
                  id="fpEmail"
                  type="email"
                  className="input"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoComplete="email"
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
                  If an account exists for that email, we&apos;ve sent a reset link.
                  Please check your inbox.
                </div>
              )}

              <button
                type="submit"
                className="btn btn--gold btn--block"
                disabled={loading}
              >
                {loading ? "Sending link…" : "Send reset link"}
              </button>
            </form>

            <p className="neon-card__meta">
              Remembered your password?{" "}
              <Link to="/login" className="neon-link">
                Back to sign in
              </Link>
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
