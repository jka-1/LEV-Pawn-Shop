// src/App.tsx
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useEffect } from "react";
import "./App.css";

import HomePage from "./pages/HomePage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import Storefront from "./pages/Storefront";
import UploadPage from "./pages/UploadPage";

/** Accept multiple shapes for user_data so auth works no matter which fields you saved. */
function isAuthed(): boolean {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return false;
    const u = JSON.parse(raw);
    return !!(u && (u.id || u.userId || u.firstName || u.login || u.username || u.email));
  } catch {
    return false;
  }
}

/** One-time upgrade: rewrite old shapes (only _id) to normalized keys */
function normalizeAndUpgradeUserData() {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return;
    const o = JSON.parse(raw);

    // If already has a nice display key, skip
    if (o && (o.email || o.username || o.firstName)) return;

    const norm = {
      id:        o?.id ?? o?._id ?? o?.userId ?? o?.UserId ?? o?.ID,
      email:     o?.email ?? o?.Email,
      username:  o?.username ?? o?.login ?? o?.Login ?? o?.UserName,
      firstName: o?.firstName ?? o?.FirstName,
      lastName:  o?.lastName ?? o?.LastName,
    };
    localStorage.setItem("user_data", JSON.stringify(norm));
  } catch {}
}

export default function App() {
  useEffect(() => {
    normalizeAndUpgradeUserData();
  }, []);

  return (
    <BrowserRouter>
      <Routes>
        {/* Canonicalize: "/" -> "/home" */}
        <Route path="/" element={<Navigate to="/home" replace />} />

        {/* Public landing + auth */}
        <Route path="/home" element={<HomePage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />

        {/* Protected pages (inline gate) */}
        <Route path="/storefront" element={<Storefront />} />

        <Route
          path="/upload"
          element={isAuthed() ? <UploadPage /> : <Navigate to="/login" replace />}
        />

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/home" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
