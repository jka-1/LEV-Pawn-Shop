import { useState } from 'react';


function Login() {
  const [message, setMessage] = useState('');
  const [loginName, setLoginName] = useState('');
  const [loginPassword, setPassword] = useState('');

  // Convenience helper to build API routes (kept simple since nginx proxies /api)
  const api = (route: string) => `/api/${route}`;

  async function doLogin(event: any): Promise<void> {
    event.preventDefault();

    const payload = { loginOrEmail: loginName, password: loginPassword };

    try {
      const response = await fetch(api('login'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include', // IMPORTANT: send/receive cookies
        body: JSON.stringify(payload)
      });

      const res = await response.json().catch(() => ({} as any));

      // Optional: if you later gate unverified users on the backend
      if (response.status === 403 && res?.error === 'EMAIL_NOT_VERIFIED') {
        setMessage('Please verify your email before logging in.');
        return;
      }

      if (!response.ok || !res?.id || res.id <= 0) {
        setMessage('User/Password combination incorrect');
        return;
      }

      const user = { firstName: res.firstName, lastName: res.lastName, id: res.id };
      localStorage.setItem('user_data', JSON.stringify(user));

      setMessage('');
      window.location.href = '/upload'; // keep your existing landing page
    } catch (err: any) {
      setMessage(err?.toString() || 'Login failed');
    }
  }

  return (
    <div id="loginDiv">
      <span id="inner-title">PLEASE LOG IN</span><br />
      Login:{' '}
      <input
        type="text"
        id="loginName"
        placeholder="Username or Email"
        onChange={(e) => setLoginName(e.target.value)}
      />
      <br />
      Password:{' '}
      <input
        type="password"
        id="loginPassword"
        placeholder="Password"
        onChange={(e) => setPassword(e.target.value)}
      />
      <input
        type="submit"
        id="loginButton"
        className="buttons"
        value="Do It"
        onClick={doLogin}
      />
      <span id="loginResult">{message}</span>
    </div>
  );
}

export default Login;
