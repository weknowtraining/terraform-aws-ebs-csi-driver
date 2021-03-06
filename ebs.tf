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

# https://github.com/kubernetes-sigs/aws-ebs-csi-driver
resource "helm_release" "this" {
  name        = "aws-ebs-csi-driver"
  repository  = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart       = "aws-ebs-csi-driver"
  version     = var.chart_version
  max_history = 10
  namespace   = var.namespace

  set {
    name  = "enableVolumeResizing"
    value = var.volume_resizing
  }

  set {
    name  = "enableVolumeScheduling"
    value = var.volume_scheduling
  }

  set {
    name  = "enableVolumeSnapshot"
    value = var.volume_snapshot
  }

  dynamic "set" {
    for_each = var.extra_tags
    content {
      name  = "extraVolumeTags.${set.key}"
      value = set.value
    }
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.cpu"
    value = "128Mi"
  }

  set {
    name  = "k8sTagClusterId"
    value = var.cluster_id
  }

  set {
    name  = "tolerateAllTaints"
    value = var.tolerate_all_taints
  }

  values = [
    yamlencode({
      nodeSelector = var.node_selector
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

locals {
  log_level_patch = templatefile("${path.module}/patches.d/daemonset.yml", { log_level : var.log_level })
}

# So ebs-snapshot-controller isn't so loud
resource "null_resource" "log-level" {
  triggers = {
    revision = helm_release.this.metadata.0.revision
    patch    = sha1(local.log_level_patch)
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}
EOF
kubectl --server="${data.aws_eks_cluster.cluster.endpoint}" --certificate-authority=/tmp/ca.crt --token="${data.aws_eks_cluster_auth.cluster.token}" \
  patch daemonset ebs-csi-node \
  --namespace ${var.namespace} \
  --type json \
  --patch '${local.log_level_patch}'
EOH
  }
}
