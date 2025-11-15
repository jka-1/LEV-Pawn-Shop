// src/pages/Storefront.tsx
import React from "react";
import NavBar from "../components/NavBar";

type Item = {
  _id: string;
  name: string;
  price: number;
  description?: string;
  imageUrl: string;
  createdAt?: string;
};

type SortKey = "createdAt" | "name" | "price";

export default function Storefront() {
  const [items, setItems] = React.useState<Item[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const [q, setQ] = React.useState("");
  const [sortKey, setSortKey] = React.useState<SortKey>("createdAt");
  const [sortDir, setSortDir] = React.useState<"asc" | "desc">("desc");

  // Lightbox state (index into `view`)
  const [lbIdx, setLbIdx] = React.useState<number | null>(null);
  const openLightbox = (i: number) => setLbIdx(i);
  const closeLightbox = () => setLbIdx(null);

  // ---- Fetch all items (server handles pagination via nextCursor) ----
  async function fetchAllPages() {
    try {
      setLoading(true);
      setError(null);

      const all: Item[] = [];
      let next: string | null = null;

      do {
        const params = new URLSearchParams({ limit: "48" });
        if (next) params.set("afterId", next);

        const res = await fetch(`/api/storefront?${params.toString()}`, {
          credentials: "include",
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);

        const data = await res.json();
        if (!data?.ok) throw new Error(data?.error || "Failed to load");

        if (Array.isArray(data.items)) all.push(...data.items);
        next = data.nextCursor ?? null;
      } while (next);

      setItems(all);
    } catch (e: any) {
      setError(e?.message || "Error loading items");
    } finally {
      setLoading(false);
    }
  }

  React.useEffect(() => {
    fetchAllPages();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ---- Filter + sort view ----
  const view = React.useMemo(() => {
    const needle = q.trim().toLowerCase();

    const filtered = needle
      ? items.filter((it) => {
          const n = (it.name || "").toLowerCase();
          const d = (it.description || "").toLowerCase();
          return n.includes(needle) || d.includes(needle);
        })
      : items;

    const toNum = (v: unknown) => {
      const n = typeof v === "number" ? v : Number(v);
      return Number.isFinite(n) ? n : null;
    };

    const sorted = [...filtered].sort((a, b) => {
      if (sortKey === "name") {
        const av = a.name || "";
        const bv = b.name || "";
        return sortDir === "asc" ? av.localeCompare(bv) : bv.localeCompare(av);
      }
      if (sortKey === "price") {
        const ap = toNum(a.price);
        const bp = toNum(b.price);
        const aVal = ap === null ? -Infinity : ap;
        const bVal = bp === null ? -Infinity : bp;
        return sortDir === "asc" ? aVal - bVal : bVal - aVal;
      }
      const at = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const bt = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return sortDir === "asc" ? at - bt : bt - at;
    });

    return sorted;
  }, [items, q, sortKey, sortDir]);

  // ---- Keyboard nav for lightbox (after `view`) ----
  React.useEffect(() => {
    if (lbIdx === null) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closeLightbox();
      if (e.key === "ArrowRight") setLbIdx((i) => (i === null ? i : (i + 1) % view.length));
      if (e.key === "ArrowLeft") setLbIdx((i) => (i === null ? i : (i - 1 + view.length) % view.length));
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [lbIdx, view.length]);

  function flipSort(key: SortKey) {
    if (key === sortKey) setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    else {
      setSortKey(key);
      setSortDir(key === "name" ? "asc" : "desc");
    }
  }

  const current = lbIdx !== null ? view[lbIdx] : null;

  // ---- Date formatter: "11/4/25 1:25 PM" ----
  function fmtShort(dt?: string) {
    if (!dt) return "—";
    const d = new Date(dt);
    if (Number.isNaN(+d)) return "—";
    return d.toLocaleString(undefined, {
      month: "numeric",
      day: "numeric",
      year: "2-digit",
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    });
  }

  return (
    <div className="sf-neon page--storefront">
      <NavBar />

      {/* push content slightly up; prevent any overlay behavior */}
      <main className="sf-stack">


  <section className="sf-wrap">
    {/* Toolbar: not sticky, but keep a stacking context so it stays clickable */}
    <header
  className="sf-toolbar"
  style={{ position: "static", zIndex: 0, marginBottom: 14 }}
>

            <h1 className="sf-title">Storefront</h1>
            <div className="sf-controls">
              <label htmlFor="sf-search" className="sr-only">Search items</label>
              <input
                id="sf-search"
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Search name or description…"
                className="input sf-input"
                autoComplete="off"
              />
              <label htmlFor="sf-sort" className="sr-only">Sort by</label>
              <select
                id="sf-sort"
                value={`${sortKey}:${sortDir}`}
                onChange={(e) => {
                  const [k, d] = e.target.value.split(":") as [SortKey, "asc" | "desc"];
                  setSortKey(k);
                  setSortDir(d);
                }}
                className="input sf-input"
              >
                <option value="createdAt:desc">Newest</option>
                <option value="createdAt:asc">Oldest</option>
                <option value="price:desc">Price ↑</option>
                <option value="price:asc">Price ↓</option>
                <option value="name:asc">Name A→Z</option>
                <option value="name:desc">Name Z→A</option>
              </select>
            </div>
          </header>

          {error && <div className="sf-alert">{error}</div>}

          {/* Table (nudged up a bit) */}
          <div className="sf-tablewrap" style={{ marginTop: 6 }}>
  <table className="sf-table sf-compact">
              <colgroup>
                <col style={{ width: 110 }} />        {/* thumb */}
                <col style={{ width: "25%" }} />      {/* name */}
                <col style={{ width: "20%" }} />      {/* price */}
                <col style={{ width: "29%" }} />      {/* description */}
                <col style={{ width: "16%" }} />      {/* added */}
              </colgroup>

              <thead style={{ display: "table-header-group" }}>

                <tr>
                  <Th label="Item" />
                  <Th label="Name" clickable onClick={() => flipSort("name")} />
                  <Th label="Price" right clickable onClick={() => flipSort("price")} />
                  <Th label="Description" />
                  <Th label="Added" clickable onClick={() => flipSort("createdAt")} />
                </tr>
              </thead>

              <tbody>
                {view.map((it, i) => (
                  <tr key={it._id} className="sf-row">
                    <td data-label="Item">
                      <button
                        type="button"
                        className="sf-thumb-btn"
                        aria-label={`View image: ${it.name || "item"}`}
                        onClick={() => openLightbox(i)}
                        onKeyDown={(e) => {
                          if (e.key === "Enter" || e.key === " ") openLightbox(i);
                        }}
                      >
                        <img
                          src={it.imageUrl}
                          alt={it.name}
                          className="sf-thumb"
                          draggable={false}
                          onError={(e) => {
                            (e.currentTarget as HTMLImageElement).src =
                              "https://placehold.co/192x144?text=No+Image";
                          }}
                        />
                      </button>
                    </td>

                    <td data-label="Name" className="sf-name">{it.name || "—"}</td>

                    <td data-label="Price" className="sf-price">
                      {formatPrice(it.price)}
                    </td>

                    <td data-label="Description">
                      <span
                        style={{
                          display: "block",
                          whiteSpace: "nowrap",
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          maxWidth: "100%",
                        }}
                        title={it.description || ""}
                      >
                        {it.description || "—"}
                      </span>
                    </td>

                    <td data-label="Added" className="sf-added">
                      {fmtShort(it.createdAt)}
                    </td>
                  </tr>
                ))}

                {loading && items.length === 0 && (
                  <tr>
                    <td colSpan={5} className="sf-empty">Loading items…</td>
                  </tr>
                )}
                {!loading && view.length === 0 && (
                  <tr>
                    <td colSpan={5} className="sf-empty">No items found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      </main>

      {/* Lightbox */}
      {current && (
        <div
          className="lb"
          role="dialog"
          aria-modal="true"
          aria-label="Image preview"
          onClick={closeLightbox}
          tabIndex={-1}
        >
          <div className="lb__pane" onClick={(e) => e.stopPropagation()}>
            <button className="lb__btn lb__close" aria-label="Close" onClick={closeLightbox}>×</button>
            <button
              className="lb__btn lb__prev"
              aria-label="Previous image"
              onClick={() => setLbIdx((i) => (i === null ? i : (i - 1 + view.length) % view.length))}
            >
              ‹
            </button>

            <img
              src={current.imageUrl}
              alt={current.name}
              className="lb__img"
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).src =
                  "https://placehold.co/1200x800?text=No+Image";
              }}
            />

            <button
              className="lb__btn lb__next"
              aria-label="Next image"
              onClick={() => setLbIdx((i) => (i === null ? i : (i + 1) % view.length))}
            >
              ›
            </button>

            <div className="lb__caption">
              <div className="lb__title">{current.name}</div>
              <div className="lb__meta">
                {formatPrice(current.price)}
                {current.description ? <> · {current.description}</> : null}
                {" · "}
                <a href={current.imageUrl} target="_blank" rel="noopener noreferrer" className="lb__link">
                  Open full image
                </a>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ---- Header cell (simple; no active arrows) ---------------------------------
function Th(props: {
  label: string;
  right?: boolean;
  clickable?: boolean;
  onClick?: () => void;
}) {
  const { label, right, clickable, onClick } = props;
  return (
    <th
      onClick={clickable ? onClick : undefined}
      className={right ? "sf-th-right" : undefined}
      style={{ cursor: clickable ? "pointer" : "default", userSelect: "none" }}
    >
      {label}
    </th>
  );
}

// ---- Price formatter ---------------------------------------------------------
function formatPrice(n: number) {
  return Number.isFinite(n)
    ? n.toLocaleString(undefined, { style: "currency", currency: "USD" })
    : "—";
}
