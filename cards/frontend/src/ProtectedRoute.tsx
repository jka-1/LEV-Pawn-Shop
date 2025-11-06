// src/ProtectedRoute.tsx
import React from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuthed } from "./auth";  // <-- correct path when file is in src/

export default function ProtectedRoute({ children }: { children: React.ReactElement }) {
  const authed = useAuthed();
  const loc = useLocation();
  if (!authed) {
    // send them to login and remember where they were trying to go
    return <Navigate to="/login" replace state={{ from: loc }} />;
  }
  return children;
}
