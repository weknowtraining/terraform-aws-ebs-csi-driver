data "aws_eks_cluster" "cluster" {
  name = var.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_id
}

# https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "kms:RetireGrant",
      "kms:CreateGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this" {
  name        = "Amazon_EBS_CSI_Driver"
  description = "Let EKS cluster EBS CSI driver make volumes"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.worker_iam_role_name
  policy_arn = aws_iam_policy.this.arn
}

locals {
  resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  reclaim_policy         = var.reclaim_policy
  volume_binding_mode    = var.volume_binding_mode

  parameters = {
    type                        = var.type
    "csi.storage.k8s.io/fstype" = var.fs_type
    encrypted                   = "true"
    kmsKeyId                    = var.kms_key_arn
  }
}
