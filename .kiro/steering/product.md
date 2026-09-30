# Product

## Purpose

This project is a boilerplate Next.js application wired up for a container-based
CI/CD pipeline. The end goal is to build a Docker image of the Next.js app and
automatically push it to Amazon Elastic Container Registry (Amazon ECR) via
GitHub Actions on merges to `main`.

It exists as a starter/reference, so clarity and reproducibility matter more than
feature breadth.

## Core capabilities

- Next.js (App Router) app configured for `standalone` output to produce
  ultra-light Docker images.
- Multi-stage Dockerfile that separates dependency install, build, and runtime.
- GitHub Actions workflow that builds, tags, and pushes images to Amazon ECR.
- Keyless authentication to AWS using GitHub OIDC to assume an IAM role (no
  long-lived access keys).

## Image tagging convention

Images are tagged with both the Git commit SHA and `latest` when pushed to ECR.

## Key configuration touchpoints

- `AWS_REGION` / `ECR_REPOSITORY` — GitHub Actions repository variables.
- `AWS_ROLE_ARN` — GitHub Actions secret for the OIDC-assumed IAM role.
- ECR repository name defaults to `nextjs-app` in the docs.

Refer to `README.md` for the full AWS/OIDC setup guide.
