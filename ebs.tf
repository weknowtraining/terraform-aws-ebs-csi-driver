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

# https://github.com/kubernetes-sigs/aws-ebs-csi-driver
resource "helm_release" "this" {
  name        = "aws-ebs-csi-driver"
  repository  = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart       = "aws-ebs-csi-driver"
  version     = var.chart_version
  max_history = 10
  namespace   = var.namespace

  dynamic "set" {
    for_each = var.extra_tags
    content {
      name  = "controller.extraVolumeTags.${set.key}"
      value = set.value
    }
  }

  values = [
    yamlencode({
      sidecars = {
        provisioner = {
          logLevel = var.log_level
        }
        attacher = {
          logLevel = var.log_level
        }
        snapshotter = {
          logLevel = var.log_level
        }
        livenessProbe = {
          logLevel = var.log_level
        }
        resizer = {
          logLevel = var.log_level
        }
        nodeDriverRegistrar = {
          logLevel = var.log_level
        }
      }
      node = {
        tolerateAllTaints = var.tolerate_all_taints
        nodeSelector      = var.node_selector
        resources         = local.resources
        logLevel          = var.log_level
      }

      controller = {
        nodeSelector    = var.node_selector
        k8sTagClusterId = var.cluster_id
        resources       = local.resources
        logLevel        = var.log_level
      }
    })
  ]
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
