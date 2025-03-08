resource "helm_release" "cilium" {
  depends_on = [
    data.talos_cluster_health.without_k8s,
    talos_cluster_kubeconfig.this
  ]

  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  namespace  = "kube-system"

  version = "1.17.0"

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
    data.talos_cluster_health.without_k8s,
    talos_cluster_kubeconfig.this
  ]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  version = "7.8.9"
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
    data.talos_cluster_health.without_k8s,
    talos_cluster_kubeconfig.this
  ]

  metadata {
    name      = "bw-auth-token"
    namespace = "external-secrets"
  }

  type      = "Opaque"
  immutable = true

  data = {
    "token" = var.bitwarden_token
  }
}

resource "argocd_application" "apps" {
  depends_on = [
    helm_release.argocd
  ]

  metadata {
    name      = "apps"
    namespace = "argocd"
  }

  spec {
    project = "default"
    source {
      repo_url        = "https://github.com/chik4ge-homelab/homelab-applications"
      path            = "."
      target_revision = "main"
    }
    destination {
      namespace = "default"
      server    = "https://kubernetes.default.svc"
    }
    sync_policy {
      automated {
        prune     = true
        self_heal = false
      }
    }
  }
}
