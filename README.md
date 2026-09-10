# HabotConnect DevOps Engineering Assignment

## Junior Cloud & DevOps Engineer — GCP / Django / React

This repository contains my implementation for the **HabotConnect Junior Cloud & DevOps Engineer hiring project**.

The solution focuses on three core engineering areas:

1. **Secure Infrastructure as Code (IaC)** using Terraform and Google Cloud Platform.
2. **Poka-Yoke CI/CD security and quality gates** using GitHub Actions.
3. **Deterministic onboarding-data validation** using Django REST Framework and a DCYN Yes/No validation library.

The implementation is designed around a **fail-closed, least-privilege and automation-first approach**, where unsafe or invalid changes are prevented from progressing through the pipeline.

---

## 1. Solution Overview

The proposed engineering flow is:

```text
Developer
   │
   ▼
Git Commit / Pull Request
   │
   ▼
GitHub Actions
   │
   ├── Ruff Lint
   ├── Ruff Format Check
   ├── Django System Check
   ├── Django Automated Tests
   ├── Gitleaks Secret Scan
   ├── Terraform Format Check
   ├── Terraform Validate
   └── Checkov IaC Security Scan
   │
   ▼
Fail-Closed Security Gate
   │
   ▼
Approved Infrastructure / Data Pipeline
   │
   ├── GCS D0 Raw Landing
   │
   └── BigQuery D1 Staged Dataset
```

The objective is to make common developer mistakes difficult to introduce by enforcing security and quality controls automatically.

---

## 2. Repository Structure

```text
habotconnect-devops-assignment/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── config/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
│
├── onboarding/
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── dcyn.py
│   ├── migrations/
│   │   └── 0001_initial.py
│   ├── models.py
│   ├── serializers.py
│   ├── tests.py
│   ├── urls.py
│   └── views.py
│
├── docs/
│
├── presentation/
│
├── schema/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── ...
│
├── manage.py
├── requirements.txt
├── pyproject.toml
└── .gitignore
```

---

# 3. Task 1 — Terraform Infrastructure

Terraform is used to define the required GCP infrastructure as code.

## D0 — Raw Landing Layer

The D0 raw landing bucket is configured with:

* Uniform bucket-level access.
* Public access prevention.
* Object versioning.
* Lifecycle management.
* Dedicated access logging.
* Restricted service-account permissions.
* IAM conditions limiting access to the intended resource.

The ingestion service account uses:

```text
roles/storage.objectCreator
```

instead of broad storage administration permissions.

This follows the **principle of least privilege**.

---

## D1 — BigQuery Staged Layer

The D1 BigQuery dataset is configured with:

* Dedicated dataset.
* Customer-managed encryption using Cloud KMS.
* Dedicated analytics service account.
* Dataset-scoped IAM permissions.
* IAM conditions restricting access to the intended dataset.

The analytics identity uses:

```text
roles/bigquery.dataEditor
```

with a resource-level IAM condition.

### Row-Level Security

The assessment form does not provide the authoritative business row/schema fields or the exact RLS predicate required for production use.

Therefore, no business-specific RLS rule has been fabricated.

The Terraform design leaves the D1 layer ready for row-level access policies once the authoritative business schema and access predicate are provided.

---

# 4. Security Architecture

The infrastructure follows several security principles:

### Least Privilege

Dedicated identities are used for ingestion and analytics instead of shared administrative credentials.

### Public Access Prevention

The D0 bucket explicitly prevents public access.

### Uniform Bucket-Level Access

Object ACL-based access is avoided to reduce permission drift.

### Encryption

The D1 BigQuery dataset uses a dedicated Cloud KMS key.

### Key Rotation

The KMS key has a defined rotation period.

### Prevent Accidental Key Destruction

The KMS key uses Terraform lifecycle protection with:

```text
prevent_destroy = true
```

### IAM Conditions

Permissions are constrained to the intended GCP resources instead of granting unnecessarily broad access.

---

# 5. Task 2 — Poka-Yoke CI/CD Security Gate

The GitHub Actions workflow implements a **fail-closed security gate**.

The pipeline performs the following checks:

```text
Source Checkout
      │
      ▼
Python Dependencies
      │
      ▼
Ruff Lint
      │
      ▼
Ruff Format Check
      │
      ▼
Django System Check
      │
      ▼
Django Tests
      │
      ▼
Terraform Format Check
      │
      ▼
Terraform Validate
      │
      ▼
Gitleaks Secret Scan
      │
      ▼
Checkov IaC Security Scan
      │
      ▼
Security Gate Passed
```

If any required check fails, the workflow exits with a failure status and subsequent pipeline progression is stopped.

This prevents an insecure or invalid change from silently progressing.

---

## Secret Detection

Gitleaks is used to detect hard-coded credentials and API secrets in repository content.

Example failure condition:

```text
Hard-coded API credential detected
        ↓
Gitleaks fails
        ↓
GitHub Actions job fails
        ↓
Build progression stops
```

This directly addresses the assignment scenario involving raw API credentials committed into source code.

---

## Infrastructure Security Scanning

Checkov scans the Terraform configuration for infrastructure security issues.

The workflow uses:

```yaml
soft_fail: false
```

This ensures that security findings are treated as blocking failures rather than warnings.

---

# 6. Task 3 — Deterministic Data Validation

The onboarding component uses Django REST Framework.

Incoming Yes/No-style values are processed through the DCYN validation library.

The purpose is to eliminate manual interpretation of incoming data.

Example:

```text
"Yes"   → Yes → True
"Y"     → Yes → True
"true"  → Yes → True
"1"     → Yes → True

"No"    → No  → False
"N"     → No  → False
"false" → No  → False
"0"     → No  → False
```

Unsupported values are rejected instead of being guessed.

The serializer also validates:

* Required student name.
* Student name length.
* Email format.
* Email length.
* Whitespace normalization.
* Lowercase email normalization.
* Deterministic boolean conversion.

---

# 7. Data Quality Flow

```text
Incoming JSON
      │
      ▼
Django REST Framework Serializer
      │
      ├── Required-field validation
      ├── String normalization
      ├── Length validation
      ├── Email validation
      └── Yes/No normalization
      │
      ▼
DCYN Validation Library
      │
      ├── Valid → Canonical True/False
      │
      └── Invalid → Reject Request
      │
      ▼
Validated Django Model
```

The implementation is intentionally deterministic so that the same input produces the same validated result.

---

# 8. Testing & Validation Evidence

The implementation was validated locally and through GitHub Actions.

### Python

```text
Ruff lint             → PASSED
Ruff formatting       → PASSED
Django system check   → PASSED
Django automated test → PASSED
```

### Terraform

```text
Terraform fmt         → PASSED
Terraform validate    → PASSED
```

### CI/CD

```text
GitHub Actions
Poka-Yoke Security Gate → GREEN
```

The CI pipeline therefore validates both application code quality and infrastructure security before allowing the workflow to progress.

---

# 9. Technology Stack

| Area                   | Technology            |
| ---------------------- | --------------------- |
| Application            | Python                |
| Backend Framework      | Django                |
| API Framework          | Django REST Framework |
| Infrastructure as Code | Terraform             |
| Cloud Platform         | Google Cloud Platform |
| Object Storage         | Google Cloud Storage  |
| Data Warehouse         | BigQuery              |
| Key Management         | Cloud KMS             |
| CI/CD                  | GitHub Actions        |
| Python Quality         | Ruff                  |
| Secret Scanning        | Gitleaks              |
| IaC Security           | Checkov               |
| Version Control        | Git / GitHub          |

---

# 10. Local Setup

## Clone the repository

```bash
git clone https://github.com/student-ishikakamble/habotconnect-devops-assignment.git
cd habotconnect-devops-assignment
```

## Create a virtual environment

Windows:

```cmd
python -m venv venv
venv\Scripts\activate.bat
```

## Install dependencies

```cmd
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## Run Django checks

```cmd
python manage.py check
```

## Run tests

```cmd
python manage.py test
```

## Run Ruff

```cmd
python -m ruff check onboarding
python -m ruff format --check onboarding
```

---

# 11. Terraform Validation

From the repository root:

```cmd
terraform -chdir=terraform fmt -check -recursive
```

Then:

```cmd
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

Terraform validation confirms that the infrastructure configuration is syntactically and structurally valid.

---

# 12. GCP Deployment Note

The Terraform configuration is prepared for deployment to Google Cloud Platform.

For this assessment, the personal GCP project used for validation had **billing disabled**.

Therefore:

```text
Terraform configuration → Validated
GCP resources           → Not applied
Paid cloud resources    → Not created
```

This was an intentional decision to avoid unexpected cloud charges while still validating the infrastructure code, security controls and CI/CD implementation.

---

# 13. Important Assumption

The supplied assessment form does not include the complete authoritative incoming JSON payload or the exact production validation limits/business RLS predicate.

Therefore, the onboarding field mapping currently implemented is explicitly treated as an **implementation assumption**, rather than presented as an authoritative production schema.

The schema mapping spreadsheet included with the submission documents these assumptions.

Once the authoritative payload and business rules are provided, the serializer, model, schema mapping and RLS predicates can be updated without changing the overall architecture.

---

# 14. Engineering Principles

The implementation follows these principles:

* **Fail closed** rather than warn and continue.
* **Least privilege** rather than broad permissions.
* **Automation over manual verification.**
* **Deterministic validation** rather than human interpretation.
* **Security checks early in the development lifecycle.**
* **Infrastructure as code** for repeatability.
* **Explicit assumptions** instead of inventing missing business requirements.
* **Mistake-proofing (Poka-Yoke)** to prevent common developer errors.

---

# 15. Submission Artifacts

The submission contains:

### Source Code

GitHub repository:

https://github.com/student-ishikakamble/habotconnect-devops-assignment

### Architecture Presentation

`HabotConnect_DevOps_Assignment_Presentation.pptx`

### Schema Mapping

`HabotConnect_Schema_Mapping.xlsx`

The presentation is limited to 15 slides as required by the assessment.

---

## Author

**Ishika Kamble**

Junior Cloud & DevOps Engineer Candidate

GitHub:
https://github.com/student-ishikakamble

LinkedIn:
https://www.linkedin.com/in/ishika-kamble-b794b0355

---

## Final Status

```text
Application Code       ✓
Django Validation      ✓
DCYN Logic             ✓
Terraform IaC          ✓
IAM Least Privilege    ✓
Poka-Yoke CI/CD        ✓
Secret Scanning        ✓
IaC Security Scanning  ✓
Automated Testing      ✓
Architecture Slides    ✓
Schema Mapping         ✓
GCP Deployment         Validation-ready
```

**Status: Assignment implementation completed and validated locally / through CI.**
