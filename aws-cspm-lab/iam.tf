data "aws_caller_identity" "current" {}

resource "aws_iam_role" "overly_permissive_role" {
  name = "cspm-lab-overly-permissive-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "cspm-lab"
    Purpose = "intentional-misconfig"
  }
}

resource "aws_iam_policy" "overly_permissive_policy" {
  name        = "cspm-lab-overly-permissive-policy"
  description = "Intentionally overly broad policy for CSPM lab"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "overly_permissive_attach" {
  role       = aws_iam_role.overly_permissive_role.name
  policy_arn = aws_iam_policy.overly_permissive_policy.arn
}

resource "aws_iam_role" "scoped_read_only_role" {
  name = "cspm-lab-scoped-read-only-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "cspm-lab"
  }
}

resource "aws_iam_role_policy_attachment" "scoped_read_only_attach" {
  role       = aws_iam_role.scoped_read_only_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}