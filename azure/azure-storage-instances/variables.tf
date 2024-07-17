variable "prefix" {
    type = string 
}

variable "location" {
  type = string
}

variable "tags" {
  description = "Map of extra tags to attach to items which accept them"
  type        = map(string)
  default     = {}
}