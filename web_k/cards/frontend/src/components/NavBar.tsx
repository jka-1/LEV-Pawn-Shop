import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

/** Accept any casing the backend might return and normalize it */
type RawUser = Record<string, unknown>;

function pick<T = string>(o: RawUser | null, ...keys: string[]): T | undefined {
  if (!o) return undefined;
  const map = new Map<string, unknown>();
  for (const [k, v] of Object.entries(o)) map.set(k.toLowerCase(), v);
  for (const k of keys) {
    const v = map.get(k.toLowerCase());
    if (v !== undefined && v !== null && String(v).trim() !== "") {
      return v as T;
    }
  }
  return undefined;
}

function normalizeUser(raw: RawUser | null) {
  if (!raw) return null;
  const id        = pick<string>(raw, "id", "_id", "userId");
  const email     = pick<string>(raw, "email", "Email");
  const username  = pick<string>(raw, "username", "login", "Login");
  const firstName = pick<string>(raw, "firstName", "FirstName");
  const lastName  = pick<string>(raw, "lastName", "LastName");
  return { id, email, username, firstName, lastName };
}

function getDisplayName(raw: RawUser | null): string {
  const u = normalizeUser(raw);
  if (!u) return "Guest";
  const name =
    ([u.firstName, u.lastName].filter(Boolean).join(" ").trim()) ||
    u.email ||
    u.username ||
    u.id ||
    "Guest";
  return name;
}

function readAuth() {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return { authed: false, user: null as RawUser | null };
    const obj = JSON.parse(raw) as RawUser;
    const u = normalizeUser(obj);
    const authed = !!(u && (u.email || u.username || u.firstName || u.id));
    return { authed, user: obj as RawUser };
  } catch {
    return { authed: false, user: null as RawUser | null };
  }
}

export default function NavBar() {
  const navigate = useNavigate();
  const [{ authed, user }, setAuth] = useState(readAuth());
  const displayName = getDisplayName(user);

  // keep in sync if another tab logs in/out
  useEffect(() => {
    const update = () => setAuth(readAuth());
    update();
    const onStorage = (e: StorageEvent) => { if (e.key === "user_data") update(); };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  const logout = async () => {
    try { await fetch("/api/logout", { method: "POST", credentials: "include" }); } catch {}
    localStorage.removeItem("user_data");
    setAuth({ authed: false, user: null });
    navigate("/", { replace: true });
  };

  return (
    <header className="navbar" role="banner">
      {/* Brand (click to go Home) */}
      <div
        className="navbar__brand"
        onClick={() => navigate("/home")}
        aria-label="QuickPawn Home"
        title="QuickPawn"
        style={{ cursor: "pointer" }}
      >
        <span className="navbar__logo" aria-hidden="true">♔</span>
        <span className="navbar__title">QuickPawn</span>
      </div>

      {/* Center links */}
      <nav className="navbar__links" aria-label="Primary">
        <Link to="/home" className="navbar__link">Home</Link>
        <Link to="/storefront" className="navbar__link">Storefront</Link>
        {authed && <Link to="/upload" className="navbar__link">Upload</Link>}
      </nav>

      {/* Right side */}
      <div className="navbar__user" style={{ display: "flex", gap: ".5rem", alignItems: "center" }}>
        {authed ? (
          <>
            <span className="navbar__name">
              Logged in as <strong>{displayName}</strong>
            </span>
            <button className="btn--ghost" onClick={logout} aria-label="Log out">Logout</button>
          </>
        ) : (
          <>
            <span className="navbar__name">Guest</span>
            <Link to="/login" className="btn--ghost" aria-label="Sign in">Sign In</Link>
          </>
        )}
      </div>
    </header>
  );
}
