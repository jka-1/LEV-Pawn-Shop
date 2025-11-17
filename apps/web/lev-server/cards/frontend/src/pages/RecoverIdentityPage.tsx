// src/pages/RecoverIdentityPage.tsx
import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import NavBar from "../components/NavBar";

const API_BASE = import.meta.env.VITE_API_BASE || "";

type LookupResult = {
  ok: boolean;
  email?: string;
  username?: string;
};

export default function RecoverIdentityPage() {
  const [value, setValue] = useState("");
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [resultMsg, setResultMsg] = useState<string | null>(null);
  const navigate = useNavigate();

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErr(null);
    setResultMsg(null);

    const v = value.trim();
    if (!v) {
      setErr("Please enter an email or username.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/recover-identity`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ value: v }),
      });

      if (!res.ok) {
        throw new Error("Unable to look up account. Please try again.");
      }

      const data: LookupResult = await res.json();

      if (!data.ok || (!data.email && !data.username)) {
        setResultMsg("We couldn't find an account with that email or username.");
        return;
      }

      const isEmail = v.includes("@");

      if (isEmail && data.username) {
        setResultMsg(
          `We found an account with that email. Your username is “${data.username}”.`
        );
      } else if (!isEmail && data.email) {
        setResultMsg(
          `We found an account with that username. The email on file is “${data.email}”.`
        );
      } else {
        setResultMsg(
          "We found an account, but not enough information to display both fields."
        );
      }
    } catch (e: any) {
      setErr(e?.message || "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page page--auth">
      <NavBar />

      <main className="login-neon auth-neon">
        <section className="auth-stack">
          <div className="auth-header">
            <div className="auth-logo" aria-hidden />
            <h1 className="auth-title">Recover your account</h1>
            <p className="auth-subtitle">
              Enter your <strong>email or username</strong> and we'll show you
              the matching <span className="highlight">username / email</span>{" "}
              if it exists.
            </p>
          </div>

          <div className="auth-card">
            <h2 className="auth-card__title">Lookup account</h2>

            <form onSubmit={handleSubmit} className="auth__form">
              <div className="form__group">
                <label htmlFor="recoverValue">Email or Username</label>
                <input
                  id="recoverValue"
                  className="input"
                  type="text"
                  placeholder="you@example.com or username"
                  value={value}
                  onChange={(e) => setValue(e.target.value)}
                  autoComplete="off"
                />
              </div>

              {err && <div className="form__error">{err}</div>}

              {resultMsg && !err && (
                <div className="form__success">{resultMsg}</div>
              )}

              <button
                type="submit"
                className="btn btn--gold btn--block"
                disabled={loading}
              >
                {loading ? "Looking up…" : "Look up account"}
              </button>

              <p className="auth-footer" style={{ marginTop: "0.75rem" }}>
                Remembered everything?{" "}
                <button
                  type="button"
                  className="link-button"
                  onClick={() => navigate("/login")}
                >
                  Back to sign in
                </button>
              </p>
            </form>
          </div>
        </section>
      </main>
    </div>
  );
}
