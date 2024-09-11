provider "helm" {
  kubernetes {
    config_path = "kubeconfig"
  }
}

# In a perfect world I would avoid using terraform for deploying helm charts (error handling, timeouts, updates, dependencies handling etc.)
# But If I'd have to use it I'd feature-flag each deployment with a boolean variable, so we can have different sets of deployments per environment, with a reasonable set of defaults. (DRY)
# Here - I'd like to get it working. KISS paradigm

resource "helm_release" "birb" {
  depends_on = [
    module.ec2_instance,
    resource.aws_key_pair.lifi-test,
    resource.null_resource.scp
  ]


  name             = "birb"
  chart            = "../helm/bird"
  namespace        = "birb-api"
  create_namespace = true

}

resource "helm_release" "observability" {
  #https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md

  depends_on = [
    module.ec2_instance,
    resource.aws_key_pair.lifi-test,
    resource.null_resource.scp,
  ]
  name             = "promstack"
  namespace        = "promstack"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "62.6.0"
  chart      = "kube-prometheus-stack"
}
