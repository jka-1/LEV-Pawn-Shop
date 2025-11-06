// src/auth.ts
import { useSyncExternalStore } from "react";

/** Read current auth status from localStorage (accepts many shapes). */
function read() {
  try {
    const raw = localStorage.getItem("user_data");
    if (!raw) return false;
    const u = JSON.parse(raw);
    return !!(
      u &&
      (u.id || u._id || u.userId || u.UserId || u.ID ||
       u.firstName || u.FirstName ||
       u.login || u.Login ||
       u.username || u.UserName ||
       u.email || u.Email)
    );
  } catch {
    return false;
  }
}

let listeners = new Set<() => void>();

function subscribe(cb: () => void) {
  listeners.add(cb);
  const onStorage = (e: StorageEvent) => { if (e.key === "user_data") cb(); };
  window.addEventListener("storage", onStorage);
  return () => {
    listeners.delete(cb);
    window.removeEventListener("storage", onStorage);
  };
}

/** Call this after login/logout to refresh all subscribers immediately. */
export function notifyAuthChange() {
  for (const cb of [...listeners]) cb();
}

/** React hook: always returns the latest auth state (reactive). */
export function useAuthed() {
  return useSyncExternalStore(subscribe, read, read);
}
