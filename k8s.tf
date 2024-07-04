# @see https://registry.terraform.io/providers/hashicorp/helm
provider "helm" {
  kubernetes {
    config_path = "${path.module}/config/kubeconfig.yaml"
  }
}

# @see https://kubernetes.github.io/ingress-nginx/deploy/
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.nodePorts.http"
    value = "30000"
  }

  set {
    name  = "controller.service.enableHttps"
    value = false
  }
}