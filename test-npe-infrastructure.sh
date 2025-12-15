#!/bin/bash
# NPE Infrastructure Testing Script (Bash version)
# Tests VPC, Cloud SQL, Storage, IAM, and Cloud Run connectivity
# Usage: ./test-npe-infrastructure.sh

set -e

PROJECT_ID="project-07a61357-b791-4255-a9e"
REGION="europe-west2"
ENVIRONMENT="npe"

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}========================================================${NC}"
    echo -e "${CYAN}TEST: $1${NC}"
    echo -e "${CYAN}========================================================${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${CYAN}  $1${NC}"
}

test_command() {
    local cmd=$1
    local description=$2
    
    print_info "Testing: $description"
    if eval "$cmd" > /dev/null 2>&1; then
        print_success "$description"
    else
        print_error "$description failed"
    fi
}

echo -e "\n${CYAN}Fincore NPE Infrastructure Test Suite${NC}"
echo -e "${CYAN}Project: $PROJECT_ID | Region: $REGION${NC}"

# Test 1: VPC Network
print_header "VPC Network Configuration"

test_command \
    "gcloud compute networks describe fincore-$ENVIRONMENT-vpc --project=$PROJECT_ID" \
    "Verify VPC network exists"

test_command \
    "gcloud compute networks subnets list --network=fincore-$ENVIRONMENT-vpc --project=$PROJECT_ID" \
    "List VPC subnets"

test_command \
    "gcloud compute firewall-rules list --filter=network:fincore-$ENVIRONMENT-vpc --project=$PROJECT_ID" \
    "List firewall rules"

test_command \
    "gcloud compute vpc-access connectors describe npe-connector --region=$REGION --project=$PROJECT_ID" \
    "Verify Serverless VPC Connector"

# Test 2: Cloud SQL
print_header "Cloud SQL Database"

test_command \
    "gcloud sql instances describe fincore-$ENVIRONMENT-db --project=$PROJECT_ID" \
    "Describe Cloud SQL instance"

test_command \
    "gcloud sql databases list --instance=fincore-$ENVIRONMENT-db --project=$PROJECT_ID" \
    "List databases"

test_command \
    "gcloud sql users list --instance=fincore-$ENVIRONMENT-db --project=$PROJECT_ID" \
    "List database users"

test_command \
    "gcloud sql backups list --instance=fincore-$ENVIRONMENT-db --project=$PROJECT_ID --limit=3" \
    "List recent backups"

# Test 3: Cloud Storage
print_header "Cloud Storage Buckets"

for BUCKET in "fincore-$ENVIRONMENT-terraform-state" "fincore-$ENVIRONMENT-artifacts" "fincore-$ENVIRONMENT-uploads"; do
    print_info "Testing bucket: $BUCKET"
    test_command \
        "gcloud storage buckets describe gs://$BUCKET --project=$PROJECT_ID" \
        "Verify bucket $BUCKET exists"
done

# Test 4: Service Accounts and IAM
print_header "Service Accounts and IAM Roles"

test_command \
    "gcloud iam service-accounts list --project=$PROJECT_ID" \
    "List service accounts"

test_command \
    "gcloud projects get-iam-policy $PROJECT_ID --flatten='bindings[].members' --filter='bindings.members:fincore-npe-cloudrun'" \
    "Check Cloud Run service account roles"

test_command \
    "gcloud secrets list --project=$PROJECT_ID" \
    "List secrets in Secret Manager"

# Test 5: Monitoring and Logging
print_header "Monitoring and Logging"

test_command \
    "gcloud alpha monitoring policies list --project=$PROJECT_ID" \
    "List alert policies"

test_command \
    "gcloud logging sinks list --project=$PROJECT_ID" \
    "List logging sinks"

# Test 6: Cloud Run Services
print_header "Cloud Run Services"

test_command \
    "gcloud run services list --region=$REGION --project=$PROJECT_ID" \
    "List Cloud Run services"

print_info "Attempting to retrieve service URLs..."
API_URL=$(gcloud run services describe fincore-$ENVIRONMENT-api --region=$REGION --project=$PROJECT_ID --format='value(status.url)' 2>/dev/null || echo "")
if [ -n "$API_URL" ]; then
    print_success "API Service URL: $API_URL"
else
    print_error "Could not retrieve API service URL"
fi

FRONTEND_URL=$(gcloud run services describe fincore-$ENVIRONMENT-frontend --region=$REGION --project=$PROJECT_ID --format='value(status.url)' 2>/dev/null || echo "")
if [ -n "$FRONTEND_URL" ]; then
    print_success "Frontend Service URL: $FRONTEND_URL"
else
    print_error "Could not retrieve Frontend service URL"
fi

# Test 7: Logs Check
print_header "Recent Logs and Errors"

print_info "Checking Cloud SQL error logs (last 30 minutes)..."
test_command \
    "gcloud logging read 'resource.type=cloudsql_database AND severity=ERROR' --limit=5 --project=$PROJECT_ID" \
    "Cloud SQL error logs"

print_info "Checking Cloud Run error logs (last 30 minutes)..."
test_command \
    "gcloud logging read 'resource.type=cloud_run_revision AND severity=ERROR' --limit=5 --project=$PROJECT_ID" \
    "Cloud Run error logs"

# Summary
echo -e "\n${CYAN}========================================================${NC}"
echo -e "${CYAN}TEST SUITE COMPLETE${NC}"
echo -e "${CYAN}========================================================${NC}"

echo -e "\n${YELLOW}Test Results:${NC}"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. If Cloud Run services not deployed:"
echo "   - Build and push Docker images"
echo "   - Run terraform apply to deploy services"
echo ""
echo "2. Once Cloud Run deployed:"
echo "   - Test API endpoints with curl or Postman"
echo "   - Verify Cloud SQL connectivity in logs"
echo ""
echo "3. Monitor costs:"
echo "   - GCP Console: Billing section"
echo "   - Expected: approximately 22 USD per month"
