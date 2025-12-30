# GitHub Environments Setup Guide

This guide explains how to configure GitHub environments for the fincore_Iasc project to enable manual approval for production deployments.

## Overview

The project uses two environments:
- **npe** (Non-Production Environment) - Auto-deploys from `develop` branch
- **prod** (Production) - Requires manual approval before deployment

## Setting Up Environments in GitHub

### 1. Navigate to Repository Settings

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Environments**

### 2. Create NPE Environment

1. Click **New environment**
2. Name: `npe`
3. Click **Configure environment**
4. **Deployment protection rules**: Leave empty (no approval needed)
5. **Environment secrets**: Add if needed
   - `GCP_SA_KEY` (if not using repository-level secret)
6. Click **Save protection rules**

### 3. Create Production Environment

1. Click **New environment**
2. Name: `prod`
3. Click **Configure environment**
4. **Deployment protection rules**:
   - ✅ Enable **Required reviewers**
   - Add yourself and/or team members who can approve production deployments
   - Maximum number: 1-6 reviewers
5. **Environment secrets**: Add if needed
   - `GCP_SA_KEY` (if different from NPE)
6. **Deployment branches**: 
   - Select **Selected branches**
   - Add rule: `main` (only allow deployments from main branch)
7. Click **Save protection rules**

## Environment Configuration Details

### NPE Environment
```yaml
Environment: npe
Auto-deploy: Yes
Approval Required: No
Deployment Branch: develop
Protection Rules: None
```

### Production Environment
```yaml
Environment: prod
Auto-deploy: No (manual workflow_dispatch only)
Approval Required: Yes
Required Reviewers: 1+ team members
Deployment Branch: main only
Protection Rules: 
  - Required reviewers
  - Branch restrictions
```

## Deployment Workflows

### Automatic NPE Deployment
- Triggers on push to `develop` branch
- No manual approval needed
- Automatically runs Terraform apply

### Manual Production Promotion
1. Go to **Actions** tab
2. Select **🔄 Promote NPE to Production** workflow
3. Click **Run workflow**
4. Type `PROMOTE` to confirm
5. Select options:
   - Skip tests: false (recommended)
   - Backup before deploy: true (recommended)
6. Click **Run workflow**
7. **Wait for approval** - designated reviewers will receive notification
8. Reviewer approves/rejects deployment
9. If approved, deployment proceeds automatically

## Required Secrets

Add these secrets at the repository level (Settings → Secrets and variables → Actions):

### Repository Secrets
- `GCP_SA_KEY`: Google Cloud Service Account JSON key with permissions:
  - Cloud SQL Admin
  - Compute Network Admin
  - Secret Manager Admin
  - Storage Admin

### Repository Variables
- `GCP_PROJECT_ID`: Your GCP project ID (e.g., `project-07a61357-b791-4255-a9e`)

## Testing the Setup

### Test NPE Auto-Deployment
1. Make a change to Terraform files
2. Commit to `develop` branch
3. Push to GitHub
4. Check Actions tab - deployment should start automatically
5. Verify deployment completes successfully

### Test Production Manual Approval
1. Go to Actions → **🔄 Promote NPE to Production**
2. Run workflow with `PROMOTE` confirmation
3. Verify that deployment **pauses** at production environment
4. Check that reviewers receive notification
5. Approve the deployment
6. Verify deployment completes after approval

## Approval Process

When a production deployment requires approval:

1. **Notification**: Reviewers receive GitHub notification
2. **Review**: Reviewer goes to Actions → Running workflow
3. **Inspect**: Review the Terraform plan and changes
4. **Decision**: Click **Review deployments**
5. **Approve/Reject**: Select environment and approve or reject
6. **Comment**: Add optional comment explaining decision
7. **Confirm**: Click **Approve and deploy** or **Reject**

## Best Practices

1. ✅ **Always require multiple reviewers** for production
2. ✅ **Enable backup before production deployment** (default)
3. ✅ **Review Terraform plan** before approving
4. ✅ **Test in NPE first** before promoting to production
5. ✅ **Use branch protection** on `main` and `develop` branches
6. ✅ **Rotate GCP service account keys** regularly
7. ✅ **Audit deployment history** periodically

## Branch Protection Rules

Recommended branch protection for `main`:
- ✅ Require pull request reviews (1+ approvals)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Include administrators
- ✅ Restrict who can push to matching branches

Recommended branch protection for `develop`:
- ✅ Require pull request reviews (optional)
- ✅ Require status checks to pass
- ✅ Allow force pushes (for development)

## Troubleshooting

### Deployment stuck waiting for approval
- **Cause**: No reviewers configured for prod environment
- **Fix**: Add required reviewers in Environment settings

### Unable to deploy to production
- **Cause**: Not deploying from `main` branch
- **Fix**: Ensure deployment branch restriction allows `main`

### Auto-approval not working for NPE
- **Cause**: Environment protection rules enabled for NPE
- **Fix**: Remove all protection rules from NPE environment

### GCP authentication fails
- **Cause**: Invalid or expired service account key
- **Fix**: Regenerate service account key and update `GCP_SA_KEY` secret

## Additional Resources

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Actions Approvals](https://docs.github.com/en/actions/managing-workflow-runs/reviewing-deployments)
- [Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
