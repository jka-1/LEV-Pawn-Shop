import { Link } from "react-router-dom";
import NavBar from "../components/NavBar";
import PageTitle from "../components/PageTitle";
import Register from "../components/Register";

export default function RegisterPage() {
  return (
    <div className="page page--auth">
      <NavBar />

      {/* Neon background wrapper (same as login) */}
      <main className="login-neon auth-neon">
        <section className="auth-stack">
          
          {/* Brand title above the card */}
          <div className="auth-header">
            <div className="auth-logo" aria-hidden />
            <h1 className="auth-title">Create your account</h1>
            <p className="auth-subtitle">
              Join <span className="highlight">QuickPawn</span> to get fast, fair quotes.
            </p>
          </div>

          {/* Glass card */}
          <div className="auth-card">
            <PageTitle />
            <Register />

            <p className="auth-footer">
              Already have an account?{" "}
              <Link to="/" className="auth-link">Sign in</Link>
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
