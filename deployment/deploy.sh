#!/bin/bash
set -e

echo "Starting deployment..."

cd /home/ubuntu/devops-assessment || exit 1

echo "Pulling latest code..."
git pull origin master


echo "Generating environment variables..."
cat <<EOF > .env
COMPOSE_PROJECT_NAME=devops-assessment
APP_ENV=production
APP_VERSION=1.0.0

NGINX_PORT=80
NGINX_HOST=localhost

SITE1_PATH=/site1
SITE2_PATH=/site2

DOCKER_NETWORK=devops-assesment
RESTART_POLICY=unless-stopped

HEALTHCHECK_INTERVAL=30s
HEALTHCHECK_TIMEOUT=3s
HEALTHCHECK_RETRIES=3
EOF

echo "Stopping old containers..."
docker compose down

echo "Building and starting containers..."
docker compose up -d --build

echo "🧹 Cleaning up unused Docker images..."
docker image prune -f

echo "Deployment successful!"
docker compose ps