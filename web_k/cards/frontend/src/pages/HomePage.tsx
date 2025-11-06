// src/pages/HomePage.tsx
import NavBar from "../components/NavBar";
import { useNavigate } from "react-router-dom";

function isAuthed(): boolean {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return false;
    const u = JSON.parse(raw);
    // keep in sync with NavBar/App predicates
    return !!(u && (u.id || u.userId || u.firstName || u.login || u.username || u.email));
  } catch {
    return false;
  }
}

export default function HomePage() {
  const navigate = useNavigate();

  // Guests → /login, Users → /storefront
  const goGetStarted = () => {
    navigate(isAuthed() ? "/storefront" : "/login");
  };

  return (
  <div className="page page--hero">
    <NavBar />

    {/* Reuse the same neon background */}
    <main className="login-neon home-neon">
      {/* Centered glass panel hero */}
      <section className="home-stack">
        <div className="home-card" aria-labelledby="hero-title">
          <div className="home-logo" aria-hidden />
          <h1 id="hero-title" className="home-title">Pawn your items in minutes</h1>
          <p className="home-subtitle">
            Upload an image, describe your item, and get an instant quote.
          </p>

          <div className="home-actions">
            <button className="btn btn--primary home-cta" onClick={goGetStarted}>
              Get Started
            </button>
          </div>
        </div>
      </section>
    </main>
  </div>
);
}
