# Using K3s and Terraform to provision a local Kubernetes cluster

This repository contains a simple example of how K3s can be provisioned through docker compose, with cluster controllers provisioned through Terraform.

## Usage

```sh
# Start k3s
docker compose up -d

# Provision k8s controllers (using terraform)
terraform init && terraform apply
```