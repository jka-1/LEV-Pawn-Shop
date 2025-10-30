import NavBar from "../components/NavBar";
import { useNavigate } from "react-router-dom";

export default function HomePage() {
  const navigate = useNavigate();
  return (
    <div className="page page--hero">
      <NavBar />
      <section className="hero">
        <div className="hero__overlay">
          <h1 className="hero__title">Pawn your items in minutes</h1>
          <p className="hero__subtitle">
            Upload an image, describe your item, and get an instant quote.
          </p>
          <div className="hero__actions">
            <button className="btn btn--primary" onClick={() => navigate('/upload')}>Get Started</button>
            <button className="btn btn--secondary" onClick={() => navigate('/')}>Sign In</button>
          </div>
        </div>
      </section>
    </div>
  );
}