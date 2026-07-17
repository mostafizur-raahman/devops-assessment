# DevOps Technical Assessment: Automated Multi-Site Deployment

A production-ready, fully automated deployment solution featuring two containerized static websites, an Nginx reverse proxy, and a robust CI/CD pipeline using GitHub Actions.

**Heads up about the live IP:** I used a temporary AWS Lab (2-hour session) to test this, so the EC2 instance gets shut down automatically once the session ends. If you're checking this later and the IP doesn't load, that's why.Screenshots below show it running live during testing, and the steps in this README work end-to-end on any EC2 instance.

## Project Overview

This project demonstrates a complete DevOps workflow. It consists of two distinct static websites (a Company Landing Page and a Portfolio) that are:

1. Containerized using optimized Docker images.
2. Orchestrated locally and on production using Docker Compose.
3. Routed through a single Nginx reverse proxy using path-based routing.
4. Automatically deployed to an AWS EC2 instance via GitHub Actions on every push to the `master` branch.

## Features

- ✅ **Proper Docker Image Optimization**: Uses lightweight `nginx:alpine` base images and `.dockerignore` files to minimize image size and build time.

- ✅ **Environment Variables**: Configuration is externalized using a `.env` file for flexibility across environments.

## 📸 Screenshots

### Site 1 (Company)

![Site 1](public/site1.png)

### Site 2 (Portfolio)

![Site 2](public/site2.png)

### Successful Deployment Pipeline

## ![Pipeline Success](public/healthy.png)

## 📁 Folder Structure

```text
devops-assessment/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD pipeline
├── deployment/
│   └── deploy.sh               # Automated server deployment script
├── nginx/
│   └── nginx.conf              # Reverse proxy configuration
├── site1/                      # Company Landing Page
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── index.html
│   └── style.css
├── site2/                      # Portfolio Page
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── index.html
│   └── style.css
├── .env.example                # Template for environment variables
├── .gitignore
├── docker-compose.yml          # Container orchestration
└── README.md                   # This file
```

## 🖥️ Server & Local Requirements

### Local Development

- Docker Engine (v20.10+)
- Docker Compose Plugin (v2.0+)

### Production (AWS EC2)

- Ubuntu 22.04 LTS or 24.04 LTS (t2.micro or higher)
- Docker Engine & Docker Compose Plugin installed
- Security Group allowing inbound traffic on:
    - Port 22 (SSH) from your IP or `0.0.0.0/0`
    - Port 80 (HTTP) from `0.0.0.0/0`

---

## How to Run the Project Locally

**1. Clone the repository:**

```bash
git clone https://github.com/mostafizur-raahman/devops-assessment.git
cd devops-assessment
```

**2. Create your environment file:**

```bash
cat <<EOF > .env
COMPOSE_PROJECT_NAME=devops-assessment
APP_ENV=development
APP_VERSION=1.0.0
NGINX_PORT=80
NGINX_HOST=localhost
SITE1_PATH=/site1
SITE2_PATH=/site2
RESTART_POLICY=unless-stopped
HEALTHCHECK_INTERVAL=30s
HEALTHCHECK_TIMEOUT=3s
HEALTHCHECK_RETRIES=3
EOF
```

**3. Build and start the containers:**

```bash
docker compose up -d --build
```

**4. Verify the deployment:**

Open your browser and navigate to:

- **Site 1 (Company):** http://localhost/site1/
- **Site 2 (Portfolio):** http://localhost/site2/
- **Health Check:** http://localhost/health

**5. Stop the containers:**

```bash
docker compose down
```

## Overview

---

## AWS EC2 Setup (One-Time Manual Step)

Before the CI/CD pipeline can run, the target server must be prepared.

**1. Launch an Ubuntu EC2 instance.**

**2. Configure the Security Group** to allow HTTP (80) and SSH (22).

**3. SSH into the instance and install Docker:**

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
sudo systemctl enable docker
newgrp docker
docker --version && docker compose version
```

**4. Clone the repository once to establish the directory:**

```bash
git clone https://github.com/mostafizur-raahman/devops-assessment.git /home/ubuntu/devops-assessment
```

---

## CI/CD Pipeline & Deployment Steps (GitHub Actions)

The deployment is fully automated. Every push to the `master` branch triggers the `.github/workflows/deploy.yml` workflow.

### 1. Configure GitHub Secrets

Navigate to your GitHub Repository → **Settings** → **Secrets and variables** → **Actions**, and add the following repository secrets:

| Secret Name   | Description                                             | Example Value                        |
| ------------- | ------------------------------------------------------- | ------------------------------------ |
| `AWS_HOST`    | The Public IPv4 address of your EC2 instance            | `54.169.199.22`                      |
| `AWS_USER`    | The SSH username for the OS                             | `ubuntu`                             |
| `AWS_SSH_KEY` | Your entire private SSH key (including BEGIN/END lines) | `-----BEGIN RSA PRIVATE KEY-----...` |

> ⚠️ **Recommended:** paste your `.pem` key into the secret using the GitHub CLI instead of the web textarea — pasting through the browser can silently strip newlines or add characters, which breaks key parsing:
>
> ```bash
> gh secret set AWS_SSH_KEY < devops-assesment.pem
> gh secret set AWS_HOST --body "54.169.199.22"
> gh secret set AWS_USER --body "ubuntu"
> ```

### 2. How the Deployment Works

When triggered, the workflow uses `appleboy/ssh-action` to connect to the server and execute `deployment/deploy.sh`, which performs the following steps:

1. Navigates to the project directory.
2. Force-syncs the code with GitHub using `git fetch --all` and `git reset --hard origin/master` (ensuring a clean state and preventing merge conflicts).
3. Generates the `.env` file dynamically (since it is ignored by Git).
4. Stops existing containers (`docker compose down`).
5. Rebuilds and starts the new containers (`docker compose up -d --build`).
6. Cleans up dangling Docker images to prevent disk space exhaustion (`docker image prune -f`).

### 3. Testing the Pipeline

1. Push a commit to `master`.
2. Go to the **Actions** tab and open the latest **Deploy to AWS** run.
3. Confirm the **Deploy to AWS EC2 via SSH** step completes without errors.
4. Visit `http://<AWS_HOST>/site1/` and `http://<AWS_HOST>/site2/` to confirm the update went live.

---

## ⚙️ Nginx Configuration

The `nginx/nginx.conf` file acts as a reverse proxy, routing incoming traffic to the correct Docker container based on the URL path.

- Requests to `/site1/` are proxied to the `site1` container.
- Requests to `/site2/` are proxied to the `site2` container.
- Requests to `/` are redirected (301) to `/site1/`.
- A `/health` endpoint is provided for uptime monitoring.

> **Note:** Trailing slashes are strictly used in the `location` and `proxy_pass` directives to ensure static assets (CSS, images) load correctly without path-prefix issues.

---

## 💡 Assumptions & Design Decisions

- **Path-Based Routing:** Chose `/site1` and `/site2` over subdomains (`site1.local`). This requires zero DNS or local hosts file configuration for the evaluator, making it instantly testable on any IP address.
- **Alpine Base Images:** Used `nginx:alpine` to adhere to the principle of least privilege and minimize the attack surface and build times.
- **Dynamic `.env` Generation:** The `.env` file is generated by the deployment script rather than stored in Git. This keeps sensitive or environment-specific configurations out of version control while ensuring the server has what it needs to run `docker compose`.

---

## 🛠️ Troubleshooting

| Issue                                                        | Cause                                                              | Fix                                                                                                                                                                                                                    |
| ------------------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **"Port 80 is already allocated"**                           | Another web server (Apache, local Nginx) is running on the host    | Run `sudo lsof -i :80` to check and stop the conflicting process                                                                                                                                                       |
| **404 Not Found on `/site1`**                                | Missing trailing slash                                             | Use `/site1/`. Nginx redirects `/site1` → `/site1/`, but browser caching can interfere — try a hard refresh (`Ctrl + F5`)                                                                                              |
| **GitHub Actions "Permission Denied" / `ssh: no key found`** | `AWS_SSH_KEY` secret is malformed or incomplete                    | Verify the secret contains the entire private key, including `-----BEGIN...` and `-----END...` lines, with no trailing spaces or characters. Prefer `gh secret set AWS_SSH_KEY < file.pem` over pasting via the web UI |
| **`handshake failed: unable to authenticate`**               | Wrong `AWS_USER`, key mismatch, or Security Group blocking port 22 | Confirm username matches the AMI (`ubuntu` for Ubuntu); confirm Security Group allows inbound `22` from `0.0.0.0/0`; confirm the public key is present in `~/.ssh/authorized_keys` on the instance                     |
| **"Your local changes... would be overwritten by merge"**    | Files were edited directly on the EC2 server outside of Git        | Already mitigated by using `git fetch` + `git reset --hard origin/master` in `deploy.sh` instead of `git pull`                                                                                                         |
| **Site unreachable after a successful deploy**               | Security Group missing inbound rule for port 80                    | Add an inbound rule allowing HTTP (80) from `0.0.0.0/0`                                                                                                                                                                |
