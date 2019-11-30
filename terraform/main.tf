provider "aws" {
  region = "sa-east-1"
}

//lambda function handler & code file
resource "aws_lambda_function" "lambda-function" {
  function_name = "Function01"
  handler = "com.rafael.lambda.Function01"
  role = "arn:aws:iam::205303771310:role/LambdaRoleTest"
  runtime = "java8"
  s3_bucket = aws_s3_bucket.sns-test.id
  s3_key = aws_s3_bucket_object.file_upload.id
  source_code_hash = filebase64sha256("../target/sns-cw-lambda-poc.jar")
}

//allow sns to call lambda
resource "aws_lambda_permission" "allow-sns-to-lambda" {
  function_name = aws_lambda_function.lambda-function.function_name
  action = "lambda:InvokeFunction"
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.call-lambdas-topic.arn
  statement_id = "AllowExecutionFromSNS"
}

//app s3 repository
resource "aws_s3_bucket" "sns-test" {
  bucket = "app-bucket-38295504053"
  region = "sa-east-1"
}

//app jar file
resource "aws_s3_bucket_object" "file_upload" {
  depends_on = [
    aws_s3_bucket.sns-test
  ]
  bucket = aws_s3_bucket.sns-test.id
  key = "sns-cw-lambda-poc.jar"
  source = "../target/sns-cw-lambda-poc.jar"
  server_side_encryption = "AES256"
  etag = filebase64sha256("../target/sns-cw-lambda-poc.jar")
}

//lambda logs register
resource "aws_cloudwatch_log_group" "lambda-cloudwatch-logs" {
  name = "/aws/lambda/${aws_lambda_function.lambda-function.function_name}"
  retention_in_days = 1
}

//rule to trigger SNS
resource "aws_cloudwatch_event_rule" "publish-sns-rule" {
  name = "publish-sns-rule"
  schedule_expression = "rate(1 minute)"
}

//cloud watch event targets SNS
resource "aws_cloudwatch_event_target" "sns-publish" {
  count = "1"
  rule = aws_cloudwatch_event_rule.publish-sns-rule.name
  target_id = aws_sns_topic.call-lambdas-topic.name
  depends_on = ["aws_cloudwatch_event_rule.publish-sns-rule"] //****
  arn = aws_sns_topic.call-lambdas-topic.arn
}

//SNS topic to subscribe
resource "aws_sns_topic" "call-lambdas-topic" {
  name = "call-lambdas-topic"
}

//topic subscritpion by lambda
resource "aws_sns_topic_subscription" "sns-lambda-subscritption" {
  topic_arn = aws_sns_topic.call-lambdas-topic.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.lambda-function.arn
}

resource "aws_sns_topic_policy" "default" {
  count  = 1
  arn    = aws_sns_topic.call-lambdas-topic.arn
  policy = "${data.aws_iam_policy_document.sns_topic_policy.0.json}"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = "1"
  statement {
    sid       = "Allow CloudwatchEvents"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.call-lambdas-topic.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}