terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"  # Replace with your actual S3 bucket name
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"             # Replace with your actual DynamoDB table
    encrypt        = true
  }
}
