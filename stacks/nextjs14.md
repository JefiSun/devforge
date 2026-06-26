---
stack: nextjs14
label: "Next.js 14 · TypeScript · Tailwind · shadcn/ui"
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
      route-name/
        page.tsx
  components/
    ui/              ← component library files, never edit manually
    {feature}/       ← feature components + co-located tests
  lib/
    utils.ts
    types.ts
  hooks/
```

## Component Library
shadcn/ui
- Install: `npx shadcn-ui@latest add {component} --yes`
- Import from `@/components/ui/`
- Never edit files inside `components/ui/`

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

### API Routes
- Validate all input with zod
- Return consistent shape: `{ data, error }`

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
