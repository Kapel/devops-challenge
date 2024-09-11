resource "null_resource" "scp" {
  # https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
  depends_on = [
    module.ec2_instance,
    resource.aws_key_pair.lifi-test
  ]

  #https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
  provisioner "local-exec" {
    command = <<EOT
      attempt=1;
      while [ $attempt -le 15 ]; do
        scp -i ~/.ssh/lifi-test -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@${module.ec2_instance.public_ip}:/tmp/kubeconfig . && break || echo "SCP failed. Retrying in 20 seconds..." && sleep 20;
        attempt=$((attempt + 1));
      done;
      [ $attempt -le 15 ] || (echo "SCP failed after 15 attempts." && exit 1);
      sed -i 's/127.0.0.1/${module.ec2_instance.public_ip}/g' kubeconfig;
    EOT

  }
}
