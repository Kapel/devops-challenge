resource "aws_key_pair" "lifi-test" {
  key_name   = "lifi-test"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEj9q4d4VCX65BWnqoNKPHNlTEzPZBhvRDGX8mGemuCwmtpB0l0XdNgoV68wvD0edtRWIQYh7k7NUhgwqbcjNJC5oAthMDaOmZPennVnto+i4QzAZGQaZaT7Gofi576JNGaD/B7YXa0KC+6YG2TVrERotbviTyljXkEYue2n9n86xLx5CY5IVnKll6emq+Sm0vF95Kgcri1J+HjHdmUymj3GNuTYRQLj7ru7OBZ6XC1Be1XRpmUL4H/8L/hCnzOv8xq71sDGniZe7ce2M4TC8S7jhfOsEODGgNV0jF+J8S9zWHbgroyqPnxAV7M757ePmIce8UUm37EFPfzRuUzcP/Z+8/Kixv7vfr5CL7e9lwSajeGgzhPfbZ6ECibdFXZuWpUO+JNd8BY6cD5kqUZ5chZYiTVvIjC307CBORrbD9cbLPwhH1+y0VYW1ira0b4nLNv1SFePiQJ7TTwQZf7tTlAJ9IU8DmVLNzd1TYvO0ZWOADWldd26HFndIu4x87tnHsjPHsyMaZH/t1Sk0PMRamVwvl3y0urccOJH8bHVP9H0Yth681yvvThpcRLDvZLm432Rmphlkj5G+2PsUAvV/b11ZELBg+0oFxv3xWK36Za4CeJWhiQPmZ2ZPXgcliTeEQKMG0KO0aYpc+puZTxa6XQ2QTkD4l3UVmnXHZ92fdFQ== lifi-test@kapel"
}

module "ec2_instance" {
  # https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest
  source = "terraform-aws-modules/ec2-instance/aws"

  depends_on = [
    module.vpc,
    resource.aws_key_pair.lifi-test
  ]

  name = "lifi-test"

  instance_type               = "t3a.small"
  ami                         = "ami-0715d656023fe21b4" // debian ami, hardcoded for the specific region; can be automated; if manually updated -> https://wiki.debian.org/Cloud/AmazonEC2Image/Bookworm
  key_name                    = "lifi-test"
  monitoring                  = false
  vpc_security_group_ids      = module.vpc.default_vpc_default_security_group_id
  subnet_id                   = module.vpc.public_subnets[0] // this will choose the first element of the subnet list
  associate_public_ip_address = true


  # https://cloudinit.readthedocs.io/en/latest/reference/examples.html
  user_data = <<-EOF

  #cloud-config
  package_update: true
  package_upgrade: true

  runcmd:
    # Install K3s using the official install script
    - curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san `curl http://checkip.amazonaws.com`" sh -s

    # Wait a few seconds to ensure K3s service is up and running
    - sleep 5

    # Check the status of the K3s service
    - systemctl status k3s

    # Restart K3s in case it's required
    - systemctl restart k3s

    # Check the installed version of K3s
    - k3s --version

    # Get the kubeconfig
    - kubectl config view --raw >> /tmp/kubeconfig
  
  EOF


  tags = {
    Terraform   = "true"
    Environment = "devops-challenge"
  }
}