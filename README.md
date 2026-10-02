# Argo CI/CD — Terraform + OPA + EKS

A hands-on DevOps/GitOps project for building AWS infrastructure with Terraform, enforcing Infrastructure Policy as Code with Open Policy Agent (OPA), and eventually implementing CI/CD and GitOps deployment using GitHub Actions, Helm, and Argo CD.

---

## Project Goal

The final project will demonstrate an end-to-end DevOps workflow:

```text
Developer
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +--> Test
    +--> Docker Build
    +--> Push Image to GHCR
    |
    +--> Terraform Plan
    +--> OPA Policy Check
    +--> Manual Approval
    +--> Terraform Apply
    |
    v
AWS EKS
    |
    v
Argo CD
    |
    v
Applications
```

The project will eventually contain:

- AWS VPC
- AWS EKS
- Terraform
- OPA / Rego
- GitHub Actions
- Manual approval
- Docker
- GitHub Container Registry (GHCR)
- Spring Boot application
- Python application
- Helm
- Argo CD
- Kubernetes
- GitOps deployment

---

# 1. Repository Setup

## Create Project Directory

```bash
cd ~/OneDrive\ -\ IBM/Desktop/devops\ pathnex\ notes

mkdir argo-ci-cd

cd argo-ci-cd
```

## Initialize Git

```bash
git init
```

Rename the default branch to `main`:

```bash
git branch -M main
```

Verify:

```bash
git branch
```

Expected:

```text
* main
```

---

# 2. GitHub Repository

GitHub repository:

**argo-ci-cd-terraform-opa-eks**

Repository:

https://github.com/pravinmoreone-ux/argo-ci-cd-terraform-opa-eks

Connect the local repository:

```bash
git remote add origin https://github.com/pravinmoreone-ux/argo-ci-cd-terraform-opa-eks.git
```

Verify:

```bash
git remote -v
```

---

# 3. Terraform Project Structure

Current Terraform structure:

```text
terraform/
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── terraform.tfvars.example
├── vpc.tf
├── eks.tf
├── eks_nodes.tf
├── outputs.tf
└── policies/
    └── terraform.rego
```

---

# 4. AWS Provider

Terraform is configured to use AWS.

`providers.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "devops"
}
```

The AWS CLI profile used for this lab is:

```text
devops
```

Verify available profiles:

```bash
aws configure list-profiles
```

Verify AWS identity:

```bash
aws sts get-caller-identity --profile devops
```

---

# 5. Terraform Variables

The project uses the following variables:

```text
aws_region
environment
node_instance_type
```

Current values:

```hcl
aws_region         = "ap-south-1"
environment        = "dev"
node_instance_type = "t3.small"
```

---

# 6. Terraform Variable Validation

Terraform variable validation was added as the first layer of infrastructure protection.

Allowed EKS worker node types:

```text
t3.small
t3.medium
```

Example validation:

```hcl
validation {
  condition = contains([
    "t3.small",
    "t3.medium"
  ], var.node_instance_type)

  error_message = "Only t3.small and t3.medium are allowed for EKS worker nodes."
}
```

An invalid value such as:

```hcl
node_instance_type = "m5.large"
```

was tested.

Terraform rejected it with:

```text
Error: Invalid value for variable

Only t3.small and t3.medium are allowed for EKS worker nodes.
```

This demonstrates Terraform's built-in variable validation.

---

# 7. AWS VPC

The Terraform configuration creates:

```text
VPC
10.30.0.0/16
```

### Public Subnets

```text
10.30.1.0/24
10.30.2.0/24
```

### Private Subnets

```text
10.30.11.0/24
10.30.12.0/24
```

### Additional Components

- Internet Gateway
- Public Route Table
- Public Route Table Associations
- DNS Support
- DNS Hostnames

Resources use tags such as:

```text
Environment = dev
Project     = argo-ci-cd
```

---

# 8. AWS EKS

The project creates an EKS cluster:

```text
argo-ci-cd-eks
```

AWS region:

```text
ap-south-1
```

The EKS control plane uses the configured VPC subnets.

An IAM role is created for the EKS cluster.

Attached policy:

```text
AmazonEKSClusterPolicy
```

---

# 9. EKS Worker Node Group

Worker node group:

```text
argo-ci-cd-nodes
```

Current configuration:

```text
Instance Type: t3.small
Capacity Type: ON_DEMAND

Desired Size: 2
Minimum Size: 1
Maximum Size: 3

Disk Size: 20 GB
```

Worker-node IAM policies:

```text
AmazonEKSWorkerNodePolicy
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly
```

---

# 10. Terraform Validation

Format Terraform:

```bash
terraform fmt
```

Validate Terraform:

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# 11. Terraform Plan

Create a Terraform plan:

```bash
terraform plan
```

The plan successfully showed:

```text
Plan: 17 to add, 0 to change, 0 to destroy.
```

The plan contains the infrastructure required for:

- VPC
- Subnets
- Internet Gateway
- Route Table
- IAM Roles
- IAM Policies
- EKS Cluster
- EKS Node Group

---

# 12. Save Terraform Plan

Instead of immediately running `terraform apply`, the plan is saved:

```bash
terraform plan -out=tfplan
```

Convert the Terraform plan to JSON:

```bash
terraform show -json tfplan > tfplan.json
```

This creates:

```text
tfplan
tfplan.json
```

The JSON plan will later be used as input for OPA.

---

# 13. Terraform Plan and OPA

The Policy as Code flow is:

```text
Terraform Code
      |
      v
terraform plan
      |
      v
tfplan
      |
      v
tfplan.json
      |
      v
OPA
      |
      v
Rego Policy
      |
      v
PASS / FAIL
```

### Important

`tfplan` is the saved Terraform plan.

`tfplan.json` is the JSON representation of the Terraform plan.

OPA evaluates the JSON plan against Rego policies.

---

# 14. Install Open Policy Agent

OPA was installed for Windows AMD64.

Download:

```bash
curl -L -o opa.exe https://openpolicyagent.org/downloads/latest/opa_windows_amd64.exe
```

Verify:

```bash
./opa.exe version
```

OPA was successfully installed.

Current version used during this lab:

```text
Version: 1.21.1
Platform: windows/amd64
Rego Version: v1
```

---

# 15. First OPA Policy

Policy location:

```text
terraform/policies/terraform.rego
```

Current policy:

```rego
package terraform

deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_eks_node_group"

    some instance_type in resource.change.after.instance_types

    not instance_type in {"t3.small", "t3.medium"}

    msg := sprintf(
        "EKS node group %s uses prohibited instance type: %s",
        [resource.name, instance_type]
    )
}
```

---

# 16. What the OPA Policy Does

The policy examines Terraform plan changes:

```text
input.resource_changes
```

It searches for:

```text
aws_eks_node_group
```

Then checks the configured worker node instance type.

Allowed:

```text
t3.small
t3.medium
```

Not allowed:

```text
Other instance types
```

If an invalid instance type is detected, OPA generates a policy violation message.

---

# 17. Run OPA

Run:

```bash
./opa.exe eval \
  --data policies/terraform.rego \
  --input tfplan.json \
  "data.terraform.deny"
```

For the current valid plan using:

```text
t3.small
```

OPA returned:

```json
"value": []
```

An empty violation list means:

```text
OPA Policy Check
       |
       v
     PASS
```

---

# 18. Important Lesson — Stale Plan

During testing, `m5.large` was placed in:

```text
terraform.tfvars
```

Terraform correctly rejected it during variable validation.

However, because Terraform did not successfully generate a new plan, the existing `tfplan.json` still represented the previous successful plan.

Therefore running OPA against that old JSON returned:

```json
"value": []
```

This demonstrated an important CI/CD lesson:

> A failed Terraform plan must stop the pipeline. Do not continue to OPA using an old plan artifact.

Correct pipeline behavior:

```text
terraform plan
      |
      +---- FAIL ---> STOP
      |
      +---- PASS
             |
             v
          tfplan
             |
             v
        tfplan.json
             |
             v
             OPA
```

---

# 19. Git Ignore

Generated and potentially sensitive files are excluded from Git.

Important exclusions:

```text
.terraform/
*.tfstate
*.tfstate.*
tfplan
tfplan.json
opa.exe
*.tfvars
```

The example variable file is allowed:

```text
terraform.tfvars.example
```

This allows the repository to contain the configuration template without committing the local Terraform variables file.

---

# 20. Git Commit

Initial project commit:

```bash
git add .

git commit -m "Initial Terraform OPA EKS setup"
```

Initial commit:

```text
a0699d0 Initial Terraform OPA EKS setup
```

---

# 21. Push to GitHub

Push the `main` branch:

```bash
git push -u origin main
```

Verify:

```bash
git status
```

Expected:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

# 22. Current Architecture

The infrastructure and policy workflow currently looks like:

```text
Developer
    |
    v
Git
    |
    v
Terraform
    |
    +--> VPC
    |
    +--> EKS
    |
    +--> Node Group
    |
    v
Terraform Plan
    |
    v
tfplan
    |
    v
tfplan.json
    |
    v
OPA / Rego
    |
    v
PASS / FAIL
```

---

# 23. Planned CI/CD Architecture

The next stage is GitHub Actions.

```text
Developer
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +--> Terraform fmt
    |
    +--> Terraform validate
    |
    +--> Terraform plan
    |
    +--> Generate tfplan.json
    |
    +--> OPA Policy Check
    |
    +--> Manual Approval
    |
    +--> Terraform Apply
    |
    v
AWS EKS
```

---

# 24. Planned Application CI/CD

After the infrastructure pipeline, applications will be added.

### Spring Boot

```text
apps/springboot/
```

### Python

```text
apps/python/
```

Both applications will eventually be:

```text
Source Code
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    v
Tests
    |
    v
Docker Build
    |
    v
GHCR
```

---

# 25. Planned Kubernetes / GitOps Architecture

The application deployment stage will use:

```text
Docker
   |
   v
GHCR
   |
   v
Helm
   |
   v
Git
   |
   v
Argo CD
   |
   v
EKS
```

Planned components:

```text
helm/
├── springboot/
└── python/

argocd/
```

---

# 26. Project Roadmap

## Phase 1 — Repository

- [x] Create Git repository
- [x] Create GitHub repository
- [x] Configure `main` branch
- [x] Push initial project

## Phase 2 — Terraform

- [x] AWS provider
- [x] VPC
- [x] Subnets
- [x] Internet Gateway
- [x] Route table
- [x] IAM roles
- [x] EKS cluster
- [x] EKS node group
- [x] Terraform validation
- [x] Terraform plan

## Phase 3 — Policy as Code

- [x] Install OPA
- [x] Create Rego policy
- [x] Generate `tfplan.json`
- [x] Evaluate Terraform plan with OPA
- [x] Verify OPA PASS
- [ ] Add additional OPA policies

## Phase 4 — Terraform CI/CD

- [ ] GitHub Actions
- [ ] Terraform fmt
- [ ] Terraform validate
- [ ] Terraform plan
- [ ] OPA policy gate
- [ ] Manual approval
- [ ] Terraform apply
- [ ] AWS authentication using GitHub Actions OIDC

## Phase 5 — Applications

- [ ] Spring Boot application
- [ ] Python application
- [ ] Application tests
- [ ] Dockerfiles
- [ ] Docker image builds
- [ ] GHCR

## Phase 6 — Kubernetes

- [ ] Helm chart for Spring Boot
- [ ] Helm chart for Python
- [ ] Kubernetes deployments
- [ ] Kubernetes services
- [ ] ConfigMaps
- [ ] Secrets

## Phase 7 — Argo CD

- [ ] Install Argo CD
- [ ] Argo CD Application
- [ ] GitOps deployment
- [ ] Automatic synchronization
- [ ] Rollback
- [ ] Sync Waves and Hooks
- [ ] App of Apps
- [ ] Environment overlays
- [ ] RBAC
- [ ] Secrets management

## Phase 8 — Monitoring

- [ ] Infrastructure monitoring
- [ ] Kubernetes monitoring
- [ ] Application monitoring
- [ ] Logs
- [ ] Alerts

---

# 27. Current Status

Current completed stage:

```text
GitHub Repository
       |
       v
Terraform
       |
       v
AWS VPC + EKS Configuration
       |
       v
Terraform Plan
       |
       v
tfplan.json
       |
       v
OPA Policy
       |
       v
PASS
```

The infrastructure has **not yet been applied** through the CI/CD pipeline.

The next major milestone is:

```text
GitHub Actions
      |
      v
Terraform + OPA
      |
      v
Manual Approval
      |
      v
Terraform Apply
```

---

## Repository

GitHub:

https://github.com/pravinmoreone-ux/argo-ci-cd-terraform-opa-eks