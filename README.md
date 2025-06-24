# Seenme App - Cloud Run Deployment

A social media application built with Go microservices backend, Flutter frontend, deployed on Google Cloud Run.

## Architecture

- **Backend**: Go microservices (auth-service, user-service, post-service)
- **Database**: PostgreSQL on Cloud SQL
- **Storage**: Google Cloud Storage for images
- **Deployment**: Google Cloud Run (instead of Kubernetes)
- **Frontend**: Flutter (to be implemented)

## Features

### Must Have (MVP)
- ✅ User registration and login with email/password
- ✅ Profile image upload during registration for ML recognition
- ✅ Image post uploads (no captions)
- ✅ View own posts in reverse chronological order
- ✅ Cloud Storage integration
- ✅ JWT authentication
- ✅ Cloud Run deployment

### Should Have
- 🔄 View posts by other users
- 🔄 Basic user profile page

### Could Have
- 🔄 Public feed with latest posts
- 🔄 Pagination/lazy loading

## Services

### Auth Service (Port 8081)
- User registration and login
- JWT token generation and validation
- Password hashing with bcrypt

### User Service (Port 8080)
- User profile management
- Profile image uploads
- User data retrieval

### Post Service (Port 8082)
- Image post uploads
- Post retrieval and feeds
- Image processing and storage

## Prerequisites

1. **Google Cloud Platform Account**
   - Create a GCP project
   - Enable billing

2. **Required Tools**
   ```bash
   # Install Google Cloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Install Terraform
   # https://learn.hashicorp.com/tutorials/terraform/install-cli
   
   # Install Go (for local development)
   # https://golang.org/doc/install
   ```

3. **Authentication**
   ```bash
   # Authenticate with Google Cloud
   gcloud auth login
   
   # Set up application default credentials
   gcloud auth application-default login
   ```

## Quick Deployment

1. **Clone and Setup**
   ```bash
   git clone <your-repo>
   cd instagram-clone
   chmod +x deploy.sh
   ```

2. **Deploy to Cloud Run**
   ```bash
   ./deploy.sh YOUR_GCP_PROJECT_ID us-central1 dev
   ```

   This script will:
   - Enable required GCP APIs
   - Deploy infrastructure with Terraform
   - Build and deploy all microservices to Cloud Run
   - Output service URLs

## Manual Deployment

### 1. Infrastructure Setup

```bash
cd infrastructure
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details
terraform plan
terraform apply
```

### 2. Build and Deploy Services

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"

# Build and deploy auth service
gcloud builds submit --tag gcr.io/$PROJECT_ID/auth-service:latest backend/auth-service/
gcloud run deploy auth-service \
    --image gcr.io/$PROJECT_ID/auth-service:latest \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated

# Repeat for other services...
```

## API Endpoints

### Auth Service
```
POST /register - User registration
POST /login - User login
GET /verify - Token verification
GET /health - Health check
```

### User Service
```
GET /users/{id} - Get user profile
PUT /users/{id} - Update user profile
POST /users/{id}/profile-images - Upload profile images
GET /health - Health check
```

### Post Service
```
POST /posts - Create new post
GET /posts/user/{userId} - Get user's posts
GET /posts/feed - Get public feed
GET /health - Health check
```

## Environment Variables

The services use these environment variables (automatically set by Terraform):

- `PORT` - Service port
- `DB_HOST` - Database host (Cloud SQL socket)
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `STORAGE_BUCKET` - Cloud Storage bucket name
- `PROJECT_ID` - GCP project ID
- `ENVIRONMENT` - Environment (dev/staging/prod)

### Local Development

### 1. Database Setup
```bash
# Start local PostgreSQL (using Docker)
docker run --name postgres-dev -e POSTGRES_PASSWORD=password -e POSTGRES_DB=seenme_app -p 5432:5432 -d postgres:15

# Set local environment variables
export DB_HOST=localhost:5432
export DB_NAME=seenme_app
export DB_USER=postgres
export DB_PASSWORD=password
export STORAGE_BUCKET=your-bucket-name
export PROJECT_ID=your-project-id
```

### 2. Run Services
```bash
# Terminal 1 - Auth Service
cd backend/auth-service
go mod tidy
go run main.go

# Terminal 2 - User Service
cd backend/user-service
go mod tidy
go run main.go

# Terminal 3 - Post Service
cd backend/post-service
go mod tidy
go run main.go
```

## Monitoring and Logs

```bash
# View logs for a specific service
gcloud logs read --project=YOUR_PROJECT_ID --filter='resource.type=cloud_run_revision AND resource.labels.service_name=auth-service'

# Monitor service metrics
gcloud run services describe auth-service --region=us-central1

# Check service status
gcloud run services list --region=us-central1
```

## Security Considerations

- JWT secret should be changed in production
- Database password should be properly secured
- Consider implementing rate limiting
- Use HTTPS for all endpoints
- Implement proper CORS policies

## Scaling

Cloud Run automatically scales based on traffic:
- Scales to zero when no requests
- Auto-scales up to configured max instances (default: 10)
- CPU and memory can be adjusted per service

## Cost Optimization

- Cloud Run pricing is per-request and CPU/memory usage
- Services scale to zero when not in use
- Use Cloud SQL's smallest tier for development
- Monitor storage costs for uploaded images

## Next Steps

1. Implement user-service and post-service
2. Add Flutter frontend
3. Implement ML-based user recognition
4. Add image processing and optimization
5. Implement caching with Redis
6. Add monitoring and alerting
7. Set up CI/CD pipeline

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify Cloud SQL instance is running
   - Check connection string format
   - Ensure service account has Cloud SQL Client role

2. **Storage Upload Errors**
   - Verify bucket exists and permissions
   - Check service account has Storage Admin role

3. **Service Build Failures**
   - Check Dockerfile paths
   - Verify Go modules are properly configured

4. **Authentication Issues**
   - Verify JWT secret is set
   - Check token format and expiration

For more help, check the Cloud Run documentation: https://cloud.google.com/run/docs
