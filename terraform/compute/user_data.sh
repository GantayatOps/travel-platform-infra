#!/bin/bash
set -e

# Start Docker
systemctl start docker
systemctl enable docker

# Region
REGION=ap-south-2
ACCOUNT_ID=949474133081
ECR_REPO=travel-app-repo
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO

# Login to ECR
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Initial deployment
docker pull $ECR_URI:latest

docker run -d -p 3000:3000 --name travel-app \
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  $ECR_URI:latest

# CREATE UPDATE SCRIPT (USED BY SSM)
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
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  $ECR_URI:$IMAGE_TAG

echo "Deployment completed"
EOF

# Make script executable
chmod +x /home/ec2-user/update_app.sh