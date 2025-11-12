# LEV-Pawn-Shop

**High-end trading marketplace — that actually moves items in real life.**

LEV-Pawn-Shop is a dual-platform monorepo containing a web application and native iOS application for securely pawning, trading, and selling high-value items — with physical logistics.

The system leverages real-world “runners” who pick up an item, validate it (clean, verify condition), and deliver it to the recipient. The platform includes geofencing logic, an algorithm to determine optimal drop-off points based on item value, and Apple Pay support for secure payment flows.

---

## Key Features

- Real-world logistics: runners physically pick up and drop off items
- Item validation: runners clean and verify condition before transport
- Geofence detection
- Algorithmic drop-off location based on pawned item value
- Apple Pay functionality
- JWT authentication
- Shared code between platforms

---

## Stack

| Layer | Tech |
|---|---|
| Web App | React + Vite |
| iOS App | SwiftUI |
| Server | Node.js + Express |
| Database | MongoDB |
| Auth | JWT |

---

## AI Pricing (Gemini) Setup

- Backend lives in `cards/server.js` and exposes `POST /api/estimate-price`.
- The endpoint starts with or without AI configured. If the Gemini key is missing, it returns `503 { error: "ai_not_configured" }` instead of breaking the server.
- To enable AI locally:
  - Copy `cards/.env.example` to `cards/.env`.
  - Set `GOOGLE_API_KEY=...` and your `MONGODB_URI`.
  - Run backend: `node cards/server.js`; frontend: `npm run dev` in `cards/frontend`.

### Deployment Safety

- Secrets are not committed. Root `.gitignore` ignores `.env` files and `cards/uploads/`.
- Pushing Gemini changes will not break servers without the key; the endpoint fails gracefully.
- Lock the model by setting `GEMINI_MODEL` (default `gemini-2.0-flash`). Choose one your key supports.

### Where environment variables live

- Local development: put secrets in `cards/.env` (ignored by Git). The backend loads them via `dotenv`.
- CI/CD and hosted servers (e.g., GitHub Actions, Render, Heroku, Vercel): configure env vars in the service’s dashboard or secrets store — do not commit `.env` to the repo.
- Self-hosted servers: set process environment or use a secrets manager (e.g., Docker Compose `env_file`, systemd `Environment=`). Keep `.env` files out of Git.

### Environment Variables

See `cards/.env.example` for all variables:

- `GOOGLE_API_KEY` — Gemini key (required for AI pricing).
- `GEMINI_MODEL` — lock to a specific model for consistent outputs.
- `APP_BASE_URL`, `PORT` — dev setup for CORS and server port.
- `MONGODB_URI` — Atlas connection string.
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` — strong strings for auth.
- `REQUIRE_EMAIL_VERIFICATION` — set `false` in dev to skip email.


---

## Repository Structure

```bash
.
├── apps
│   ├── web                 # React + Vite web client
│   ├── server              # Node/Express backend API
│   └── ios                 # SwiftUI native app
│       ├── UIApp.swift     # App entry point
│       └── Screens/
│           └── ContentView.swift
│
├── packages
│   └── shared              # Shared code (schemas, types, utilities)
│
└── .github
    └── workflows           # CI/CD pipelines
