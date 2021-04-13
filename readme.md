[See Rancher Federal Docs](https://github.com/rancherfederal/rke2-aws-tf)

### Deploy RKE2 to AWS.

### Pre Reqs
- `terrform`
- `awscli`
- `kubectl`
- `helm` v3

```
cd ./terraform
# update varibles.tf 
terraform init
terraform apply
```
Kubeconfig is dumped into working directory (`./terraform`) as `rke2.yaml`
```
export KUBECONFIG="$PWD"/rke2.yaml
```
For Local-Path Storage
```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
