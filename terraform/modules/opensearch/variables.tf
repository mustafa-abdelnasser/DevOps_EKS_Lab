variable "vpc_id" {
  type = string
}

# variable "subnet_ids" {
#   type = list(string)
# }

variable "opensearch_domain" {
  type = string
  default = "opensearch-cluster"
}

variable "opensearch_engine_version" {
    type = string
    default = "OpenSearch_2.5"
}

variable "opensearch_instance_type" {
    type = string
    default = "t3.small.search"
}

variable "opensearch_instance_count" {
    type = number
    default = 3
}

variable "opensearch_dedicated_master_type" {
    type = string
    default = "t3.small.search"
}

variable "opensearch_dedicated_master_count" {
    type = number
    default = 3
}

variable "opensearch_data_volume_size" {
  type = number
  default = 20
}

variable "opensearch_data_volume_type" {
  type = string
  default = "gp3"
}

variable "opensearch_data_volume_throughput" {
  type = number
  default = 125
}