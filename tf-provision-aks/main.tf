provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

resource "kubernetes_namespace" "kong-mesh-system" {
  metadata {
    name = "kong-mesh-system"
  }
  depends_on = [
    azurerm_kubernetes_cluster.default,
  ]
}

resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
  depends_on = [
    azurerm_kubernetes_cluster.default,
  ]
}

resource "kubernetes_secret" "license" {
   metadata {
    name = "kong-mesh-license"
    namespace = "kong-mesh-system"
   }
   type = "Opaque"
   data = {
        "license.json" = file("${path.cwd}/../license/license.json")
      }
}

resource "helm_release" "kong-mesh" {
  name              = "kong-mesh"
  chart             = "kong-mesh"
  repository = "https://kong.github.io/kong-mesh-charts"
  namespace         = "kong-mesh-system"
  dependency_update = true

  set {
    name  = "kuma.controlPlane.secrets[0].Env"
    value = "KMESH_LICENSE_INLINE"
  }

  set {
    name  = "kuma.controlPlane.secrets[0].Secret"
    value = "kong-mesh-license"
  }

  set {
    name  = "kuma.controlPlane.secrets[0].Key"
    value = "license.json"
  }

  depends_on = [
    kubernetes_namespace.kong-mesh-system
  ]
}

resource "helm_release" "kong-ingress-controller" {
  name              = "kong"
  chart             = "kong"
  repository = "https://charts.konghq.com"
  namespace         = "kong"
  dependency_update = true

  set {
    name  = "ingressController.installCRDs"
    value = "false"
  }

  depends_on = [
    helm_release.kong-mesh
  ]
}

resource "kubectl_manifest" "kong-mesh-gui-ingress" {
    yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mesh-gui
  namespace: kong-mesh-system
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: kong-mesh-control-plane
            port:
              number: 5681
YAML
}