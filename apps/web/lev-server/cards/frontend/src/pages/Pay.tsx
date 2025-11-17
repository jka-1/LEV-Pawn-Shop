// src/pages/Pay.tsx
import React from "react";
import { useParams, useNavigate } from "react-router-dom";
import NavBar from "../components/NavBar";

type Item = {
  _id: string;
  name: string;
  price: number;
  description?: string;
  imageUrl: string;
  createdAt?: string;
};

export default function Pay() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [item, setItem] = React.useState<Item | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [email, setEmail] = React.useState("");
  const [processing, setProcessing] = React.useState(false);
  const [ok, setOk] = React.useState<string | null>(null);

  React.useEffect(() => {
    let alive = true;
    (async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(`/api/storefront/${id}`, { credentials: "include" });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        if (!data?.ok || !data?.item) throw new Error("Item not found");
        if (alive) setItem(data.item as Item);
      } catch (e: any) {
        if (alive) setError(e?.message || "Failed to load item");
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id]);

  function formatPrice(n?: number) {
    return Number.isFinite(n ?? NaN)
      ? (n as number).toLocaleString(undefined, { style: "currency", currency: "USD" })
      : "—";
  }

  async function payNow(e: React.FormEvent) {
    e.preventDefault();
    setProcessing(true);
    setOk(null);
    // Placeholder checkout flow
    setTimeout(() => {
      setProcessing(false);
      setOk("✅ Demo payment succeeded (placeholder).");
    }, 800);
  }

  return (
    <div className="page page--auth">
      <NavBar />

      <main className="login-neon auth-neon">
        <section className="auth-stack" style={{ paddingTop: "calc(var(--nav-h) + 6px)" }}>
          <div className="auth-header">
            <div className="auth-logo" aria-hidden />
            <h1 className="auth-title">Checkout</h1>
            <p className="auth-subtitle">Confirm the item and proceed to payment.</p>
          </div>

          <div className="auth-card">
            {loading && <p className="sf-empty">Loading…</p>}
            {error && <div className="sf-alert">{error}</div>}

            {item && (
              <>
                {/* Item summary */}
                <div style={{ display: "grid", gridTemplateColumns: "140px 1fr", gap: 16, marginBottom: 16 }}>
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    className="sf-thumb"
                    style={{ width: 140, height: 105, objectFit: "cover", borderRadius: 10 }}
                    onError={(e) => {
                      (e.currentTarget as HTMLImageElement).src = "https://placehold.co/192x144?text=No+Image";
                    }}
                  />
                  <div>
                    <h2 style={{ margin: 0, fontWeight: 700 }}>{item.name}</h2>
                    <div style={{ opacity: .9, marginTop: 6 }}>{item.description || "—"}</div>
                    <div style={{ marginTop: 8, fontSize: "1.05rem" }}>
                      <strong>{formatPrice(item.price)}</strong>
                    </div>
                  </div>
                </div>

                {/* Fake payment form */}
                <form onSubmit={payNow} className="upload-form" style={{ marginTop: 8 }}>
                  <label htmlFor="pay-email">Receipt email (optional)</label>
                  <input
                    id="pay-email"
                    className="input"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />

                  {ok && (
                    <div
                      style={{
                        margin: ".75rem 0",
                        padding: ".6rem .8rem",
                        border: "1px solid #059669",
                        background: "#062a24",
                        color: "#A7F3D0",
                        borderRadius: ".6rem",
                      }}
                    >
                      {ok}
                    </div>
                  )}

                  <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
                    <button type="submit" className="btn btn--gold" disabled={processing}>
                      {processing ? "Processing…" : "Pay now"}
                    </button>
                    <button
                      type="button"
                      className="btn--ghost"
                      onClick={() => navigate(-1)}
                      aria-label="Go back"
                    >
                      Back
                    </button>
                  </div>
                </form>
              </>
            )}

            <p className="auth-footer" style={{ marginTop: 18 }}>
              This is a placeholder checkout. You can wire real payments later (Stripe, etc.).
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
