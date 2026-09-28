# Sample Node.js CI/CD Pipeline

A complete Continuous Integration and Continuous Delivery (CI/CD) reference pipeline built with Node.js, Docker, GitHub Actions, and Caddy. It implements automated matrix testing, container artifact creation, and promotion through staging and production environments hosted on an Oracle Cloud Infrastructure (OCI) VPS.

---

## 🏗️ Architecture Overview

```text
                               ┌─────────────────────────────────────────────────────────┐
                               │                    GitHub Actions                       │
                               └──────────────────────────┬──────────────────────────────┘
                                                          │
                                     1. Build & Push      │ 2. Deploy via SSH
                                        Docker Image      │    (ghcr.io Image Tag)
                                                          ▼
                               ┌─────────────────────────────────────────────────────────┐
                               │                    Oracle Cloud VPS                     │
                               │                                                         │
                               │   ┌─────────────────────────────────────────────────┐   │
                               │   │              Caddy Reverse Proxy                │   │
                               │   └───────────────┬─────────────────┬───────────────┘   │
                               │                   │                 │                   │
                               │  amin-test.duckdns.org    amin-prod.duckdns.org         │
                               │                   │                 │                   │
                               │                   ▼                 ▼                   │
                               │             ┌───────────┐     ┌───────────┐             │
                               │             │  Staging  │     │Production │             │
                               │             │ Container │     │ Container │             │
                               │             │(Port 3001)│     │(Port 3000)│             │
                               │             └───────────┘     └───────────┘             │
                               └─────────────────────────────────────────────────────────┘
```

---

## ✨ Features

* **Continuous Integration (`ci.yml`)**:
  * Matrix testing across multiple Node.js runtimes (20, 22).
  * Automated linting and native unit test execution (`node --test`).
  * Concurrency management to auto-cancel superseded pull request builds.
* **Continuous Delivery (`deliver.yml`)**:
  * Build-once principle: Builds a Docker image tagged with the Git commit SHA and pushes it to GitHub Container Registry (GHCR).
  * Repo name normalization step (`prep` job) to prevent capital-letter registry errors.
  * Staging deployment over SSH with automated HTTP smoke tests (`https://amin-test.duckdns.org`).
  * Manual approval gate for production deployments (`https://amin-prod.duckdns.org`).
* **Infrastructure & Security**:
  * Automatic HTTPS certificates managed by Caddy.
  * Branch protection and GitHub Rulesets blocking direct pushes to `main`.

---

## 📁 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml              # Matrix tests & linting on PR / main
│       └── deliver.yml         # Container build, staging deploy & prod promotion
├── scripts/
│   ├── deploy.sh               # Remote SSH execution trigger
│   └── smoke-test.sh           # HTTP health check polling script
├── Dockerfile                  # Production container definition
├── index.js                    # Express application entry point
├── index.test.js               # Native Node test suite
├── package.json                # Project dependencies and scripts
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

* Node.js v20 or v22 installed locally.
* Docker runtime for building images locally.
* An OCI VPS (Ubuntu) with public ports `80` and `443` open.

### Local Development

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Run linting checks**:
   ```bash
   npm run lint
   ```

3. **Run unit tests**:
   ```bash
   npm test
   ```

4. **Start the local server**:
   ```bash
   npm start
   # Server runs on http://localhost:3000
   ```

---

## ⚙️ VPS & Deployment Setup

### 1. Firewall Configuration (VPS)

Ensure Oracle VCN Security Lists allow TCP on ports `80` and `443`, then allow traffic through `iptables`:

```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

### 2. Caddy Reverse Proxy (`/etc/caddy/Caddyfile`)

```caddyfile
amin-test.duckdns.org {
    reverse_proxy 127.0.0.1:3001
}

amin-prod.duckdns.org {
    reverse_proxy 127.0.0.1:3000
}
```

Reload configuration:
```bash
sudo systemctl reload caddy
```

### 3. VPS Deployment Runner (`/usr/local/bin/deploy-app.sh`)

Create this script on your VPS and mark it executable (`sudo chmod +x /usr/local/bin/deploy-app.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_TYPE="$1"       # "staging" or "production"
IMAGE_TAG="$2"      # ghcr.io/<owner>/<repo>:<sha>
GHCR_TOKEN="$3"
GHCR_USER="$4"

if [ "$ENV_TYPE" = "staging" ]; then
    CONTAINER_NAME="app-staging"
    HOST_PORT="3001"
elif [ "$ENV_TYPE" = "production" ]; then
    CONTAINER_NAME="app-production"
    HOST_PORT="3000"
else
    echo "Invalid environment. Use 'staging' or 'production'."
    exit 1
fi

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
docker pull "$IMAGE_TAG"
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "127.0.0.1:${HOST_PORT}:3000" \
  -e "NODE_ENV=${ENV_TYPE}" \
  "$IMAGE_TAG"
```

---

## 🔑 GitHub Configuration

### 1. Repository Secrets

Set these in **Settings > Secrets and variables > Actions > Repository secrets**:

| Secret Name | Description |
| :--- | :--- |
| `VPS_HOST` | Oracle Cloud VPS Public IP address |
| `VPS_USER` | VPS SSH Username (e.g., `ubuntu`) |
| `VPS_SSH_KEY` | Private SSH Key matching `~/.ssh/authorized_keys` on VPS |

### 2. GitHub Environments

Set these under **Settings > Environments**:
* `staging`: No protection rules.
* `production`: Enable **Required reviewers** and assign repository admins.

### 3. Branch Protection / Rulesets

Under **Settings > Rulesets**, target the `main` branch with:
* Require a pull request before merging.
* Require status checks to pass (`test (ubuntu-latest, 20)` and `test (ubuntu-latest, 22)`).
* Block direct pushes to `main`.

---

## 🔄 Development & Release Workflow

1. **Feature Branching**:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. **Push & Open Pull Request**:
   ```bash
   git push -u origin feature/my-new-feature
   ```
3. **Automated CI Validation**: `ci.yml` runs linters and unit tests across Node 20 and 22. Merging is blocked until checks pass.
4. **Staging Rollout**: Merging to `main` triggers `deliver.yml`, building a container image, pushing to GHCR, deploying to port `3001`, and executing smoke tests at `https://amin-test.duckdns.org`.
5. **Production Promotion**: Reviewers approve the deployment gate in the GitHub Actions UI to promote the identical image SHA to port `3000` (`https://amin-prod.duckdns.org`).