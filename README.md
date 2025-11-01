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
