variable "chart_version" {
  default     = "0.8.2"
  description = "The Helm chart version to install"
}

variable "volume_resizing" {
  default     = true
  description = "Whether to allow volume resizing"
}

variable "volume_scheduling" {
  default     = true
  description = "Whether to allow volume scheduling"
}

variable "volume_snapshot" {
  default     = true
  description = "Whether to allow volume snapshots"
}

variable "cluster_id" {
  description = "The EKS cluster_id"
}

variable "storage_class_name" {
  description = "The name to give the new StorageClass"
}

variable "worker_iam_role_name" {
  description = "The EKS worker IAM role name"
}

variable "kms_key_arn" {
  description = "The KMS key ARN to encrypt volumes with"
}

variable "type" {
  default     = "gp2"
  description = "The type of storage to use"

  validation {
    condition     = contains(["gp3", "gp2", "io2", "io1", "st1", "sc1", "standard"], var.type)
    error_message = "Must be one of gp3, gp2, io2, io1, st1, sc1, standard."
  }
}

variable "fs_type" {
  default     = "ext4"
  description = "The filesystem type to use"

  validation {
    condition     = contains(["ext4", "xfs"], var.fs_type)
    error_message = "Must be one of ext4 or xfs."
  }
}

variable "reclaim_policy" {
  default     = "Delete"
  description = "The reclaim policy for the StorageClass"

  validation {
    condition     = contains(["Delete", "Retain"], var.reclaim_policy)
    error_message = "Must be one of Delete or Retain."
  }
}

variable "volume_binding_mode" {
  default     = "WaitForFirstConsumer"
  description = "The volume binding mode for the StorageClass"

  validation {
    condition     = contains(["WaitForFirstConsumer", "Immediate"], var.volume_binding_mode)
    error_message = "Must be one of WaitForFirstConsumer or Immediate."
  }
}

variable "extra_tags" {
  type        = map(string)
  default     = {}
  description = "A map of extra volume tags"
}

variable "namespace" {
  default     = "kube-system"
  description = "The k8s namespace to install the driver in"
}
