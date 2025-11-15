import { useCallback, useEffect, useRef, useState } from 'react';

type ItemForm = {
  name: string;
  description: string;
  category: string;
  askingPrice: string;
};

type UrlRow = {
  _id: string;
  slug: string;
  targetUrl: string;
  createdAt: string;
};

export default function UploadItem() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string>('');
  const [form, setForm] = useState<ItemForm>({
    name: '',
    description: '',
    category: '',
    askingPrice: ''
  });
  const [message, setMessage] = useState<string>('');

  // short-link state (talks to your API)
  const [slug, setSlug] = useState<string>('');
  const [targetUrl, setTargetUrl] = useState<string>('');
  const [urls, setUrls] = useState<UrlRow[]>([]);

  const inputRef = useRef<HTMLInputElement | null>(null);

  // --- helpers ---
  const toSlug = (s: string) =>
    s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

  async function fetchWithRefresh(input: RequestInfo, init: RequestInit = {}) {
    const withCreds = { ...init, credentials: 'include' as const };
    let res = await fetch(input, withCreds);
    if (res.status === 401) {
      const r = await fetch('/api/refresh', { method: 'POST', credentials: 'include' });
      if (r.ok) res = await fetch(input, withCreds);
    }
    return res;
  }

  // --- image logic (unchanged) ---
  const onFileSelected = (f: File | null) => {
    if (!f) return;
    setFile(f);
    const url = URL.createObjectURL(f);
    setPreview(url);
  };

  const onDrop = useCallback((e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      onFileSelected(e.dataTransfer.files[0]);
    }
  }, []);

  const onDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  const onChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
    if (name === 'name' && !slug) setSlug(toSlug(value));
  };

  // --- fetch my URLs on mount ---
  useEffect(() => {
    (async () => {
      try {
        const resp = await fetchWithRefresh('/api/urls', { method: 'GET' });
        if (resp.ok) {
          const data = await resp.json();
          setUrls(data.urls || []);
        } else {
          setMessage('Log in to view your URLs.');
        }
      } catch {
        setMessage('Unable to load URLs.');
      }
    })();
  }, []);

  // --- submit handler: keeps your item UX + creates a short link in Mongo ---
  const submit = async () => {
    setMessage('');

    // keep your local validations/UX
    if (!file) {
      setMessage('Please upload an image of your item first.');
      return;
    }
    if (!form.name || !form.askingPrice) {
      setMessage('Please add a name and asking price.');
      return;
    }

    // minimal API write: require a targetUrl; slug auto-fills from name if empty
    const finalSlug = slug || toSlug(form.name);
    if (!finalSlug) {
      setMessage('Please provide a valid slug (letters/numbers).');
      return;
    }
    if (!/^https?:\/\//i.test(targetUrl)) {
      setMessage('Please provide a valid target URL (must start with http:// or https://).');
      return;
    }

    try {
      const resp = await fetchWithRefresh('/api/urls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slug: finalSlug, targetUrl })
      });
      const data = await resp.json();

      if (!resp.ok) {
        setMessage(data?.error || 'Failed to create short link.');
        return;
      }

      setMessage('Item submitted — an appraiser will review shortly. Short link created!');
      // reset local bits (keep preview so they can still see what they uploaded)
      setTargetUrl('');
      setSlug('');

      // refresh list
      const r = await fetchWithRefresh('/api/urls', { method: 'GET' });
      const d = await r.json();
      setUrls(d.urls || []);
    } catch (e: any) {
      setMessage(e?.toString() || 'Submit failed.');
    }
  };

  return (
    <div className="upload">
      <div className="upload__grid">
        {/* Left: image dropzone */}
        <div className="upload__dropzone" onDrop={onDrop} onDragOver={onDragOver}>
          {preview ? (
            <img className="upload__preview" src={preview} alt="Preview" />
          ) : (
            <div className="upload__placeholder">
              <span className="upload__icon">⇪</span>
              <p>Drag & drop an image here, or</p>
              <button className="btn btn--ghost" onClick={() => inputRef.current?.click()}>
                Browse
              </button>
            </div>
          )}
          <input
            ref={inputRef}
            type="file"
            accept="image/*"
            style={{ display: 'none' }}
            onChange={(e) => onFileSelected(e.target.files?.[0] || null)}
          />
        </div>

        {/* Right: item form + short-link form */}
        <div className="upload__form">
          <div className="field">
            <label>Name</label>
            <input
              name="name"
              value={form.name}
              onChange={onChange}
              placeholder="e.g., Rolex Submariner"
            />
          </div>

          <div className="field">
            <label>Category</label>
            <select name="category" value={form.category} onChange={onChange}>
              <option value="">Select a category</option>
              <option>Jewelry</option>
              <option>Electronics</option>
              <option>Collectibles</option>
              <option>Musical Instruments</option>
              <option>Luxury Goods</option>
            </select>
          </div>

          <div className="field">
            <label>Asking Price</label>
            <input
              name="askingPrice"
              value={form.askingPrice}
              onChange={onChange}
              placeholder="$500"
            />
          </div>

          <div className="field">
            <label>Description</label>
            <textarea
              name="description"
              value={form.description}
              onChange={onChange}
              placeholder="Include condition, accessories, provenance."
              rows={5}
            />
          </div>

          <hr style={{ margin: '16px 0', opacity: 0.2 }} />

          {/* Minimal backend wiring: make a short link */}
          <div className="field">
            <label>Short Link Slug</label>
            <input
              value={slug}
              onChange={(e) => setSlug(toSlug(e.target.value))}
              placeholder="e.g., rolex-submariner"
            />
          </div>
          <div className="field">
            <label>Target URL</label>
            <input
              value={targetUrl}
              onChange={(e) => setTargetUrl(e.target.value)}
              placeholder="https://example.com/your-item-details"
            />
          </div>

          <div className="actions">
            <button className="btn btn--primary" onClick={submit}>
              Submit for Appraisal
            </button>
            {message && <p className="hint">{message}</p>}
          </div>

          {/* Your URLs */}
          {urls.length > 0 && (
            <>
              <h3 style={{ marginTop: 24 }}>Your Short Links</h3>
              <ul>
                {urls.map((u) => (
                  <li key={u._id}>
                    <code>{u.slug}</code> →{' '}
                    <a href={u.targetUrl} target="_blank" rel="noreferrer">
                      {u.targetUrl}
                    </a>
                    {'  '}|{'  '}
                    <a href={`/u/${u.slug}`} target="_blank" rel="noreferrer">
                      open
                    </a>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
