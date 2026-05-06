#!/bin/bash
set -euo pipefail

REGION=${AWS_REGION:-ap-south-2}
ACCOUNT_ID=${AWS_ACCOUNT_ID:-949474133081}
ECR_REGISTRY=${ECR_REGISTRY:-$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com}
APP_REPOSITORY=${APP_REPOSITORY:-travel-app-repo}
ECR_URI=$ECR_REGISTRY/$APP_REPOSITORY

IMAGE_TAG=${1:-}

if [ -z "$IMAGE_TAG" ]; then
  echo "IMAGE_TAG not provided"
  exit 1
fi

container_env() {
  local key=$1

  docker inspect travel-app \
    --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null |
    awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' ||
    true
}

script_env() {
  local key=$1

  if [ ! -f /home/ec2-user/update_app.sh ]; then
    return 0
  fi

  awk -v key="$key" '
    index($0, "-e " key "=") {
      value = $0
      sub(".*-e " key "=", "", value)
      sub(/[[:space:]\\].*/, "", value)
      print value
      exit
    }
  ' /home/ec2-user/update_app.sh ||
    true
}

require_value() {
  local name=$1
  local value=$2

  if [ -z "$value" ]; then
    echo "Missing required deployment value: $name"
    echo "Set $name in the workflow/SSM command or deploy once after Terraform refreshes user data."
    exit 1
  fi
}

resolve_env() {
  local key=$1
  local default_value=${2:-}
  local value=${!key:-}

  if [ -z "$value" ]; then
    value=$(container_env "$key")
  fi

  if [ -z "$value" ]; then
    value=$(script_env "$key")
  fi

  if [ -z "$value" ]; then
    value=$default_value
  fi

  printf "%s" "$value"
}

DB_HOST=$(resolve_env DB_HOST)
DB_NAME=$(resolve_env DB_NAME)
DB_USER=$(resolve_env DB_USER)
DB_SECRET_ARN=$(resolve_env DB_SECRET_ARN)
DB_PASSWORD=$(resolve_env DB_PASSWORD)
SQS_QUEUE_URL=$(resolve_env SQS_QUEUE_URL)
BUCKET_NAME=$(resolve_env BUCKET_NAME travel-platform-assets-952341)

require_value DB_HOST "$DB_HOST"
require_value DB_NAME "$DB_NAME"
require_value DB_USER "$DB_USER"
require_value SQS_QUEUE_URL "$SQS_QUEUE_URL"

if [ -z "$DB_SECRET_ARN" ] && [ -z "$DB_PASSWORD" ]; then
  echo "Missing database password configuration: DB_SECRET_ARN or DB_PASSWORD is required"
  exit 1
fi

docker_env=(
  -e AWS_REGION="$REGION"
  -e BUCKET_NAME="$BUCKET_NAME"
  -e SQS_QUEUE_URL="$SQS_QUEUE_URL"
  -e DB_HOST="$DB_HOST"
  -e DB_NAME="$DB_NAME"
  -e DB_USER="$DB_USER"
)

if [ -n "$DB_SECRET_ARN" ]; then
  docker_env+=(-e DB_SECRET_ARN="$DB_SECRET_ARN")
fi

if [ -n "$DB_PASSWORD" ]; then
  docker_env+=(-e DB_PASSWORD="$DB_PASSWORD")
fi

echo "Deploying image: $ECR_URI:$IMAGE_TAG"

aws ecr get-login-password --region "$REGION" |
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker pull "$ECR_URI:$IMAGE_TAG"

echo "Running database migrations..."
docker run --rm "${docker_env[@]}" "$ECR_URI:$IMAGE_TAG" \
  python -m alembic -c alembic.ini upgrade head

echo "Restarting travel-app..."
docker stop travel-app || true
docker rm travel-app || true

docker run -d -p 3000:3000 --name travel-app \
  --restart always \
  "${docker_env[@]}" \
  "$ECR_URI:$IMAGE_TAG"

echo "App deployment completed"
