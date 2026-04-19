# Clarivate Terraform Challenge

## What You Built

Using LocalStack to simulate AWS, I created two S3 buckets (`state` and `logs`) per environment using a reusable Terraform module. Both buckets have versioning and server-side encryption (AES256) enabled. An IAM role with a permission policy is defined to represent a Lambda function with read access to the logs bucket (`s3:GetObject`, `s3:ListBucket`). A DynamoDB table is included for Terraform state locking purposes.

Both environments are deployed simultaneously using separate state files (`terraform-dev.tfstate` and `terraform-prod.tfstate`). In production, state would be stored remotely in S3 with DynamoDB locking.

## How Does Environment Affect Configuration

The environment name is passed as a variable and integrated into resource names. For example: `clarivate-dev-state` and `clarivate-prod-state`. The same module is called twice with different input values, avoiding code duplication.

Each environment has its own tfvars file and state file, specified explicitly on every command:

```bash
terraform apply -var-file="dev.tfvars" -state="terraform-dev.tfstate"
terraform apply -var-file="prod.tfvars" -state="terraform-prod.tfstate"
```

## Terraform Explanation

Variables allow the same code to be reused with different values. A `variables.tf` file defines what inputs are expected, while a `tfvars` file provides the actual values.

The flow is as follows: values from `dev.tfvars` or `prod.tfvars` are loaded into root `variables.tf`, then passed to the module via `main.tf`. The module creates resources using those values, publishes outputs (`bucket_id`, `bucket_arn`) through `outputs.tf`, and the root `outputs.tf` exposes them to the user after apply. 

`locals` are values defined internally, instead of being passed from the outside. In this case, `common_tags` is constructed from existing variables and applied to all resources using `local.common_tags`, avoiding repetition across every resource block.

The `environment` variable has no default value and this is intentional. Without a default, Terraform throws an error if no value is provided, forcing an explicit environment choice. A `validation` block further restricts accepted values to `dev` and `prod` only.

Terraform knows which environment to deploy to based on the `-var-file` flag passed at runtime:
```bash
terraform apply -var-file="dev.tfvars" -state="terraform-dev.tfstate"
```

## IAM Explanation

I have created two IAM resources: an IAM role and an inline policy attached to it.

The IAM role (`log-processor`) is designed to be assumed by a Lambda function. In this case, the trust policy allows `lambda.amazonaws.com` as the principal, meaning only Lambda can assume this role.

The attached permission policy grants two actions on the logs bucket: `s3:GetObject` for reading log files and `s3:ListBucket` for listing bucket contents. This represents a Lambda function that would process S3 access logs, for example: parsing them and forwarding metrics to CloudWatch.

## DynamoDB

A DynamoDB table is provisioned as an additional resource, intended to support Terraform state locking in a production setup. When `terraform apply` is run simultaneously, state locking prevents concurrent writes that could corrupt the state file. Terraform writes a lock entry to the table before apply and releases it after completion.

`PAY_PER_REQUEST` billing mode is used intentionally. A state locking table is accessed infrequently, so reserving read/write capacity in advance would be unnecessary. With `PAY_PER_REQUEST`, cost scales with actual usage.

DynamoDB felt like a natural fit here, as it is the go-to AWS solution for state locking and ensures that only one process can write a lock entry at a time, preventing simultaneous applies.

## How to Run

Ensure LocalStack is running before executing any commands:

```bash
docker run --rm -d -p 4566:4566 --name localstack localstack/localstack
```

Initialize, validate and format:

```bash
terraform init
terraform fmt -recursive
terraform validate
```

Deploy dev environment:

```bash
terraform plan -var-file="dev.tfvars" -state="terraform-dev.tfstate" -out=tfplan-dev.binary
terraform apply -state="terraform-dev.tfstate" "tfplan-dev.binary"
```

Deploy prod environment:

```bash
terraform plan -var-file="prod.tfvars" -state="terraform-prod.tfstate" -out=tfplan-prod.binary
terraform apply -state="terraform-prod.tfstate" "tfplan-prod.binary"
```

The same code deploys both environments — only the `-var-file` and `-state` flags differ.

For my final plans and applies, I have added a pipe which writes in txt files using tee command. Example:
```terraform plan ... 2>&1 | tee ../outputs/dev-plan.txt```

## Verification

See [VERIFICATION.md](./VERIFICATION.md) for full CLI verification of all deployed resources including S3 buckets, versioning, encryption, DynamoDB tables, IAM roles permission policies, and resource tags.

## Reflection

### What Was New or Unfamiliar
Writing a reusable Terraform module from scratch was new for me. In my current role I work with Terraform in a different way, in form of using wrapper scripts and existing configurations, which were gradually implemented by senior engineers and architects, rather than building modules myself. Understanding how variables and outputs flow between root and child modules was challenging and required hands-on practice for proper implementation.

AWS provider v4+ syntax was also unfamiliar, since resources like versioning and server-side encryption are now separate from the main `aws_s3_bucket` resource, which differs from most examples I found during my early research with Terraform.

### What I Had to Look Up
- As mentioned above, current syntax for `aws_s3_bucket_versioning` and `aws_s3_bucket_server_side_encryption_configuration`
- LocalStack provider configuration. Although I've had experience with LocalStack in one of my recent projects, I hadn't used S3 there. In this project I specifically had to find a solution for S3 bucket creation hanging. I resolved it by adding `s3_use_path_style = true` to the provider config.
- Although I had an idea of implementing remote backend, I wanted to find a solution for local state files. Since remote backend is yet to be implemented, I decided to use two separate state files, one for dev and one for prod, so both environments can exist simultaneously. That's where I had to look up the `-state` flag for their separation.
- Structure of IAM trust policy vs permission policy in IaC format.

I used Claude and Terraform documentation as a reference throughout, similar to how I would ask a senior or experienced colleague, to verify syntax and consult on architectural decisions. All decisions, testing, implementations and explanations were, in the end, my own.

### What I Would Improve With More Time
I can surely say that I will improve, since I have a lot of ideas and this project definitely will not stop here.

Some of the ideas that are currently planned:
- Configure a proper remote S3 backend with DynamoDB state locking instead of local state files with the `-state` flag, since I've gathered understanding of why that would serve as best practice.
- Add a CI/CD pipeline with `terraform plan` on pull requests and `terraform apply` on merge to main.
- Implement actual S3 access logging configuration connecting the logs bucket to the state bucket using `aws_s3_bucket_logging` resource, ensuring access logs of the state bucket are automatically written to the logs bucket.
- Add a random naming suffix for S3 buckets to guarantee global uniqueness, which is an AWS requirement.
- Put more accent on granular environment differences between dev and prod, for example: Different versioning policies or bucket lifecycle rules that would reflect real use cases of each environment.