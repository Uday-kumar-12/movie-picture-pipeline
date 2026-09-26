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
│   └── workflows/
│       ├── frontend-ci.yml
│       ├── frontend-cd.yml
│       ├── backend-ci.yml
│       └── backend-cd.yml
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

### 1. Frontend CI (`.github/workflows/frontend-ci.yml`)
- **Trigger**: Pull Requests to `main` modifying `frontend/**`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint`: Runs ESLint on frontend code.
  - `test`: Runs Jest tests via `CI=true npm test -- --watchAll=false`.
  - `build`: Requires `[lint, test]` (will NOT run if either fails). Builds Docker image using `--build-arg REACT_APP_MOVIE_API_URL`.

### 2. Backend CI (`.github/workflows/backend-ci.yml`)
- **Trigger**: Pull Requests to `main` modifying `backend/**`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint`: Runs `pipenv run lint` (flake8).
  - `test`: Runs `pipenv run test` (pytest).
  - `build`: Requires `[lint, test]`. Builds backend Docker image.

### 3. Frontend CD (`.github/workflows/frontend-cd.yml`)
- **Trigger**: Push to `main` modifying `frontend/**`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint` & `test`: Run independently.
  - `build`: Requires `[lint, test]`. Dynamically resolves the active EKS backend LoadBalancer endpoint, injects it into `--build-arg REACT_APP_MOVIE_API_URL`, builds and tags image with `${{ github.sha }}`, and pushes to Amazon ECR.
  - `deploy`: Requires `[build]`. Uses Kustomize to update the image tag with Git SHA and deploys to EKS:
    ```bash
    cd frontend/k8s
    kustomize edit set image frontend=<ECR_REPO>:${{ github.sha }}
    kustomize build | kubectl apply -f -
    ```

### 4. Backend CD (`.github/workflows/backend-cd.yml`)
- **Trigger**: Push to `main` modifying `backend/**`, or manual `workflow_dispatch`.
- **Jobs**:
  - `lint` & `test`: Run independently.
  - `build`: Requires `[lint, test]`. Builds Docker image, tags with `${{ github.sha }}`, and pushes to Amazon ECR.
  - `deploy`: Requires `[build]`. Deploys via Kustomize to EKS:
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
- **Amazon EKS**: EKS Cluster version 1.29 and managed worker node groups with auto-scaling.
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
