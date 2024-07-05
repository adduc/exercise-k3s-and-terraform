terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubectl" {
  config_path = "${path.module}/config/kubeconfig.yaml"
}

# @see https://registry.terraform.io/providers/hashicorp/helm
provider "helm" {
  kubernetes {
    config_path = "${path.module}/config/kubeconfig.yaml"
  }
}

# Provision the Gateway API CRDs

data "kubectl_file_documents" "gateway_api" {
  content = file("${path.module}/manifests/gateway-api-standard-1.1.0.yaml")
}

resource "kubectl_manifest" "gateway_api" {
  for_each = {
    for m in data.kubectl_file_documents.gateway_api.manifests : "${yamldecode(m).kind} ${yamldecode(m).metadata.name}" => m
  }
  yaml_body = each.value
}

# Provision Nginx's Gateway API implementation
# @see https://github.com/nginxinc/nginx-gateway-fabric

resource "helm_release" "nginx_gateway" {
  name             = "nginx-gateway"
  repository       = "oci://ghcr.io/nginxinc/charts"
  chart            = "nginx-gateway-fabric"
  namespace        = "nginx-gateway"
  create_namespace = true
  version          = "1.3.0"
  depends_on       = [kubectl_manifest.gateway_api]

  values = [
    yamlencode({
      service = {
        type = "NodePort"
        ports = [
          {
            port       = 80
            targetPort = 80
            nodePort   = 30000
            protocol   = "TCP"
            name       = "http"
          }
        ]
      }
    })
  ]
}

# Provision an initial gateway listener for port 80 (relative to the
# nginx pods)

data "kubectl_file_documents" "gateway_http" {
  content = file("${path.module}/manifests/gateway-http.yaml")
}

resource "kubectl_manifest" "gateway_http" {
  for_each = {
    for m in data.kubectl_file_documents.gateway_http.manifests : "${yamldecode(m).kind} ${yamldecode(m).metadata.name}" => m
  }
  yaml_body  = each.value
  depends_on = [helm_release.nginx_gateway]
}

# Provision a dummy app and its gateway routes

data "kubectl_file_documents" "hello_world" {
  content = file("${path.module}/manifests/dummy-app.yaml")
}

resource "kubectl_manifest" "hello_world" {
  for_each = {
    for m in data.kubectl_file_documents.hello_world.manifests : "${yamldecode(m).kind} ${yamldecode(m).metadata.name}" => m
  }
  yaml_body  = each.value
  depends_on = [kubectl_manifest.gateway_http]
}