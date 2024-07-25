# main.tf

# Provider configuration for AWS
provider "aws" {
  region = "us-east-2"  # Replace with your desired AWS region
}

# Resource definition for S3 bucket
resource "aws_s3_bucket" "confluent_mongo_aws_demo_bucket" {
  bucket = "confluent-mongo-aws-demo"  # Replace with your desired bucket name
}

# Define IAM policy for CloudWatch Logs
resource "aws_iam_policy" "confluent_mongo_aws_cloudwatch_logs_policy" {
  name        = "lambda-cloudwatch-logs-policy"
  description = "Allows Lambda functions to write logs to CloudWatch Logs"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource  = "*"
      }
    ]
  })
}

# Define the IAM Role for Lambda 1
resource "aws_iam_role" "confluent_mongo_aws_lambda_role_1" {
  name               = "confluent-mongo-aws-lambda-1-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonS3FullAccess policy to Lambda 1 role
resource "aws_iam_policy_attachment" "lambda1_s3_full_access_attachment" {
  name       = "lambda1-s3-full-access"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_1.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach AmazonS3ObjectLambdaExecutionRolePolicy policy to Lambda 1 role
resource "aws_iam_policy_attachment" "lambda1_object_lambda_execution_attachment" {
  name       = "lambda1-object-lambda-execution"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_1.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}

# Attach CloudWatch Logs policy to Lambda 1 role
resource "aws_iam_policy_attachment" "lambda1_cloudwatch_logs_attachment" {
  name       = "lambda1-cloudwatch-logs"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_1.name]
  policy_arn = aws_iam_policy.confluent_mongo_aws_cloudwatch_logs_policy.arn
}

# Define the IAM Role for Lambda 2
resource "aws_iam_role" "confluent_mongo_aws_lambda_role_2" {
  name               = "confluent-mongo-aws-lambda-2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonS3FullAccess policy to Lambda 2 role
resource "aws_iam_policy_attachment" "lambda2_s3_full_access_attachment" {
  name       = "lambda2-s3-full-access"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_2.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach AmazonS3ObjectLambdaExecutionRolePolicy policy to Lambda 2 role
resource "aws_iam_policy_attachment" "lambda2_object_lambda_execution_attachment" {
  name       = "lambda2-object-lambda-execution"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_2.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}

# Attach CloudWatch Logs policy to Lambda 2 role
resource "aws_iam_policy_attachment" "lambda2_cloudwatch_logs_attachment" {
  name       = "lambda2-cloudwatch-logs"
  roles      = [aws_iam_role.confluent_mongo_aws_lambda_role_2.name]
  policy_arn = aws_iam_policy.confluent_mongo_aws_cloudwatch_logs_policy.arn
}

# Define the Lambda Layer Version
resource "aws_lambda_layer_version" "python3_layer" {
  layer_name = "python3Layer"  # Replace with your desired layer name
  compatible_runtimes = ["python3.11"]

  # specify your source code from a local directory:
  filename = "./layers/python3-Layer-for-lambda.zip"

  description = "Python 3.11 layer for Lambda functions"
}

# Define the Lambda Function for Valid Reviews
resource "aws_lambda_function" "confluent_mongo_aws_lambda_1" {
  function_name    = "confluent-mongo-aws-lambda-1"
  role             = aws_iam_role.confluent_mongo_aws_lambda_role_1.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 180
  memory_size      = 128

  # Specify your Lambda function code from a local ZIP file
  filename = "./scripts/lambda-valid-reviews/lambda_valid_reviews.zip"

  layers = [aws_lambda_layer_version.python3_layer.arn]

  tracing_config {
    mode = "PassThrough"
  }
}

# Define the Lambda Function for Invalid Reviews
resource "aws_lambda_function" "confluent_mongo_aws_lambda_2" {
  function_name    = "confluent-mongo-aws-lambda-2"
  role             = aws_iam_role.confluent_mongo_aws_lambda_role_2.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 600
  memory_size      = 512

  # Specify your Lambda function code from a local ZIP file
  filename = "./scripts/lambda-review-bombing/lambda_review_bombing.zip"

  layers = [aws_lambda_layer_version.python3_layer.arn]
  
  tracing_config {
    mode = "PassThrough"
  }
}

############### STEP FUNCTION CONFIGURATION FOR VALID REVIEWS ###########################

# Define the IAM Role for the Step Function
resource "aws_iam_role" "step_function_role" {
  name               = "StepFunctions-confluent-mongo-aws-state-function-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to the Step Function role
resource "aws_iam_policy_attachment" "step_function_policy_attachment" {
  name       = "step-function-policy-attachment"
  roles      = [aws_iam_role.step_function_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# Define the Step Function state machine for Valid Reviews
resource "aws_sfn_state_machine" "confluent_mongo_aws_state_function" {
  name     = "confluent-mongo-aws-state-function-1"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "Step Function to invoke Lambda 1 every 5 seconds indefinitely",
    StartAt = "InvokeLambda",
    States = {
      InvokeLambda = {
        Type     = "Task",
        Resource = aws_lambda_function.confluent_mongo_aws_lambda_1.arn,
        Next     = "WaitState",
        Retry    = [
          {
            ErrorEquals    = ["States.ALL"],
            IntervalSeconds = 5,
            MaxAttempts     = 3,
            BackoffRate     = 2
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "WaitState"
          }
        ]
      },
      WaitState = {
        Type   = "Wait",
        Seconds = 5,
        Next   = "CheckForEnd"
      },
      CheckForEnd = {
        Type    = "Choice",
        Choices = [
          {
            Variable      = "$.continue",
            BooleanEquals = true,
            Next          = "InvokeLambda"
          }
        ],
        Default = "EndState"
      },
      EndState = {
        Type = "Succeed"
      }
    }
  })
}

############### STEP FUNCTION CONFIGURATION FOR INVALID REVIEWS ###########################

# Define the IAM Role for the Step Function
resource "aws_iam_role" "step_function_role_2" {
  name               = "StepFunctions-confluent-mongo-aws-state-function-2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to the Step Function role
resource "aws_iam_policy_attachment" "step_function_policy_attachment_2" {
  name       = "step-function-policy-attachment-2"
  roles      = [aws_iam_role.step_function_role_2.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# Define the Step Function state machine for Invalid Reviews
resource "aws_sfn_state_machine" "confluent_mongo_aws_state_function_2" {
  name     = "confluent-mongo-aws-state-function-2"
  role_arn = aws_iam_role.step_function_role_2.arn

  definition = jsonencode({
    Comment = "Step Function to invoke Lambda 2 every 3 minutes indefinitely",
    StartAt = "InvokeLambda",
    States = {
      InvokeLambda = {
        Type     = "Task",
        Resource = aws_lambda_function.confluent_mongo_aws_lambda_2.arn,
        Next     = "WaitState",
        Retry    = [
          {
            ErrorEquals    = ["States.ALL"],
            IntervalSeconds = 5,
            MaxAttempts     = 3,
            BackoffRate     = 2
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "WaitState"
          }
        ]
      },
      WaitState = {
        Type   = "Wait",
        Seconds = 180,
        Next   = "CheckForEnd"
      },
      CheckForEnd = {
        Type    = "Choice",
        Choices = [
          {
            Variable      = "$.continue",
            BooleanEquals = true,
            Next          = "InvokeLambda"
          }
        ],
        Default = "EndState"
      },
      EndState = {
        Type = "Succeed"
      }
    }
  })
}
