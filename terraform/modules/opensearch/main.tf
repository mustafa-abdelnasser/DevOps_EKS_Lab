
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Name = "*private*"
  }
}

# data "aws_subnet" "private" {
#   for_each = toset(data.aws_subnets.private-subnets.ids)
#   id       = each.value
# }

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "opensearch_sg" {
  name        = "opensearch-${var.opensearch_domain}-sg"
  description = "opensearch security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block
    ]
  }
}

# logs
resource "aws_cloudwatch_log_group" "opensearch_index_slow_logs" {
  name = "/aws/opensearch/${var.opensearch_domain}/index_slow"
}


resource "aws_cloudwatch_log_group" "opensearch_search_slow_logs" {
  name = "/aws/opensearch/${var.opensearch_domain}/search_slow"
}

resource "aws_cloudwatch_log_group" "opensearch_es_application_logs" {
  name = "/aws/opensearch/${var.opensearch_domain}/es_application"
}


data "aws_iam_policy_document" "log_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    actions = [
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:CreateLogStream",
    ]

    resources = [
      "${aws_cloudwatch_log_group.opensearch_index_slow_logs.arn}:*",
      "${aws_cloudwatch_log_group.opensearch_search_slow_logs.arn}:*",
      "${aws_cloudwatch_log_group.opensearch_es_application_logs.arn}:*"
    ]

    condition {
      test = "ForAnyValue:StringEquals"
      variable = "aws:SourceAccount"
      values = [ "${data.aws_caller_identity.current.account_id}" ]
    }

    condition {
      test = "ForAnyValue:ArnLike"
      variable = "aws:SourceArn"
      values = [ "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain}" ]
    }
    # condition {
    #       "StringEquals" = {
    #           "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
    #       },
    #       "ArnLike" = {
    #           "aws:SourceArn": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain}"
    #       }
    #   }
  }
}


resource "aws_cloudwatch_log_resource_policy" "log_policy" {
  policy_name     = "opensearch_log_policy"
  policy_document = data.aws_iam_policy_document.log_policy.json
}

# opensearch master password
resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "opensearch_master_user" {
  name        = "/service/${var.opensearch_domain}/MASTER_USER"
  description = "opensearch_password for ${var.opensearch_domain} domain"
  type        = "SecureString"
  value       = "${var.opensearch_domain}-master,${random_password.password.result}"
}

# opensearch access policy
data "aws_iam_policy_document" "access_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain}/*"]
  }
}

# linked role 
# resource "aws_iam_service_linked_role" "opensearch-linked-role" {
#   aws_service_name = "opensearchservice.amazonaws.com"
# }

resource "aws_opensearch_domain" "cluster" {
  #depends_on = [ aws_iam_service_linked_role.opensearch-linked-role ]

  domain_name    = var.opensearch_domain
  engine_version = var.opensearch_engine_version

  cluster_config {
    dedicated_master_enabled = true
    dedicated_master_type = var.opensearch_dedicated_master_type
    dedicated_master_count = var.opensearch_dedicated_master_count
    instance_type = var.opensearch_instance_type
    instance_count = var.opensearch_instance_count
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = length(data.aws_subnets.private-subnets.ids)
    }
  }
  
  vpc_options {
    subnet_ids = data.aws_subnets.private-subnets.ids
    security_group_ids = [ aws_security_group.opensearch_sg.id ]
  }
  
  encrypt_at_rest {
      enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_data_volume_size
    volume_type = var.opensearch_data_volume_type
    throughput = var.opensearch_data_volume_throughput
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_index_slow_logs.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_search_slow_logs.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_es_application_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
    #custom_endpoint_enabled  = true
  }

  advanced_security_options {
    enabled = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name = "${var.opensearch_domain}-master"
      master_user_password = random_password.password.result
    }
  }
  
  advanced_options = {
    "override_main_response_version" = "true"
  }

  auto_tune_options {
    desired_state = enabled
  }

  access_policies = data.aws_iam_policy_document.access_policy.json

  tags = {
    Domain = var.opensearch_domain
  }
}