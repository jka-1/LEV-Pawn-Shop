import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

export default function NavBar() {
  const [displayName, setDisplayName] = useState<string>('Guest');
  const navigate = useNavigate();

  useEffect(() => {
    try {
      const raw = localStorage.getItem('user_data');
      if (raw) {
        const user = JSON.parse(raw);
        const first = (user.firstName || 'Guest').trim();
        const last = (user.lastName || '').trim();
        setDisplayName(last ? `${first} ${last}` : first);
      } else {
        setDisplayName('Guest');
      }
    } catch {
      setDisplayName('Guest');
    }
  }, []);

  const logout = async () => {
    try {
      await fetch('/api/logout', { method: 'POST', credentials: 'include' });
    } catch {}
    localStorage.removeItem('user_data');
    navigate('/');
  };

  return (
    <header className="navbar">
      <div className="navbar__brand" onClick={() => navigate('/home')}>
        <span className="navbar__logo">♔</span>
        <span className="navbar__title">QuickPawn</span>
      </div>

      <nav className="navbar__links">
        <Link to="/home" className="navbar__link">Home</Link>
        <Link to="/upload" className="navbar__link">Upload</Link>
      </nav>

      <div className="navbar__user">
        <span className="navbar__name">{displayName}</span>
        <button className="btn btn--ghost" onClick={logout}>Logout</button>
      </div>
    </header>
  );
}
