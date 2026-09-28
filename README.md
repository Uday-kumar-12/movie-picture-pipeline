# Movie Picture Pipeline

A production-grade, end-to-end DevOps CI/CD pipeline and web application built from scratch.

---

## Architecture Overview

```
                      +-----------------------------+
                      |       GitHub Actions        |
                      |  (CI: Lint/Test/Build)      |
                      |  (CD: Push to ECR & Deploy) |
                      +--------------+--------------+
                                     |
                +--------------------+--------------------+
                |                                         |
                v                                         v
     +---------------------+                   +---------------------+
     | Amazon ECR Frontend |                   | Amazon ECR Backend  |
     +----------+----------+                   +----------+----------+
                |                                         |
                +--------------------+--------------------+
                                     |
                                     v
                       +---------------------------+
                       |    Amazon EKS Cluster     |
                       |                           |
                       |  +---------------------+  |
                       |  |  frontend-service   |  | (LoadBalancer)
                       |  |   (Port 3000 / 80)  |  |
                       |  +----------+----------+  |
                       |             |             |
                       |             v             |
                       |  +---------------------+  |
                       |  | frontend-deployment |  | (React / Nginx)
                       |  +---------------------+  |
                       |                           |
                       |  +---------------------+  |
                       |  |   backend-service   |  | (LoadBalancer)
                       |  |     (Port 5000)     |  |
                       |  +----------+----------+  |
                       |             |             |
                       |             v             |
                       |  +---------------------+  |
                       |  | backend-deployment  |  | (Flask API)
                       |  +---------------------+  |
                       +---------------------------+
```

---

## Project Structure

```
movie-picture-pipeline/
├── frontend/
│   ├── src/
│   │   ├── App.css
│   │   ├── App.js
│   │   ├── App.test.js
│   │   ├── index.css
│   │   ├── index.js
│   │   └── setupTests.js
│   ├── public/
│   │   ├── index.html
│   │   └── manifest.json
│   ├── nginx.conf
│   ├── package.json
│   ├── package-lock.json
│   ├── .nvmrc
│   ├── .eslintrc.js
│   ├── .prettierrc
│   ├── Dockerfile
│   └── k8s/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
│
├── backend/
│   ├── movies/
│   │   ├── __init__.py
│   │   └── app.py
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_app.py
│   ├── .flake8
│   ├── Pipfile
│   ├── Pipfile.lock
│   ├── Dockerfile
│   └── k8s/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
│
├── setup/
│   ├── terraform/
│   │   ├── ecr.tf
│   │   ├── eks.tf
│   │   ├── iam.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   ├── versions.tf
│   │   └── vpc.tf
│   └── init.sh
│
├── .github/
│   ├── actions/
│   │   └── setup-eks-kubectl/
│   │       └── action.yaml
│   └── workflows/
│       ├── frontend-ci.yaml
│       ├── frontend-cd.yaml
│       ├── backend-ci.yaml
│       └── backend-cd.yaml
│
├── .gitignore
├── LICENSE.md
└── README.md
```

---

## Application Functionality

### Backend API
- Built with **Python 3.10** and **Flask**.
- Exposes `GET /movies` returning:
```json
{
  "movies": [
    {
      "id": "123",
      "title": "Top Gun: Maverick"
    },
    {
      "id": "456",
      "title": "Sonic the Hedgehog"
    },
    {
      "id": "789",
      "title": "A Quiet Place"
    }
  ]
}
```
- Includes health probe `GET /health`.
- CORS-enabled for web browser integration.
- Tests cover:
  1. HTTP 200 response
  2. JSON content-type
  3. Valid movie payload verification

### Frontend Web App
- Built with **React 18** and **Node.js 18.14**.
- Displays the heading **Movie List** and renders the movies received dynamically from the backend API.
- Reads `REACT_APP_MOVIE_API_URL` at build/runtime.
- Tests cover:
  - App render without crashing
  - Movie List heading presence
  - Movies rendered dynamically from the API
  - Error state handling

---

## Local Development & Testing

### Backend (Python & Pipenv)
```bash
cd backend

# Install dependencies (including dev packages: pytest, flake8)
pipenv install --dev

# Run linting (flake8)
pipenv run lint

# Run automated tests (pytest)
pipenv run test
```

### Frontend (Node.js & React)
```bash
cd frontend

# Install exact dependencies
npm ci

# Run linting (ESLint + Prettier compatibility)
npm run lint

# Run automated tests
CI=true npm test -- --watchAll=false

# Run production build
npm run build
```

---

## Docker Builds

### Frontend Docker Build
Accepts `REACT_APP_MOVIE_API_URL` build argument:
```bash
docker build \
  --build-arg REACT_APP_MOVIE_API_URL=http://localhost:5000 \
  -t mp-frontend:test \
  ./frontend
```

Run frontend locally:
```bash
docker run -d -p 3000:3000 --name mp-frontend-app mp-frontend:test
```

### Backend Docker Build
```bash
docker build -t mp-backend:test ./backend
```

Run backend locally:
```bash
docker run -d -p 5000:5000 --name mp-backend-app mp-backend:test
```

---

## CI/CD Automation (GitHub Actions)

### 1. Frontend Continuous Integration (`.github/workflows/frontend-ci.yaml`)
- **Trigger**: Pull Requests to `main`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint`: Checks out code, sets up Node.js, caches npm dependencies (`actions/cache@v4`), installs dependencies (`npm ci`), and runs `npm run lint`.
  - `test`: Runs in parallel with `lint`. Checks out code, sets up Node.js, caches npm dependencies (`actions/cache@v4`), installs dependencies (`npm ci`), and runs `npm run test`.
  - `build`: Requires `[lint, test]` (will NOT run if either fails). Runs tests, builds Docker image using `--build-arg REACT_APP_MOVIE_API_URL`, and posts a status comment on the Pull Request.

### 2. Backend Continuous Integration (`.github/workflows/backend-ci.yaml`)
- **Trigger**: Pull Requests to `main`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint`: Caches Pipenv virtualenvs (`actions/cache@v4`) and runs `pipenv run lint` (flake8).
  - `test`: Runs in parallel with `lint`. Caches Pipenv virtualenvs and runs `pipenv run test` (pytest).
  - `build`: Requires `[lint, test]`. Builds backend Docker image and posts a status comment on the Pull Request.

### 3. Frontend Continuous Deployment (`.github/workflows/frontend-cd.yaml`)
- **Trigger**: Push/merge to `main`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint` & `test`: Run in parallel with dependency caching.
  - `build-and-deploy`: Requires `[lint, test]`. Uses our custom composite action (`.github/actions/setup-eks-kubectl`), dynamically resolves the active EKS backend LoadBalancer endpoint, logs in to ECR via `aws-actions/amazon-ecr-login@v2`, builds Docker image with `--build-arg REACT_APP_MOVIE_API_URL`, pushes to Amazon ECR, and deploys to EKS using Kustomize and `kubectl`:
    ```bash
    cd frontend/k8s
    kustomize edit set image frontend=<ECR_REPO>:${{ github.sha }}
    kustomize build | kubectl apply -f -
    ```

### 4. Backend Continuous Deployment (`.github/workflows/backend-cd.yaml`)
- **Trigger**: Push/merge to `main`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint` & `test`: Run in parallel with dependency caching.
  - `build-and-deploy`: Requires `[lint, test]`. Logs in to ECR via `aws-actions/amazon-ecr-login@v2`, builds Docker image, tags with `${{ github.sha }}`, pushes to Amazon ECR, configures EKS via `.github/actions/setup-eks-kubectl`, and deploys via Kustomize and `kubectl` to EKS:
    ```bash
    cd backend/k8s
    kustomize edit set image backend=<ECR_REPO>:${{ github.sha }}
    kustomize build | kubectl apply -f -
    ```

---

## AWS Infrastructure & Terraform

Infrastructure is defined in `setup/terraform/` using HashiCorp Terraform:
- **VPC & Networking**: Multi-AZ VPC with public and private subnets, Internet Gateway, and NAT Gateway.
- **Amazon ECR**: Repositories for `movie-picture-frontend` and `movie-picture-backend` with automated scan-on-push and lifecycle expiration policies.
- **Amazon EKS**: EKS Cluster version 1.32 and managed worker node groups with auto-scaling.
- **IAM Security**: Dedicated IAM user and policy for GitHub Actions CI/CD with least-privilege permissions without hard-coded account IDs.

### Outputs:
- `aws_region`: Configured AWS region.
- `eks_cluster_name`: Name of the EKS cluster.
- `frontend_ecr_repository_url`: ECR URL for frontend image.
- `backend_ecr_repository_url`: ECR URL for backend image.
- `github_actions_access_key_id`: Access Key ID for CI/CD secrets.
- `github_actions_secret_access_key`: Secret Access Key for CI/CD secrets.

---

## Required GitHub Secrets

Configure these secrets in GitHub repository Settings -> Secrets and variables -> Actions:

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM deployment access key ID |
| `AWS_SECRET_ACCESS_KEY` | IAM deployment secret access key |
| `AWS_REGION` | AWS region (e.g. `us-east-1`) |
| `EKS_CLUSTER_NAME` | EKS Cluster name (`movie-picture-eks`) |
| `ECR_FRONTEND_REPOSITORY` | Full frontend ECR URL |
| `ECR_BACKEND_REPOSITORY` | Full backend ECR URL |
