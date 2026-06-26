---
stack: nextjs14
label: "Next.js 14 · TypeScript · Tailwind · shadcn/ui · Prisma · PostgreSQL"
---

# Stack: Next.js 14

## Scaffold (new project)
```bash
npx create-next-app@latest {name} --typescript --tailwind --app --src-dir --import-alias "@/*"
cd {name}
```

## Dev Dependencies
```bash
npm install -D vitest @vitejs/plugin-react @testing-library/react @testing-library/jest-dom @testing-library/user-event
npm install -D @playwright/test wait-on
npx playwright install chromium --with-deps
npm install zod
```

## Runtime Dependencies
```bash
# ORM + DB
npm install prisma @prisma/client
npx prisma init

# Auth
npm install bcrypt jsonwebtoken
npm install -D @types/bcrypt @types/jsonwebtoken

# i18n
npm install next-intl

# UI (both allowed — use shadcn/ui for base components, antd/material-ui for complex data components)
npm install antd
# OR: npm install @mui/material @emotion/react @emotion/styled
```

## Test Config

Write `vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom', setupFiles: ['./src/test/setup.ts'] }
})
```

Write `src/test/setup.ts`:
```ts
import '@testing-library/jest-dom'
```

## Commands
```
build:      npm run build
typecheck:  npx tsc --noEmit
lint:       npx eslint src --ext .ts,.tsx --max-warnings 0
dev:        npx next dev --port 3001
unit-test:  npx vitest run --coverage --reporter=json --outputFile=.pipeline/vitest-raw.json
e2e-test:   npx playwright test --base-url http://localhost:3001 --reporter=json
```

## Dev Server Port
3001

## File Structure (new project)
```
src/
  app/
    layout.tsx
    page.tsx
    (routes)/
      {feature}/        ← feature route folder
        page.tsx
        _components/    ← components scoped to this route
  components/
    ui/                 ← shadcn/ui files, never edit manually
  lib/
    utils.ts
    types.ts
    auth.ts             ← JWT helpers
    prisma.ts           ← Prisma client singleton
  hooks/
  messages/             ← i18n locale files
    en.json
    id.json
```

## Component Library
shadcn/ui (base components) + antd or @mui/material (complex data components e.g. tables, date pickers)

shadcn/ui install:
- `npx shadcn-ui@latest add {component} --yes`
- Import from `@/components/ui/`
- Never edit files inside `components/ui/`

antd: import directly — `import { Table, DatePicker } from 'antd'`

## Code Conventions

### TypeScript
- No `any` without explanatory comment
- Explicit return types on all functions and components
- Props: `interface {Component}Props { ... }`

### React
- Functional components only
- `'use client'` only when using browser APIs or event handlers
- No inline styles — Tailwind classes only
- `next/image` for all `<img>` · `next/link` for all internal links
- `React.memo` for pure components
- Extract reusable logic into custom hooks (`useCamelCase.ts`)
- Default exports for page components; named exports for shared components

### Folder organization
- Feature-based folders — not type-based
- Co-locate component, styles, and tests in same folder
- PascalCase for component files and folders (`UserProfile.tsx`)
- Keep components small; extract logic to hooks

### API Routes
- Validate all input with zod
- Return consistent shape: `{ data, error }`
- Never hardcode secrets — use environment variables

### Database (Prisma)
- Every table must have full audit columns:
  ```prisma
  createdAt   DateTime  @default(now())
  createdBy   String
  updatedAt   DateTime  @updatedAt
  updatedBy   String
  isDeleted   Boolean   @default(false)
  deletedAt   DateTime?
  deletedBy   String?
  ```
- Always use soft delete — never `DELETE` rows. Filter `isDeleted: false` in all queries.
- Prisma client singleton in `src/lib/prisma.ts`

### Authentication
- JWT-based auth with bcrypt password hashing
- Store JWT in HttpOnly cookie (not localStorage)
- Role-based access: validate role on every protected API route
- After login, always redirect to `/dashboard`

### i18n
- Use `next-intl` — locale files in `src/messages/{locale}.json`
- Supported locales: `en`, `id` (Indonesian)
- All user-facing strings must use translation keys — no hardcoded UI text

### UI / Design
- Minimalist modern style — clean lines, consistent spacing
- Responsive + mobile-friendly on all layouts
- Dark mode toggle (default: light mode) — use Tailwind `dark:` classes
- Smooth transitions and subtle animations
- Maintain a11y: color contrast, keyboard navigation

### File Naming
- Components: `PascalCase.tsx`
- Hooks: `useCamelCase.ts`
- Utils: `camelCase.ts`
- Tests: `{FileName}.test.tsx`

## Unit Test Pattern
```tsx
import { render, screen } from '@testing-library/react'
import { Foo } from './Foo'

describe('Foo', () => {
  it('{acceptance criterion}', () => {
    render(<Foo />)
    expect(screen.getByRole('...')).toBeInTheDocument()
  })
})
```
One test per acceptance criterion in spec.

## Performance Review Checks
```bash
npm run build 2>&1 | grep -E "Route|Size|First Load JS"
grep -rn "<img " src --include="*.tsx"
grep -rn "'use client'" src --include="*.tsx" -l | wc -l
cat package.json | grep -E '"moment"|"lodash"'
```
Thresholds:
- First Load JS > 500kB → CRITICAL; 250–500kB → WARN
- Raw `<img>` instead of `next/image` → WARN per file
- More than 10 `'use client'` files → WARN
- `moment` or full `lodash` → INFO

## API Completeness Check
```bash
find src/app/api -name "route.ts" -exec grep -L "z\." {} \; 2>/dev/null
```
- API routes without zod validation → WARN per file

## Known Gaps (require clarification per project)
- **Email service** — choose: Nodemailer (SMTP) / Resend / SendGrid. Add to npm deps when needed.
- **File uploads** — choose: local disk / AWS S3 / Cloudinary. Add when needed.
- **Charts** — choose: Recharts / Chart.js / Victory. Add when needed.
- **Scheduled jobs** — choose: node-cron / Bull / Vercel Cron. Add when needed.
- **PDF generation** — choose: fast-report / react-pdf / Puppeteer. Add when needed.
