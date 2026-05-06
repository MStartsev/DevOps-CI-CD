# IRSA для Kaniko дозволяє пушити образи в ECR без docker credentials
data "aws_iam_policy_document" "kaniko_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      # jenkins namespace, kaniko ServiceAccount
      values   = ["system:serviceaccount:jenkins:kaniko"]
    }
  }
}

resource "aws_iam_role" "kaniko" {
  name               = "${var.cluster_name}-kaniko-role"
  assume_role_policy = data.aws_iam_policy_document.kaniko_assume_role.json
  tags               = { Name = "${var.cluster_name}-kaniko-role", ManagedBy = "Terraform" }
}

# ECR push permissions
data "aws_iam_policy_document" "kaniko_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kaniko_ecr" {
  name   = "${var.cluster_name}-kaniko-ecr-policy"
  policy = data.aws_iam_policy_document.kaniko_ecr.json
}

resource "aws_iam_role_policy_attachment" "kaniko_ecr" {
  role       = aws_iam_role.kaniko.name
  policy_arn = aws_iam_policy.kaniko_ecr.arn
}