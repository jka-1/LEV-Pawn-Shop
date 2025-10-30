import { useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';

import PageTitle from '../components/PageTitle';
import Login from '../components/Login';

export default function LoginPage() {
  const navigate = useNavigate();

  // If already logged in, send to Upload (or Home)
  useEffect(() => {
    try {
      if (localStorage.getItem('user_data')) {
        navigate('/upload'); // or '/home'
      }
    } catch {}
  }, [navigate]);

  return (
    <div className="page page--auth">
      <PageTitle />
      <Login />
      <p style={{ marginTop: 12 }}>
        New here? <Link to="/register">Create an account</Link>
      </p>
    </div>
  );
}
