[See Rancher Federal Docs](https://github.com/rancherfederal/rke2-aws-tf)

### Deploy RKE2 to AWS.

### Pre Reqs
- `terrform`
- `awscli`
- `kubectl`

```
# update varibles.tf 
terraform init
terraform apply
export KUBECONFIG="$PWD"/rke2.yaml
```
Kubeconfig is dumped into working directory as `rke2.yaml`


### Optional storage provider options. AWS EBS CSI is installed by default.

For Local-Path Storage
```
kubectl patch storageclass ebs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
For Longhorn
```
kubectl patch storageclass ebs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.2/deploy/longhorn.yaml
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
