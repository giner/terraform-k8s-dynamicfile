# terraform-k8s-dynamicfile
Terraform module to spin up a web-server serving static content provided and refreshed by a command running recurrently inside a Kubernetes pod

## Usage example

See [variables.tf](variables.tf) for configuration options

example.tf:
```terraform
provider "kubernetes" {
  config_path = "/var/snap/microk8s/current/credentials/client.config" # Example for MicroK8s
}

module "dynamicfile" {
  source = "git::https://github.com/giner/terraform-k8s-dynamicfile"  # Make sure to use ref to a specific commit for production

  command = "echo \"Hello, World! Time is $(date +%T)\""
}
```

How to run:
```shell
terraform apply
kubectl get --raw /api/v1/namespaces/default/services/dynamicfile/proxy
# OUTPUT: Hello, World! Time is 14:31:07
```
