# Tech Stack

## Framework & language

- **Next.js 16** with the **App Router** (`app/` directory).
- **React 19**.
- **TypeScript 5** in `strict` mode. Path alias `@/*` maps to the project root.
- **Tailwind CSS v4** via `@tailwindcss/postcss`.
- **ESLint 9** with `eslint-config-next`.

> Note: This Next.js version may differ from older conventions. Consult the
> guides in `node_modules/next/dist/docs/` before writing framework code, and
> heed deprecation notices.

## Commands

```bash
npm install      # install dependencies
npm run dev      # start dev server at http://localhost:3000
npm run build    # production build
npm run start    # run the production build
npm run lint     # run eslint
```

Do not run long-lived commands (`npm run dev`, watchers) as part of automated
steps — leave those for the user to run manually.

## Docker

- Uses a multi-stage `Dockerfile` (deps → build → runtime).
- Requires Next.js `output: "standalone"` for the slim runtime image.

```bash
docker build -t nextjs-app:local .
docker run -p 3000:3000 nextjs-app:local
```

## Deployment / CI-CD

- GitHub Actions workflow at `.github/workflows/deploy.yml`, triggered on push
  to `main`.
- Auth to AWS via OIDC (assume `AWS_ROLE_ARN`), then push to Amazon ECR.

## Known gap to keep in mind

The README documents `output: "standalone"` in `next.config.mjs`, but the actual
config is `next.config.ts` and does not yet set `output: "standalone"`. The
standalone Docker build depends on this, so add it to `next.config.ts` when
wiring up the Docker/CI work.
