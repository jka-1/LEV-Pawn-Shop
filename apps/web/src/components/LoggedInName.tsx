function LoggedInName() {
  async function doLogout(event: any): Promise<void> {
    event.preventDefault();
    try {
      await fetch('/api/logout', { method: 'POST', credentials: 'include' });
    } catch {}
    localStorage.removeItem('user_data');
    window.location.href = '/';
  }

  let displayName = 'Guest';
  try {
    const raw = localStorage.getItem('user_data');
    if (raw) {
      const ud = JSON.parse(raw);
      const fn = (ud.firstName || '').trim();
      const ln = (ud.lastName || '').trim();
      const full = `${fn} ${ln}`.trim();
      if (full.length > 0) displayName = full;
    }
  } catch {}

  return (
    <div id="loggedInDiv">
      <span id="userName">Logged In As {displayName}</span><br />
      <button id="logoutButton" className="buttons" onClick={doLogout}>
        Log Out
      </button>
    </div>
  );
}

export default LoggedInName;
