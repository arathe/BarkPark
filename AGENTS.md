# Repository Guidelines

This AGENTS.md is a concise contributor guide for BarkPark. Start by reading `CLAUDE.md` for architecture, workflows, environment, and local setup details. Follow the patterns already used in the repo and keep changes focused and minimal.

## Project Structure & Module Organization
- `backend/`: Node.js/Express API with PostgreSQL/PostGIS. Routes in `routes/` (plural), models in `models/` (PascalCase). Tests in `backend/tests/`.
- `ios/`: SwiftUI app (`BarkPark.xcodeproj`). Tests in `BarkParkTests/` and `BarkParkUITests/`.
- `docs/`, `backend/docs/`: Deployment, PostGIS, and testing references.

## Build, Test, and Development Commands
- Setup backend: `cd backend && npm install`
- Run API (dev): `cd backend && npm run dev` (nodemon on port 4000, configurable via `PORT`)
- Run tests (sequential): `cd backend && npm test`
- Specific test file: `cd backend && npm test -- tests/auth.test.js`
- Coverage: `cd backend && npm test -- --coverage`
- DB migrations: `cd backend && npm run db:migrate` (see `db:migrate:*` scripts)
- iOS tests: `cd ios && xcodebuild test -project BarkPark.xcodeproj -scheme BarkPark -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5'`

## Coding Style & Naming Conventions
- Backend: 2‑space indent, semicolons, CommonJS (`require`/`module.exports`).
- Routes plural in `routes/` (e.g., `routes/users.js`); models PascalCase in `models/` (e.g., `models/User.js`).
- DB uses `snake_case`; map to iOS `camelCase` with `CodingKeys`.
- Prefer existing patterns over new abstractions; keep functions small and explicit.

## Testing Guidelines
- Frameworks: Jest + Supertest; tests live in `backend/tests/**.test.js`.
- Always run sequentially (`npm test` uses `--runInBand`); do not call `jest` directly.
- Use `beforeEach` (not `beforeAll`); isolate data with factories/utilities in `tests/utils/`.
- Useful scripts: `npm run quick-check`; when touching schema/migrations run `npm test -- tests/database-integrity.test.js`.

## Commit & Pull Request Guidelines
- Commit format: `<type>: <subject>` where type ∈ {feat, fix, docs, style, refactor, test, chore}.
- PRs include: clear description, linked issues, test plan (commands + results), migration notes (if any), screenshots for iOS UI changes, and environment variable changes.
- Don’t commit `.env`, `node_modules/`, or build artifacts.

## Security & Configuration Tips
- Copy `backend/.env.example` to `backend/.env`; never commit secrets.
- Required vars: `DATABASE_URL`, `JWT_SECRET`, SMTP, and AWS S3 for photo uploads.
- For iOS local dev, point API base URL to your machine IP (see `CLAUDE.md`).

## Agent-Specific Notes
- Scope: This file applies to the entire repo; deeper `AGENTS.md` files take precedence in their subtrees.
- Follow the commands above when running or testing; keep changes minimal and aligned with established structure and naming.
