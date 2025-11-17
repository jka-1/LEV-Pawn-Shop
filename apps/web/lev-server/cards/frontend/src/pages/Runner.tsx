// src/pages/Runner.tsx
import React from "react";
import NavBar from "../components/NavBar";

export default function Runner() {
  return (
    <div className="page">
      <NavBar />
      <main className="login-neon auth-neon">
        <section className="auth-stack" style={{ paddingTop: "calc(var(--nav-h) + 8px)" }}>
          <div className="auth-header">
            <div className="auth-logo" aria-hidden />
            <h1 className="auth-title">Hello, Runner! 👟</h1>
            <p className="auth-subtitle">This is a mock page — swap this out with your real runner UI later.</p>
          </div>

          <div className="auth-card" style={{ textAlign: "center", padding: "2rem 1.25rem" }}>
            <p style={{ marginBottom: "1rem" }}>
              Welcome to <strong>Runner</strong> mode. You logged in with the runner toggle on.
            </p>
            <p style={{ color: "#64748b" }}>
              Tip: keep this page around while you build features, then replace the contents.
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
