// src/App.tsx
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import "./App.css";

import HomePage from "./pages/HomePage";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import Storefront from "./pages/Storefront";
import UploadPage from "./pages/UploadPage";
import ProtectedRoute from "./ProtectedRoute";

import Pay from "./pages/Pay";
import ForgotPasswordPage from "./pages/ForgotPasswordPage";
import ResetPasswordPage from "./pages/ResetPasswordPage";
import RecoverIdentityPage from "./pages/RecoverIdentityPage";
import RunnerDashboard from "./pages/RunnerDashboard";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/home" replace />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/storefront" element={<Storefront />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/recover-identity" element={<RecoverIdentityPage />} />

        {/* ✅ only this /runner route */}
        <Route path="/runner" element={<RunnerDashboard />} />

        <Route
          path="/upload"
          element={
            <ProtectedRoute>
              <UploadPage />
            </ProtectedRoute>
          }
        />
        <Route path="/pay/:id" element={<Pay />} />
        <Route path="*" element={<Navigate to="/home" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
