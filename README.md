# Next.js Docker to Amazon ECR CI/CD Pipeline

A boilerplate Next.js application configured with multi-stage Docker builds and an automated CI/CD workflow to build, tag, and push container images to Amazon Elastic Container Registry (Amazon ECR) using GitHub Actions.

---

## Architecture & Features

- **Next.js (App Router)** configured with `standalone` output for ultra-light Docker images.
- **Multi-Stage Dockerfile** separating dependencies, build, and runtime environments.
- **GitHub Actions CI/CD** pushing automatically to Amazon ECR on merge to `main`.
- **Keyless Authentication (OIDC)** to securely assume AWS IAM roles without long-lived access keys.

---

## Prerequisites

Before getting started, make sure you have:

- [Node.js](https://nodejs.org/) (v18.17+ or v20+)
- [Docker](https://docs.docker.com/get-docker/) installed locally
- An active [AWS Account](https://aws.amazon.com/) with administrative or deployment privileges
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured

---

## AWS Setup Guide

### 1. Create the Amazon ECR Repository

Using the AWS CLI:

```bash
aws ecr create-repository \
  --repository-name nextjs-app \
  --image-scanning-configuration scanOnPush=true \
  --region <YOUR_AWS_REGION>
```

Note the `repositoryUri` output (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/nextjs-app`).

---

### 2. Configure GitHub Actions OIDC Role (Recommended)

Using OpenID Connect (OIDC) avoids storing permanent AWS Access Keys in your repository secrets.

1. **Add GitHub as an Identity Provider in AWS IAM:**
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. **Create an IAM Role with a Trust Policy:**
   Create a role (e.g., `GitHubActionsECRPushRole`) with this trust relationship:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<YOUR_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": [
           "sts:AssumeRoleWithWebIdentity",
           "sts:TagSession"
         ],
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_USERNAME>*/<YOUR_REPO_NAME>*:*"
           }
         }
       }
     ]
   }
   ```

   > **Note — the `sub` claim now includes numeric ID suffixes.** GitHub has
   > started embedding immutable account and repository IDs in the OIDC `sub`
   > claim, so it looks like
   > `repo:owner@1814138/repo@1396615823:ref:refs/heads/main` rather than the
   > classic `repo:owner/repo:...`. A `sub` condition of the old form
   > (`repo:owner/repo:*`) will **not** match, and the assume-role call fails
   > with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. The
   > wildcards around the owner and repo name above (`owner*/repo*`) absorb the
   > `@<id>` suffixes while still scoping to your repository. To pin exact IDs
   > instead, look them up with
   > `gh api users/<owner> --jq '.id'` and
   > `gh api repos/<owner>/<repo> --jq '.id'`.

   > **Note — session tags (`sts:TagSession`).** The `aws-actions/configure-aws-credentials`
   > action attaches session tags by default. If your trust policy allows
   > session tagging you can keep `sts:TagSession` in the `Action` list above
   > (as shown); otherwise set `role-skip-session-tagging: true` on the action
   > in the workflow. Note this is a separate concern from the `sub` mismatch —
   > a wrong `sub` fails with the same `Not authorized` error whether or not
   > `sts:TagSession` is present, so fix the `sub` condition first.

3. **Attach Permissions to the Role:**
   Attach an inline policy granting permissions to authenticate and push to your ECR repository:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ecr:GetAuthorizationToken"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "ecr:BatchCheckLayerAvailability",
           "ecr:GetDownloadUrlForLayer",
           "ecr:BatchGetImage",
           "ecr:PutImage",
           "ecr:InitiateLayerUpload",
           "ecr:UploadLayerPart",
           "ecr:CompleteLayerUpload"
         ],
         "Resource": "arn:aws:ecr:<YOUR_AWS_REGION>:<YOUR_ACCOUNT_ID>:repository/nextjs-app"
       }
     ]
   }
   ```

---

### 3. Add GitHub Repository Secrets & Variables

In your GitHub repository, navigate to **Settings > Secrets and variables > Actions**:

#### Variables (`Repository variables`):
- `AWS_REGION`: Your target AWS region (e.g., `us-east-1`)
- `ECR_REPOSITORY`: Name of your repository (e.g., `nextjs-app`)

#### Secrets (`Repository secrets`):
- `AWS_ROLE_ARN`: The ARN of the IAM role you created (`arn:aws:iam::<YOUR_ACCOUNT_ID>:role/GitHubActionsECRPushRole`)

*(Alternative: If using standard IAM user credentials instead of OIDC, add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to Secrets.)*

---

## Local Development & Docker Build

### 1. Run Next.js Locally

```bash
npm install
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000).

---

### 2. Enable Next.js Standalone Mode

In `next.config.ts`, ensure output is set to `standalone`:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
};

export default nextConfig;
```

---

### 3. Build & Test Docker Image Locally

Build the container image:

```bash
docker build -t nextjs-app:local .
```

Run the container:

```bash
docker run -p 3000:3000 nextjs-app:local
```

Access the app at [http://localhost:3000](http://localhost:3000).

---

### 4. Manual Push to ECR (Optional Verification)

```bash
# 1. Authenticate Docker with AWS ECR
aws ecr get-login-password --region <YOUR_AWS_REGION> | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com

# 2. Tag local image
docker tag nextjs-app:local <YOUR_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com/nextjs-app:latest

# 3. Push to ECR
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com/nextjs-app:latest
```

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) is triggered automatically on pushes to the `main` branch. It executes the following steps:

1. Checks out repository code.
2. Assumes the designated AWS IAM role via OpenID Connect (OIDC).
3. Authenticates Docker to Amazon ECR.
4. Builds the Next.js Docker image with multi-stage caching.
5. Tags the image with both the Git commit SHA and `latest`.
6. Pushes the images to your ECR repository.

---

## License

Distributed under the MIT License. See `LICENSE` for more information.