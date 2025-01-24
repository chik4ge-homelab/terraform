resource "helm_release" "cilium" {
  depends_on = [
    data.talos_cluster_health.without_k8s
  ]

  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  namespace  = "kube-system"

  version = "1.16.6"

  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = "true"
    },
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
    },
    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = "false"
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "k8sServicePort"
      value = "7445"
    }
  ]
}

resource "helm_release" "argocd" {
  depends_on = [
    data.talos_cluster_health.without_k8s
  ]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  version = "7.7.17"
}

# get argocd initial admin password
data "kubernetes_secret" "argocd-initial-admin-secret" {
  depends_on = [
    helm_release.argocd
  ]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

resource "kubernetes_secret" "bw-auth-token" {
  depends_on = [
    data.talos_cluster_health.without_k8s
  ]

  metadata {
    name = "bw-auth-token"
  }

  type      = "Opaque"
  immutable = true

  data = {
    "token" = var.bitwarden_token
  }
}

resource "argocd_application" "external-secrets" {
  depends_on = [
    helm_release.argocd
  ]

  metadata {
    name      = "external-secrets-bitwarden"
    namespace = "argocd"
  }

  spec {
    project = "default"
    source {
      repo_url        = "https://github.com/chik4ge-homelab/external-secrets-bitwarden"
      path            = "."
      target_revision = "main"
    }
    destination {
      namespace = "default"
      server    = "https://kubernetes.default.svc"
    }
    sync_policy {
      automated {
        prune = true
      }
      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }
}

# resource "argocd_application" "self-managed-argocd" {
#   depends_on = [
#     helm_release.argocd
#   ]

#   metadata {
#     name      = "argo-cd"
#     namespace = "argocd"
#   }

#   spec {
#     project = "default"
#     source {
#       repo_url        = "https://github.com/chik4ge-homelab/self-managed-argocd"
#       path            = "."
#       target_revision = "main"
#     }
#     destination {
#       namespace = "argocd"
#       server    = "https://kubernetes.default.svc"
#     }
#     sync_policy {
#       automated {
#         prune = true
#       }
#     }
#   }
# }
