[See Rancher Federal Docs](https://github.com/rancherfederal/rke2-aws-tf)

Deploy RKE2 to AWS.

```
cd ./terraform
# update varibles.tf 
terraform init
terraform apply
```
Kubeconfig is dumped into working directory (`./terraform`) as `rke2.yaml`