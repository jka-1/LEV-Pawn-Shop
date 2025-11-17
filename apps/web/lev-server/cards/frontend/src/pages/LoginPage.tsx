// src/pages/LoginPage.tsx
import { useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import NavBar from "../components/NavBar";
import Login from "../components/Login";

function normalizeAndUpgradeUserData() {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return;
    const o = JSON.parse(raw);
    if (o && (o.email || o.username || o.firstName)) return;

    const norm = {
      id:        o?.id ?? o?._id ?? o?.userId ?? o?.UserId ?? o?.ID,
      email:     o?.email ?? o?.Email,
      username:  o?.username ?? o?.login ?? o?.Login ?? o?.UserName,
      firstName: o?.firstName ?? o?.FirstName,
      lastName:  o?.lastName ?? o?.LastName,
    };

    localStorage.setItem("user_data", JSON.stringify(norm));
  } catch {
    // ignore bad JSON
  }
}

export default function LoginPage() {
  const navigate = useNavigate();

  useEffect(() => {
    normalizeAndUpgradeUserData();
    try {
      const raw = localStorage.getItem("user_data");
      const u = raw ? JSON.parse(raw) : null;
      const authed = !!(
        u &&
        (
          u.id || u._id || u.userId || u.UserId || u.ID ||
          u.firstName || u.FirstName ||
          u.login || u.Login ||
          u.username || u.UserName ||
          u.email || u.Email
        )
      );

      if (authed) navigate("/storefront", { replace: true });
    } catch {
      // ignore
    }
  }, [navigate]);

  return (
    <div className="page page--auth">
      <NavBar />

      <main className="login-neon">
        {/* LEFT: Brand hero */}
        <section className="neon-stack">
          {/* Brand text on top */}
          <div className="neon-hero__inner">
            <div className="neon-logo" aria-hidden />
            <h1 className="neon-title">
              LEV
              <span className="neon-title__accent"> • instant quotes</span>
            </h1>
            <p className="neon-subtitle">Fast quotes. Fair offers. Zero hassle.</p>
            <ul className="neon-points">
              <li>Encrypted sign-in &amp; secure sessions</li>
              <li>Track offers and payouts in one place</li>
              <li>List items on the storefront instantly</li>
            </ul>
          </div>

          {/* Login card below */}
          <div className="neon-card">
            <Login />
            <p className="neon-card__meta">
              New here?{" "}
              <Link to="/register" className="neon-link">
                Create an account
              </Link>
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
