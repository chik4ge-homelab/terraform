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
    data.talos_cluster_health.with_k8s
  ]

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  version = "7.7.16"
}

resource "helm_release" "bitwarden-secret-operator" {
  depends_on = [
    data.talos_cluster_health.with_k8s
  ]

  name         = "bw-sm-operator"
  repository   = "https://charts.bitwarden.com"
  chart        = "sm-operator"
  force_update = true
  replace      = true
  set = [{
    name  = "settings.bwSecretsManagerRefreshInterval"
    value = "180"
  }]

  version = "0.1.0-Beta"
}
