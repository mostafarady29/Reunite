# Reunite Node.js Backend (`backend-node`)

A production-grade, modular Node.js API backend for the Reunite network built with Fastify, TypeScript, PostgreSQL, Supabase Storage, and the CoALA Agent Memory Cognitive Architecture.

## Key Features

- **Dual-Client Architecture**: Fully compatible with both the React Web Frontend (`/api/*` with HTTP-only cookies) and Flutter Mobile App (`/cases/*`, `/sightings`, `/locations/governorates` with `Authorization: Bearer <token>`).
- **CoALA Agent Memory Systems**:
  - **Semantic Memory**: 512-dimension Siamese facial embedding vectors stored as binary `BYTEA` buffers with normalized cosine similarity search.
  - **Episodic Memory**: Longitudinal case sightings, incident timelines, and status transitions.
  - **Procedural Memory**: Multi-factor composite ranking combining visual face similarity (65%), cognitive temporal decay with 30-day half-life (20%), and Haversine geographic proximity (15%).
- **Robust Layered Architecture**:
  - `config/`: Zod environment validation.
  - `core/`: Connection pooling (`pg.Pool`), custom error classes (`AppError`), security/JWT/bcrypt, and Supabase Storage integration with temporary signed URLs.
  - `repositories/`: Clean data access layer (Users, Reports, Photos, Comments/Sightings, Locations).
  - `services/`: CoALA Agent Memory and business orchestration.
  - `routes/`: Validated Fastify route plugins.
- **Security**: Helmet security headers, rate limiting (120 req/min), CORS credentials, parameterized SQL queries, password hashing with bcrypt.

## Requirements

- Node.js >= 20.0.0
- PostgreSQL database (local or cloud)

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` and fill in your database and Supabase credentials:
```bash
cp .env.example .env
```

### 3. Run Development Server
```bash
npm run dev
# Server starts on http://localhost:8000
```

### 4. Run Tests
```bash
npm test
# Runs 23 unit, integration, and visual search tests with Vitest
```

### 5. Typecheck & Build
```bash
npm run typecheck
npm run build
```

## API Overview

### Web Endpoints
- `GET /api/health` — Service health
- `GET /api/ready` — Database & AI readiness check
- `POST /api/auth/signup` — Member registration
- `POST /api/auth/login` — Member login
- `GET /api/me` — Current authenticated profile
- `GET /api/reports` — Paginated case reports
- `POST /api/reports` — Create report
- `POST /api/reports/:id/photos` — Upload report photo & auto-generate facial embedding
- `POST /api/search/photo` — Visual face similarity search using Agent Memory

### Flutter Mobile Endpoints
- `GET /cases/missing` — Filter missing cases (search, city, age range, gender)
- `GET /cases/found` — Open found children cases
- `GET /cases/:id` — Case details with normalized coordinates
- `GET /cases/:id/matches` — Possible matches ranked by facial similarity, recency, and distance
- `GET /cases/nearby` — Geo-spatial radius query (`lat`, `lng`, `radius`)
- `GET /cases/statistics` — Platform metrics (`activeCases`, `childrenFound`, `reportsToday`, `reunifications`)
- `POST /cases/missing` & `POST /cases/found` — Submit reports
- `POST /sightings` — Community sightings
- `GET /locations/governorates` — Governorates with nested cities
