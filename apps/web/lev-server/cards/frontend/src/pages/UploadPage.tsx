import React from "react";
import NavBar from "../components/NavBar";
import { useNavigate, Navigate } from "react-router-dom";

type Draft = {
  name: string;
  price: string;
  description: string;
  imageUrl: string;
};

export default function UploadPage() {
  const navigate = useNavigate();

  // 🔒 If runner mode is on, bounce to /runner
  const isRunner =
    typeof window !== "undefined" && localStorage.getItem("runner_mode") === "1";
  if (isRunner) {
    return <Navigate to="/runner" replace />;
  }

  const [draft, setDraft] = React.useState<Draft>({
    name: "",
    price: "",
    description: "",
    imageUrl: "",
  });

  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [ok, setOk] = React.useState<string | null>(null);
  const errorRef = React.useRef<HTMLDivElement | null>(null);

  // 🌟 AI pricing state
  const [aiLoading, setAiLoading] = React.useState(false);
  const [aiNote, setAiNote] = React.useState<string | null>(null);

  async function handleFileSelect(file: File) {
    setError(null);
    setOk(null);
    try {
      const sigResp = await fetch("/api/uploads/sign", {
        method: "POST",
        credentials: "include",
      });
      const sig = await sigResp.json().catch(() => ({}));
      if (!sigResp.ok || !sig?.ok)
        throw new Error(sig?.error || "Failed to get upload signature");

      const fd = new FormData();
      fd.append("file", file);
      fd.append("api_key", sig.apiKey);
      fd.append("timestamp", String(sig.timestamp));
      fd.append("signature", sig.signature);
      fd.append("folder", sig.folder);

      const up = await fetch(
        `https://api.cloudinary.com/v1_1/${sig.cloudName}/auto/upload`,
        { method: "POST", body: fd }
      );
      const j = await up.json().catch(() => ({}));
      if (!up.ok) throw new Error(j?.error?.message || "Cloud upload failed");

      setDraft((d) => ({ ...d, imageUrl: j.secure_url || j.url || "" }));
      setOk("Image uploaded.");
    } catch (e: any) {
      setError(e?.message || "Upload failed");
      setTimeout(
        () =>
          errorRef.current?.scrollIntoView({
            behavior: "smooth",
            block: "center",
          }),
        50
      );
    }
  }

  // 🌟 Ask Gemini for a price estimate
  async function estimateWithAI() {
    setError(null);
    setOk(null);
    setAiNote(null);

    if (!draft.name.trim()) {
      setError("Please enter a name before estimating.");
      return;
    }

    if (!draft.imageUrl.trim() && !draft.description.trim()) {
      setError("Provide an image or description for a better estimate.");
      return;
    }

    setAiLoading(true);
    try {
      let location: any = null;
      try {
        location = await new Promise((resolve) => {
          if (!("geolocation" in navigator)) return resolve(null);
          navigator.geolocation.getCurrentPosition(
            (pos) =>
              resolve({
                lat: pos.coords.latitude,
                lng: pos.coords.longitude,
              }),
            () => resolve(null),
            { enableHighAccuracy: true, timeout: 4000 }
          );
        });
      } catch {
        location = null;
      }

      const resp = await fetch("/api/estimate-price", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          name: draft.name.trim(),
          description: draft.description.trim(),
          imageUrl: draft.imageUrl.trim() || undefined,
          location,
        }),
      });

      const data = await resp.json().catch(() => ({}));
      if (!resp.ok || !data?.ok) {
        throw new Error(data?.error || `HTTP ${resp.status}`);
      }

      const priceNum = Number(data.price);
      if (Number.isFinite(priceNum) && priceNum >= 0) {
        setDraft((d) => ({ ...d, price: String(priceNum.toFixed(0)) }));
      }

      const range =
        Number.isFinite(data.low) && Number.isFinite(data.high)
          ? `Range: $${Number(data.low).toFixed(0)}–$${Number(
              data.high
            ).toFixed(0)}`
          : "";

      const conf =
        typeof data.confidence === "number"
          ? `Confidence: ${(data.confidence * 100).toFixed(0)}%`
          : "";

      const noteParts = [
        priceNum && Number.isFinite(priceNum)
          ? `AI suggests $${priceNum.toFixed(0)} USD`
          : null,
        range,
        conf,
      ].filter(Boolean);

      if (noteParts.length) {
        setAiNote(noteParts.join(" · "));
      }
    } catch (e: any) {
      setError(e?.message || "AI estimate failed.");
      setTimeout(
        () =>
          errorRef.current?.scrollIntoView({
            behavior: "smooth",
            block: "center",
          }),
        50
      );
    } finally {
      setAiLoading(false);
    }
  }

  const onSubmit: React.FormEventHandler = async (e) => {
    e.preventDefault();
    setError(null);
    setOk(null);

    if (!draft.name.trim()) return setError("Please enter a name.");

    // 🌟 Require AI to have filled in a price or use manual price
    if (!draft.price.trim()) {
      return setError("Please use AI to estimate a price or manually enter one.");
    }

    const priceNum = Number(draft.price);
    if (!Number.isFinite(priceNum) || priceNum < 0) {
      return setError("Please enter a valid price.");
    }

    if (!draft.imageUrl.trim())
      return setError("Please provide an image (URL or upload).");

    setSubmitting(true);
    try {
      const res = await fetch("/api/storefront", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          name: draft.name.trim(),
          price: priceNum,
          description: draft.description.trim() || null,
          imageUrl: draft.imageUrl.trim(),
        }),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok || !data?.ok)
        throw new Error(data?.error || `HTTP ${res.status}`);

      setOk("Item added!");
      setAiNote(null);
      setDraft({ name: "", price: "", description: "", imageUrl: "" });
    } catch (err: any) {
      setError(err?.message || "Failed to save item.");
      setTimeout(
        () =>
          errorRef.current?.scrollIntoView({
            behavior: "smooth",
            block: "center",
          }),
        50
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="page page--auth">
      <NavBar />
      <main className="login-neon auth-neon">
        <section
          className="auth-stack"
          style={{ paddingTop: "calc(var(--nav-h) + 6px)" }}
        >
          <div className="auth-header">
            <div className="auth-logo" aria-hidden />
            <h1 className="auth-title">Add a Storefront Item</h1>
            <p className="auth-subtitle">
              Let AI suggest a fair cash offer for your item.
            </p>
          </div>

          <div className="auth-card">
            <form onSubmit={onSubmit} className="upload-form">
              <div>
                <label htmlFor="up-name">Name</label>
                <input
                  id="up-name"
                  className="input"
                  placeholder="Apple Watch Series 9"
                  value={draft.name}
                  onChange={(e) =>
                    setDraft({ ...draft, name: e.target.value })
                  }
                />
              </div>

              <div>
                <label htmlFor="up-desc">Description</label>
                <textarea
                  id="up-desc"
                  className="input"
                  rows={4}
                  placeholder="Excellent condition, includes charger."
                  value={draft.description}
                  onChange={(e) =>
                    setDraft({ ...draft, description: e.target.value })
                  }
                />
              </div>

              <div>
                <label htmlFor="up-img">Image URL</label>
                <input
                  id="up-img"
                  className="input"
                  placeholder="https://…  (or use Upload Image below)"
                  value={draft.imageUrl}
                  onChange={(e) =>
                    setDraft({ ...draft, imageUrl: e.target.value })
                  }
                />
                <div
                  style={{
                    marginTop: 8,
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                    flexWrap: "wrap",
                  }}
                >
                  <label
                    className="btn btn--gold"
                    style={{ cursor: "pointer" }}
                  >
                    <input
                      type="file"
                      accept="image/*"
                      style={{ display: "none" }}
                      onChange={(e) => {
                        const f = e.currentTarget.files?.[0];
                        if (f) handleFileSelect(f);
                      }}
                    />
                    Upload Image
                  </label>
                  {draft.imageUrl ? (
                    <>
                      <img
                        src={draft.imageUrl}
                        alt="preview"
                        className="sf-thumb"
                        onError={(e) => {
                          (e.currentTarget as HTMLImageElement).src =
                            "https://placehold.co/192x144?text=Preview";
                        }}
                      />
                      <button
                        type="button"
                        className="btn btn--gold"
                        onClick={() =>
                          window.open(draft.imageUrl, "_blank", "noopener")
                        }
                        aria-label="Open full-size image preview"
                      >
                        Preview Image
                      </button>
                    </>
                  ) : (
                    <>
                      <small style={{ color: "#a9b5cb" }}>
                        No image selected
                      </small>
                      <button
                        type="button"
                        className="btn btn--gold"
                        disabled
                        aria-disabled="true"
                        style={{ opacity: 0.5, cursor: "not-allowed" }}
                      >
                        Preview Image
                      </button>
                    </>
                  )}
                </div>
              </div>

              <div>
                <label htmlFor="up-price">Price (USD)</label>
                <input
                  id="up-price"
                  className="input"
                  inputMode="decimal"
                  placeholder="Enter or estimate price"
                  value={draft.price}
                  onChange={(e) => setDraft({ ...draft, price: e.target.value })}
                />
                <div
                  style={{
                    marginTop: 8,
                    display: "flex",
                    gap: 10,
                    alignItems: "center",
                    flexWrap: "wrap",
                  }}
                >
                  <button
                    type="button"
                    className="btn btn--gold"
                    onClick={estimateWithAI}
                    disabled={aiLoading}
                    aria-disabled={aiLoading}
                  >
                    {aiLoading ? "Estimating…" : "Estimate with AI"}
                  </button>
                  {aiNote && (
                    <small style={{ color: "#a9b5cb" }}>{aiNote}</small>
                  )}
                </div>
              </div>

              {error && (
                <div ref={errorRef} className="sf-alert">
                  {error}
                </div>
              )}
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

              <div className="sticky-submit">
                <button
                  type="submit"
                  className="btn btn--gold btn--block"
                  disabled={submitting}
                  aria-disabled={submitting}
                >
                  {submitting ? "Uploading…" : "Add Item"}
                </button>
              </div>
            </form>

            <p className="auth-footer">
              Done here?{" "}
              <a className="auth-link" onClick={() => navigate("/storefront")}>
                View Storefront
              </a>
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
