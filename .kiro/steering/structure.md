# Project Structure

## Layout

```
.
├── app/                 # Next.js App Router
│   ├── layout.tsx       # Root layout
│   ├── page.tsx         # Home page
│   ├── globals.css      # Global styles (Tailwind)
│   └── favicon.ico
├── public/              # Static assets served at /
├── next.config.ts       # Next.js config (add output: "standalone" here)
├── tsconfig.json        # TS config; @/* alias -> project root
├── eslint.config.mjs    # Flat ESLint config
├── postcss.config.mjs   # PostCSS / Tailwind
├── Dockerfile           # Multi-stage build (to be added if missing)
└── .github/workflows/   # CI/CD (deploy.yml -> build & push to ECR)
```

## Conventions

- App Router only — put routes, layouts, and pages under `app/`.
- Use the `@/*` import alias for absolute imports from the project root.
- Keep the app minimal; this is a deployment-focused starter, not a feature app.
- Infrastructure and CI config (Dockerfile, GitHub Actions) are first-class
  parts of this repo — keep them in sync with `README.md`.
- Static files go in `public/` and are served from the site root.
