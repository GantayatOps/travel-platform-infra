#!/bin/bash
set -e

# Start Docker
systemctl start docker
systemctl enable docker

# Region
REGION=ap-south-2
ACCOUNT_ID=949474133081

# Repos
ECR_REPO=travel-app-repo
WORKER_ECR_REPO=travel-worker-repo

ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO
WORKER_ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$WORKER_ECR_REPO

echo "Logging into ECR..."

# Login to ECR
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "Pulling latest images..."

# Pull latest images
docker pull $ECR_URI:latest
docker pull $WORKER_ECR_URI:latest

echo "Cleaning up old containers (if any)..."

# Docker Cleanup
docker stop travel-app || true
docker rm travel-app || true

docker stop travel-worker || true
docker rm travel-worker || true

echo "Starting travel-app..."

# Start App container
docker run -d -p 3000:3000 --name travel-app \
  --restart always \
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  -e DB_HOST=${db_endpoint} \
  -e DB_NAME=postgres \
  -e DB_USER=postgres \
  -e DB_PASSWORD=${db_password} \
  $ECR_URI:latest

echo "Waiting before starting worker..."
sleep 5

echo "Starting travel-worker..."

# Start Worker container
docker run -d --name travel-worker \
  --restart always \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  -e DB_HOST=${db_endpoint} \
  -e DB_NAME=postgres \
  -e DB_USER=postgres \
  -e DB_PASSWORD=${db_password} \
  $WORKER_ECR_URI:latest

echo "Creating update_app.sh..."

# Create /home/ec2-user/update_app.sh
cat << 'EOF' > /home/ec2-user/update_app.sh
#!/bin/bash
set -e

REGION=ap-south-2
ACCOUNT_ID=949474133081
ECR_REPO=travel-app-repo
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO

IMAGE_TAG=$1

if [ -z "$IMAGE_TAG" ]; then
  echo "IMAGE_TAG not provided"
  exit 1
fi

echo "Deploying image: $IMAGE_TAG"

aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker pull $ECR_URI:$IMAGE_TAG

docker stop travel-app || true
docker rm travel-app || true

docker run -d -p 3000:3000 --name travel-app \
  --restart always \
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  -e DB_HOST=${db_endpoint} \
  -e DB_NAME=postgres \
  -e DB_USER=postgres \
  -e DB_PASSWORD=${db_password} \
  $ECR_URI:$IMAGE_TAG

echo "App deployment completed"
EOF

echo "Creating update_worker.sh..."

# Create /home/ec2-user/update_worker.sh
cat << 'EOF' > /home/ec2-user/update_worker.sh
#!/bin/bash
set -e

REGION=ap-south-2
ACCOUNT_ID=949474133081
ECR_REPO=travel-worker-repo
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO

IMAGE_TAG=$1

if [ -z "$IMAGE_TAG" ]; then
  echo "IMAGE_TAG not provided"
  exit 1
fi

echo "Deploying worker image: $IMAGE_TAG"

aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker pull $ECR_URI:$IMAGE_TAG

docker stop travel-worker || true
docker rm travel-worker || true

docker run -d --name travel-worker \
  --restart always \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  -e DB_HOST=${db_endpoint} \
  -e DB_NAME=postgres \
  -e DB_USER=postgres \
  -e DB_PASSWORD=${db_password} \
  $ECR_URI:$IMAGE_TAG

echo "Worker deployment completed"
EOF

# Make scripts executable
chmod +x /home/ec2-user/update_app.sh
chmod +x /home/ec2-user/update_worker.sh

echo "========================================="
echo "User Data setup completed"

echo ""
echo "Available deployment scripts:"
echo "  /home/ec2-user/update_app.sh <IMAGE_TAG>"
echo "  /home/ec2-user/update_worker.sh <IMAGE_TAG>"

echo ""
echo "Example usage:"
echo "  /home/ec2-user/update_app.sh latest"
echo "  /home/ec2-user/update_worker.sh latest"

echo ""
echo "Check running containers:"
echo "  docker ps"

echo ""
echo "Check logs:"
echo "  docker logs travel-app"
echo "  docker logs travel-worker"

echo "========================================="