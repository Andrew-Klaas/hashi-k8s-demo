# k8s consul/vault/transit-app/mariadb demo

## Setup
0. Set your GCP creds. I've done mine via environment variables
https://www.terraform.io/docs/providers/google/provider_reference.html

1. Fill out terraform.tfvars with your values

2. plan/apply
```bash
terraform apply --auto-approve;
```

3. Go into GCP console and copy the command for  "connecting" to your k8s cluster.
```bash
gcloud container clusters get-credentials your-k8s-cluster --zone us-east1-b --project your_project
```

4. Deploy Consul/Vault/Mariadb/Python-transit-app. This takes a minute or two as there are a bunch of sleeps setup in the script.
```bash
cd demo
./full_stack_deploy.sh
```
cat that script if you want to see how to deploy each of the above by hand/manually.


## Teardown
```bash
demo/cleanup.sh
```