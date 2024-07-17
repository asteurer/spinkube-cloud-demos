# Creating an AKS Cluster with Terraform

```sh
terraform init
terraform plan -var-file terraform.tfvars.tmpl
terraform apply -var-file terraform.tfvars.tmpl
```

> Note: you can add a prefix to the name of your cluster by adding `-var prefix=myPrefix`

Once complete, get the kubernetes config file with `terraform output kube_config` and put it in a location accessible by `kubectl` (`$HOME/.kube/config` by default).
