name: "Bootstrap Quick Test"

on:
  workflow_dispatch:
    inputs:
      MODE:
        description: "Terraform mode"
        type: choice
        required: true
        default: plan
        options: [plan, apply]
      STATE_BUCKET_NAME:
        description: "S3 bucket for Terraform state"
        required: true
        default: iot-playground-tfstate

env:
  AWS_REGION: eu-west-3

jobs:
  quick-test:
    name: "Quick Infrastructure Test [${{ github.event.inputs.MODE }}]"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Create minimal test infrastructure
        run: |
          # Créer un répertoire temporaire avec une config Terraform minimale
          mkdir -p /tmp/test-infra
          cd /tmp/test-infra

          cat > main.tf << 'EOF'
          terraform {
            required_version = ">= 1.9.0"
            required_providers {
              aws = {
                source  = "hashicorp/aws"
                version = "~> 5.0"
              }
            }
            backend "s3" {}
          }

          provider "aws" {
            region = "eu-west-3"
          }

          # Ressource simple pour tester
          resource "aws_s3_bucket" "test" {
            bucket = "iot-playground-test-${formatdate("YYYYMMDDhhmmss", timestamp())}"

            tags = {
              Name        = "Quick Test Bucket"
              Environment = "test"
              Purpose     = "API Testing"
            }
          }

          output "bucket_name" {
            value = aws_s3_bucket.test.bucket
          }
          EOF

          # Initialiser et déployer
          terraform init \
            -backend-config="bucket=${{ github.event.inputs.STATE_BUCKET_NAME }}" \
            -backend-config="key=quick-test/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}" \
            -backend-config="dynamodb_table=terraform-locks"

          terraform plan -out=tfplan

          if [ "${{ github.event.inputs.MODE }}" == "apply" ]; then
            terraform apply -auto-approve tfplan
            echo "✅ Quick test infrastructure deployed!"
            terraform output
          fi

      - name: Summary
        if: github.event.inputs.MODE == 'apply'
        run: |
          echo "### ✅ Quick Test Successful" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "Test infrastructure deployed in ~30 seconds!" >> $GITHUB_STEP_SUMMARY
          echo "You can now test the API with this workflow." >> $GITHUB_STEP_SUMMARY

