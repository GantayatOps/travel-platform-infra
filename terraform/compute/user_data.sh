#!/bin/bash

# Start Docker
systemctl start docker
systemctl enable docker

# Get region
REGION=ap-south-2

# Login to ECR
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin 949474133081.dkr.ecr.$REGION.amazonaws.com

# Pull image
docker pull 949474133081.dkr.ecr.$REGION.amazonaws.com/travel-app-repo:latest

# Run container
docker run -d -p 3000:3000 --name travel-app \
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  949474133081.dkr.ecr.$REGION.amazonaws.com/travel-app-repo:latest