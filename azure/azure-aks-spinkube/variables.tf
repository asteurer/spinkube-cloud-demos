variable "prefix" {
  default = "spinkube-demo"
}

variable "location" {
  default = "westus2"
  type    = string
}

variable "kubernetes_version" {
  default = "1.29.2"
  type    = string
}

variable "sku_tier" {
  default = "Free"
  type    = string
}

variable "system_nodepool" {
  type = object({
    name = string
    size = string
    min  = number
    max  = number
  })
  default = {
    name = "agentpool"
    size = "Standard_D2s_v5"
    min  = 1
    max  = 1
  }
}

variable "user_nodepools" {
  type = list(object({
    name       = string
    size       = string
    node_count = number
    max_pods   = number
    labels     = map(string)
    taints     = list(string)
  }))
  default = [{
    name       = "spinapps"
    size       = "Standard_D2s_v5"
    node_count = 1
    max_pods   = 250
    labels = {
      "runtime" = "containerd-shim-spin"
    }
    taints = []
    },
    {
      name       = "system"
      size       = "Standard_D2s_v5"
      node_count = 1
      max_pods   = 100
      labels = {
        "workload" = "system"
      }
      taints = []
  }]
}

variable "apps_nodepool_sku" {
  description = "SKU override for the node(s) hosting SpinApps. (Default: empty, inherit SKU used in var.user_nodepools)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of extra tags to attach to items which accept them"
  type        = map(string)
  default     = {}
}
