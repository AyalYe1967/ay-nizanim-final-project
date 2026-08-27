# GitHub Actions → AWS ECR OIDC Permissions

This document records the AWS IAM permissions and trust relationship used by the GitHub Actions workflow that builds the Status-Page Docker image and pushes it to Amazon ECR.

## Purpose

```text
GitHub push to main
        ↓
GitHub Actions
        ↓
GitHub OIDC token
        ↓
AWS STS AssumeRoleWithWebIdentity
        ↓
IAM role
        ↓
Amazon ECR
        ↓
Push <ECR_REPOSITORY> image
```

No long-lived AWS access key or secret access key is stored in GitHub.

## GitHub / AWS Values

```text
GitHub owner:        <GITHUB_OWNER>
GitHub owner ID:     <GITHUB_OWNER_ID>
Repository:          <GITHUB_REPOSITORY>
Repository ID:       <GITHUB_REPOSITORY_ID>
Allowed branch:      main

AWS account ID:      <AWS_ACCOUNT_ID>
AWS region:          <AWS_REGION>
ECR repository:      <ECR_REPOSITORY>
```

GitHub repository variables:

```text
AWS_REGION=<AWS_REGION>
ECR_REPOSITORY=<ECR_REPOSITORY>
```

GitHub Actions secret:

```text
AWS_ROLE_ARN=arn:aws:iam::<AWS_ACCOUNT_ID>:role/<GITHUB_ACTIONS_ECR_ROLE_NAME>
```

> The role ARN itself is not an AWS credential. The workflow uses GitHub OIDC to obtain temporary credentials from AWS STS.

---

## 1. IAM Permission Policy

Suggested policy name:

```text
<GITHUB_ACTIONS_ECR_POLICY_NAME>
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:BatchGetImage"
      ],
      "Resource": "arn:aws:ecr:<AWS_REGION>:<AWS_ACCOUNT_ID>:repository/<ECR_REPOSITORY>"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
```

This policy allows the role to authenticate to ECR and push Docker image layers and manifests only to the `<ECR_REPOSITORY>` repository.

`ecr:GetAuthorizationToken` uses `"Resource": "*"` because the ECR authorization token is not scoped to a single repository ARN.

---

## 2. IAM Role Trust Policy

Suggested role name:

```text
<GITHUB_ACTIONS_ECR_ROLE_NAME>
```

Trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:<GITHUB_OWNER>@<GITHUB_OWNER_ID>/<GITHUB_REPOSITORY>@<GITHUB_REPOSITORY_ID>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

This trust policy answers:

> Who is allowed to assume this IAM role?

Only the GitHub Actions OIDC identity for:

```text
Owner:      <GITHUB_OWNER> / <GITHUB_OWNER_ID>
Repository: <GITHUB_REPOSITORY> / <GITHUB_REPOSITORY_ID>
Branch:     main
Audience:   sts.amazonaws.com
```

can assume the role.

The important STS action is:

```text
sts:AssumeRoleWithWebIdentity
```

This belongs in the **role trust policy**, not in the ECR permission policy.

---

## 3. GitHub Actions Requirements

The workflow must allow GitHub to request an OIDC token:

```yaml
permissions:
  contents: read
  id-token: write
```

AWS authentication step:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ vars.AWS_REGION }}
```

Current trigger:

```yaml
on:
  push:
    branches:
      - main
```

Expected flow:

```text
development branch
      ↓
Pull Request
      ↓
merge to main
      ↓
push event on main
      ↓
GitHub OIDC authentication
      ↓
Build Docker image
      ↓
Push image to ECR
```

---

## 4. Security Notes

- Do **not** store `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in the repository.
- GitHub OIDC provides short-lived AWS credentials instead.
- Keep the IAM trust policy limited to the exact GitHub repository and branch that need it.
- Keep ECR permissions restricted to the `<ECR_REPOSITORY>` repository where possible.
- Application secrets such as Django `SECRET_KEY`, database passwords, API tokens, and production credentials must not be committed to Git.
- Keep the local `.env` file in `.gitignore`.
- In AWS production, application secrets should be injected at runtime through AWS Secrets Manager or another secure secret mechanism.

---

## 5. Future ECS Deployment Permissions

This role currently covers only the **build and push to ECR** workflow.

When the deployment workflow later updates ECS/Fargate, the deployment role may require permissions such as:

```text
ecs:RegisterTaskDefinition
ecs:UpdateService
ecs:DescribeServices
ecs:DescribeTaskDefinition
iam:PassRole
```

The exact ECS permissions should be documented only after the Terraform/ECS architecture is finalized.
