resource "aws_iam_user" "cd" {
  name = "${local.prefix}-cd"
}

resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}

# permissions to access backend ------------ #
data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/deploy/*"
    ]
  }
}

resource "aws_iam_policy" "tf-backend" {
  name        = "${aws_iam_user.cd.name}-tf-backend-s3"
  policy      = data.aws_iam_policy_document.tf_backend.json
  description = "Allow access to the TF backend S3 bucket"
}

resource "aws_iam_user_policy_attachment" "tf-backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf-backend.arn
}

# permissions for ECR ------------------------ #
data "aws_iam_policy_document" "ecr" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [
      aws_ecr_repository.api.arn,
      aws_ecr_repository.proxy.arn
    ]
  }
}

resource "aws_iam_policy" "ecr" {
  name   = "${local.prefix}-ecr"
  policy = data.aws_iam_policy_document.ecr.json

}

resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}
