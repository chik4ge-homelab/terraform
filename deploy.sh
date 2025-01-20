#!/bin/bash

# Terraform init
terraform init

# Terraform apply
terraform apply -auto-approve

# if succeeded
if [ $? -eq 0 ]; then
    terraform output -raw kubeconfig >~/.kube/config
    chmod 600 ~/.kube/config
    echo "Kubeconfig file is copied to ~/.kube/config"

    terraform output -raw talosconfig >~/.talos/config
    echo "Talosconfig file is copied to ~/.talos/config"
fi
