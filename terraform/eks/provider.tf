# set aws credentials
# export AWS_ACCESS_KEY_ID="anaccesskey"
# export AWS_SECRET_ACCESS_KEY="asecretkey"
# export AWS_REGION="us-west-1"

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# helm provider

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
  depends_on = [ module.eks_cluster ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
  depends_on = [ module.eks_cluster ]
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host = module.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.cluster.token
  load_config_file = false
}