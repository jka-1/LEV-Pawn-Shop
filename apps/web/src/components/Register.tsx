import { useState } from 'react';

export default function Register() {
  const [login, setLogin] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirst] = useState('');
  const [lastName, setLast] = useState('');
  const [msg, setMsg] = useState('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setMsg('');
    try {
      const r = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ login, email, password, firstName, lastName })
      });
      const data = await r.json().catch(() => ({}));
      if (!r.ok) {
        setMsg(data?.error || 'Registration failed');
        return;
      }
      setMsg('Registration successful! Please verify your email, then log in.');
    } catch (err: any) {
      setMsg(err?.toString() || 'Registration failed');
    }
  }

  return (
    <form onSubmit={submit} className="auth-form">
      <h2>Create an account</h2>

      <label>Username</label>
      <input value={login} onChange={(e)=>setLogin(e.target.value)} placeholder="username" required />

      <label>Email</label>
      <input type="email" value={email} onChange={(e)=>setEmail(e.target.value)} placeholder="you@example.com" required />

      <label>Password</label>
      <input type="password" value={password} onChange={(e)=>setPassword(e.target.value)} placeholder="••••••••" required />

      <div className="grid-2">
        <div>
          <label>First name (optional)</label>
          <input value={firstName} onChange={(e)=>setFirst(e.target.value)} />
        </div>
        <div>
          <label>Last name (optional)</label>
          <input value={lastName} onChange={(e)=>setLast(e.target.value)} />
        </div>
      </div>

      <button className="btn btn--primary" type="submit">Register</button>
      {msg && <p className="hint" style={{marginTop:8}}>{msg}</p>}
    </form>
  );
}
