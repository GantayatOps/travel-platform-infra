# ECR Bootstrap Stack

This stack manages the long-lived ECR repository used by CI/CD:

- `travel-app-repo`
- `travel-worker-repo` is retained for historical worker images; active upload processing now runs on Lambda.

It is intentionally kept separate from the root Terraform stack so application infrastructure can be destroyed and recreated without deleting container image history or breaking future deployments.

## Apply

Run this once before the main app stack or CI/CD deployment:

```bash
cd terraform/ecr
terraform init
terraform apply
```

The repositories have `prevent_destroy = true`, so Terraform will block accidental deletion.

## Existing Repository

If the AWS repository already exists but this local ECR state is missing, import it before applying:

```bash
cd terraform/ecr
terraform init
terraform import aws_ecr_repository.app_repo travel-app-repo
terraform import aws_ecr_lifecycle_policy.keep_last_5 travel-app-repo
terraform import aws_ecr_repository.worker_repo travel-worker-repo
terraform import aws_ecr_lifecycle_policy.worker_keep_last_5 travel-worker-repo
terraform plan
```

Only remove or destroy this stack when intentionally retiring the project image history.
