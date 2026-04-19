# Verification

All resources verified using AWS CLI using LocalStack endpoint (`http://localhost:4566`).

## S3 Buckets

```bash
aws --endpoint-url=http://localhost:4566 s3api list-buckets
```

```json
{
    "Buckets": [
        {
            "Name": "clarivate-dev-logs",
            "CreationDate": "2026-04-19T10:24:22+00:00",
            "BucketRegion": "us-east-1",
            "BucketArn": "arn:aws:s3:::clarivate-dev-logs"
        },
        {
            "Name": "clarivate-dev-state",
            "CreationDate": "2026-04-19T10:24:22+00:00",
            "BucketRegion": "us-east-1",
            "BucketArn": "arn:aws:s3:::clarivate-dev-state"
        },
        {
            "Name": "clarivate-prod-logs",
            "CreationDate": "2026-04-19T10:36:09+00:00",
            "BucketRegion": "us-east-1",
            "BucketArn": "arn:aws:s3:::clarivate-prod-logs"
        },
        {
            "Name": "clarivate-prod-state",
            "CreationDate": "2026-04-19T10:36:09+00:00",
            "BucketRegion": "us-east-1",
            "BucketArn": "arn:aws:s3:::clarivate-prod-state"
        }
    ]
}
```

## Versioning

```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning --bucket clarivate-dev-state
aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning --bucket clarivate-prod-state
```

```json
{ "Status": "Enabled" }
{ "Status": "Enabled" }
```

## Server-Side Encryption

```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket clarivate-dev-state
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket clarivate-prod-state
```

```json
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }
}
```

Both environments return identical SSE configuration with `AES256` algorithm.

## DynamoDB Tables

```bash
aws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1
```

```json
{
    "TableNames": [
        "clarivate-dev-state-lock",
        "clarivate-prod-state-lock"
    ]
}
```

## IAM Roles

```bash
aws --endpoint-url=http://localhost:4566 iam get-role --role-name clarivate-dev-log-processor
aws --endpoint-url=http://localhost:4566 iam get-role --role-name clarivate-prod-log-processor
```

Both roles confirm `lambda.amazonaws.com` as the principal with `sts:AssumeRole` action and correct environment tags.

## Permission Policies

```bash
aws --endpoint-url=http://localhost:4566 iam get-role-policy --role-name clarivate-dev-log-processor --policy-name clarivate-dev-s3-read
aws --endpoint-url=http://localhost:4566 iam get-role-policy --role-name clarivate-prod-log-processor --policy-name clarivate-prod-s3-read
```

```json
{
    "Statement": [
        {
            "Action": ["s3:GetObject", "s3:ListBucket"],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::clarivate-dev-logs",
                "arn:aws:s3:::clarivate-dev-logs/*"
            ]
        }
    ]
}
```

Dev policy targets `clarivate-dev-logs`, prod policy targets `clarivate-prod-logs`.

## Resource Tags

```bash
aws --endpoint-url=http://localhost:4566 s3api get-bucket-tagging --bucket clarivate-dev-state
aws --endpoint-url=http://localhost:4566 s3api get-bucket-tagging --bucket clarivate-prod-state
```

Dev tags confirm `environment: dev`, prod tags confirm `environment: prod`. Both include `project: clarivate` and `managed_by: terraform`.