import { useState } from "react";
import { useNavigate } from "react-router-dom";

const API_BASE = import.meta.env.VITE_API_BASE || ""; // e.g., http://localhost:5000

export default function Register() {
  const [login, setLogin] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirst] = useState("");
  const [lastName, setLast] = useState("");

  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const navigate = useNavigate();

  async function submit(e: React.FormEvent) {
  e.preventDefault();
  setMsg('');

  // minimal org-style checks
  const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,24}$/; // must have @ and a real TLD
  const PASSWORD_REGEX =
    /^(?=.*\d)(?=.*[ !"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~]).{10,64}$/; // 10–64, 1+ digit, 1+ special

  if (!EMAIL_REGEX.test(email.trim())) {
    setMsg('Please enter a valid email (e.g., name@company.com).');
    return;
  }
  if (!PASSWORD_REGEX.test(password)) {
    setMsg('Password must be 10–64 characters and include a number and a special character.');
    return;
  }

  try {
    const r = await fetch('/api/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        login: login.trim(),
        email: email.trim().toLowerCase(),
        password,
        firstName: firstName.trim(),
        lastName: lastName.trim()
      })
    });

    const data = await r.json().catch(() => ({}));

    if (!r.ok) {
      // minimal friendly messages
      const code = data?.error || '';
      if (code === 'UserExists') setMsg('An account with that username or email already exists.');
      else if (code === 'InvalidEmail') setMsg('Please enter a valid email.');
      else if (code === 'WeakPassword') setMsg('Please choose a stronger password.');
      else setMsg('Registration failed. Please try again.');
      return;
    }

    setMsg('Registration successful! Check your email to verify, then sign in.');
  } catch (err: any) {
    setMsg('Could not reach the server. Please try again.');
  }
}


  return (
    <form onSubmit={submit} className="auth__form" noValidate>
      <div className="auth__legend">Sign up</div>

      <div className="form__group">
        <label htmlFor="reg-username">Username</label>
        <input
          id="reg-username"
          className="input"
          value={login}
          onChange={(e) => setLogin(e.target.value)}
          placeholder="username"
          required
        />
      </div>

      <div className="form__group">
        <label htmlFor="reg-email">Email</label>
        <input
          id="reg-email"
          className="input"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
          required
          autoComplete="email"
        />
      </div>

      <div className="form__group">
        <label htmlFor="reg-password">Password</label>
        <input
          id="reg-password"
          className="input"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="••••••••"
          required
          autoComplete="new-password"
          minLength={8}
        />
      </div>

      <div className="grid-2" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
        <div className="form__group">
          <label htmlFor="reg-first">First name (optional)</label>
          <input
            id="reg-first"
            className="input"
            value={firstName}
            onChange={(e) => setFirst(e.target.value)}
          />
        </div>
        <div className="form__group">
          <label htmlFor="reg-last">Last name (optional)</label>
          <input
            id="reg-last"
            className="input"
            value={lastName}
            onChange={(e) => setLast(e.target.value)}
          />
        </div>
      </div>

      {msg && (
        <div
          style={{
            marginTop: 8,
            marginBottom: 6,
            color: ok ? "#b0f5b0" : "#f6b3b3",
            fontSize: ".92rem",
          }}
        >
          {msg}
        </div>
      )}

      <button className="btn btn--gold btn--block" type="submit" disabled={loading}>
        {loading ? "Creating account…" : "Create account"}
      </button>
    </form>
  );
}
