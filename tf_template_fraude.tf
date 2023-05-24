terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

variable "envType" {
  description = "Environment dev/qa/prod"
  type        = string
}

resource "aws_iam_policy" "IAMManagedPolicy" {
    name = "manageUser-fraude-lambdaBasicExecutionRole-dev"
    path = "/service-role/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-east-1:563875027714:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}

EOF
}

resource "aws_iam_policy" "IAMManagedPolicy2" {
    name = "manageUser-fraude-inlinePolicy-dev"
    path = "/"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ec2:CreateNetworkInterface",
                "ses:SendEmail",
                "secretsmanager:GetSecretValue",
                "dynamodb:PutItem",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ssm:GetParameter"
            ],
            "Resource": "*"
        }
    ]
}

EOF
}

resource "aws_lambda_function" "LambdaFunction" {
    description = ""
    function_name = "manageUser-fraude-dev"
    handler = "lambda_function.lambda_handler"
    architectures = [
        "x86_64"
    ]
    s3_bucket = "prod-04-2014-tasks"
    s3_key = "/snapshots/563875027714/manageUser-fraude-dev-3cd24fed-9570-4934-a36a-8e241fe8441c"
    s3_object_version = "cv.01ypqRijPMo.iqRFtoje4wdzDzjCI"
    memory_size = 128
    role = "${aws_iam_role.IAMRole.arn}"
    runtime = "python3.7"
    timeout = 30
    tracing_config {
        mode = "PassThrough"
    }
    tags = {}
}

resource "aws_lambda_permission" "LambdaPermission" {
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.LambdaFunction.arn}"
    principal = "apigateway.amazonaws.com"
    source_arn = "arn:aws:execute-api:us-east-1:563875027714:kqu7c7qoog/*/POST/user"
}

resource "aws_api_gateway_rest_api" "ApiGatewayRestApi" {
    name = "manageUser-fraude-api-dev"
    api_key_source = "HEADER"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"execute-api:Invoke\",\"Resource\":\"*\",\"Condition\":{\"IpAddress\":{\"aws:SourceIp\":\"40.118.241.243/32\"}}}]}"
    endpoint_configuration {
        types = [
            "REGIONAL"
        ]
    }
    tags = {}
}

resource "aws_api_gateway_method" "ApiGatewayMethod" {
    rest_api_id = "${aws_api_gateway_rest_api.ApiGatewayRestApi.id}"
    resource_id = "m11sur"
    http_method = "POST"
    authorization = "NONE"
    api_key_required = false
    request_parameters = {}
    request_models = {}
}

resource "aws_api_gateway_deployment" "ApiGatewayDeployment" {
    rest_api_id = "${aws_api_gateway_rest_api.ApiGatewayRestApi.id}"
    description = "My deployment"
}

resource "aws_api_gateway_resource" "ApiGatewayResource" {
    rest_api_id = "${aws_api_gateway_rest_api.ApiGatewayRestApi.id}"
    path_part = "user"
    parent_id = "ci1rn61xs1"
}

resource "aws_ssm_parameter" "SSMParameter" {
    name = "/dev/manageUser-fraude/maxId"
    type = "String"
    value = "0"
}

resource "aws_ssm_parameter" "SSMParameter2" {
    name = "/dev/manageUser-fraude/auth0"
    type = "String"
    value = <<EOF
{
    "domain": "deuna-backend.dev.deunalab.com",
    "audience": "https://deuna-dev.us.auth0.com/api/v2/"
}

EOF
}

resource "aws_dynamodb_table" "DynamoDBTable" {
    attribute {
        name = "id"
        type = "N"
    }
    name = "manageUser-fraude-audit-dev"
    hash_key = "id"
    read_capacity = 1
    write_capacity = 1
    global_secondary_index {
        name = "id-index"
        hash_key = "id"
        projection_type = "ALL"
        read_capacity = 1
        write_capacity = 1
    }
}

resource "aws_iam_role" "IAMRole" {
    path = "/service-role/"
    name = "manageUser-fraude-dev-role"
    assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    max_session_duration = 3600
    tags = {}
}

resource "aws_secretsmanager_secret" "SecretsManagerSecret" {
    name = "/dev/manageUser-fraude/auth0-creds"
    tags = {}
}

resource "aws_secretsmanager_secret_version" "SecretsManagerSecretVersion" {
    secret_id = "${aws_secretsmanager_secret.SecretsManagerSecret.id}"
    secret_string = "{\"client_id\":\"ve2zXiZMoKK8I9IO7yGlNu3Dkx0wdRSu\",\"client_secret\":\"Ty4TTkVSS_tSzWV2pF6mkFblZKhd-jGHOE6eaKJjTENNJWACUMm00Y7BJKoHt7Y0\"}"
}
