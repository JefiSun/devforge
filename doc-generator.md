---
name: doc-generator
model: claude-sonnet-4-6
description: Generate README, API docs, and deployment guide from the built project
tools:
  - Read
  - Edit
  - Bash
  - Glob
---

# Doc Generator

Generate three documentation files from the built project.

## Input
- Project root
- `.pipeline/impl-plan.md`
- `.pipeline/brd-parsed.json`

---

## Step 1: Gather Context

```bash
cat package.json
cat .env.example 2>/dev/null || echo "NO_ENV_EXAMPLE"
find src/app/api -name "route.ts" 2>/dev/null
```

Read:
- `package.json` → project name, scripts, dependencies
- `.env.example` → environment variables
- API route files → request/response shapes

---

## Step 2: Write README.md

Write to project root `README.md`:

```markdown
# {projectName}

{projectDescription from brd-parsed.json}

## Getting Started

### Prerequisites
- Node.js 18+
- npm / yarn / pnpm

### Installation

```bash
git clone {repo-url}
cd {project-name}
npm install
cp .env.example .env.local
# Fill in .env.local values
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| ... | Yes/No | ... |

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Production build |
| `npm run test` | Unit tests with coverage |
| `npm run test:e2e` | Playwright E2E tests |

## Features

{list from brd-parsed.json features with one-line descriptions}

## Tech Stack

- [Next.js 14](https://nextjs.org) — App Router
- [TypeScript](https://typescriptlang.org)
- [Tailwind CSS](https://tailwindcss.com)
- [shadcn/ui](https://ui.shadcn.com)
```

---

## Step 3: Write docs/API.md

Create `docs/` if missing. Write `docs/API.md`.

For each file found in `src/app/api/**/route.ts`, read it and document:

```markdown
# API Reference

## {HTTP Method} /api/{route}

**Description**: {one line}

**Request Body**
```json
{inferred from handler}
```

**Response**
```json
{inferred from handler}
```

**Errors**
| Status | Meaning |
|--------|---------|
| 400 | Validation error |
| 401 | Unauthorized |
| 500 | Server error |
```

If no API routes exist, write: `# API Reference\n\nThis project has no API routes.`

---

## Step 4: Write docs/DEPLOYMENT.md

Write `docs/DEPLOYMENT.md`:

```markdown
# Deployment

## Vercel (Recommended)

1. Push code to GitHub
2. Go to [vercel.com/new](https://vercel.com/new) → import repository
3. Add environment variables (from `.env.example`)
4. Click Deploy

Build settings (auto-detected):
- Build command: `npm run build`
- Output directory: `.next`
- Install command: `npm install`

## Environment Variables

Set these in your host's dashboard. Refer to `.env.example` for the full list.

## Other Hosts

Any host supporting Node.js 18+ and Next.js works.
Minimum: set `NODE_ENV=production` and all variables from `.env.example`.
```

---

## Step 5: Create .env.example if Missing

```bash
grep -rh "process\.env\." src --include="*.ts" --include="*.tsx" | \
  grep -oE "process\.env\.[A-Z_0-9]+" | sort -u | \
  sed 's/process\.env\.//' | sed 's/^/# /; s/$/ /'
```

Write to `.env.example` — one variable per line with empty value:
```
NEXT_PUBLIC_APP_URL=
DATABASE_URL=
AUTH_SECRET=
```

---

## Done
Return: `"Docs complete. Files: README.md, docs/API.md, docs/DEPLOYMENT.md{, .env.example if created}."`
