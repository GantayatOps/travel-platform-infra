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

# Auto-update script for continuous deployment
cat << EOF > /home/ec2-user/update_app.sh
#!/bin/bash

# Get region
REGION=ap-south-2

# Login to ECR
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin 949474133081.dkr.ecr.$REGION.amazonaws.com

# Pull latest image
docker pull 949474133081.dkr.ecr.$REGION.amazonaws.com/travel-app-repo:latest

# Stop existing container (if running)
docker stop travel-app || true

# Remove old container
docker rm travel-app || true

# Run container with latest image
docker run -d -p 3000:3000 --name travel-app \
  -e BUCKET_NAME=travel-platform-assets-952341 \
  -e SQS_QUEUE_URL=${sqs_queue_url} \
  949474133081.dkr.ecr.$REGION.amazonaws.com/travel-app-repo:latest
EOF

chmod +x /home/ec2-user/update_app.sh

# Cron not installed on Private EC2 yet
# Cron job (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ec2-user/update_app.sh") | crontab -