variable "chart_version" {
  default     = "2.4.0"
  description = "The Helm chart version to install"
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
  default     = "gp3"
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

variable "node_selector" {
  default     = {}
  type        = map(string)
  description = "Node selector for the helm chart"
}

variable "log_level" {
  default     = 4
  description = "Log level for the containers"
}

variable "tolerate_all_taints" {
  default     = false
  description = "Whether to tolerate all taints (not usually a good thing, breaks eviction when doing updates)"
}
