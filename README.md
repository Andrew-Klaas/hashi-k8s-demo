# k8s consul/vault/transit-app/mariadb demo
Software requirements (on your laptop):

```git curl jq kubectl(v1.11 or greater) helm(v2.14.3 or greater) consul vault```

## Setup
0. Set your GCP creds. I've done mine via environment variables
https://www.terraform.io/docs/providers/google/provider_reference.html

If using TFE, use the GOOGLE_CREDENTIALS environment variable. Also the JSON credential data is required to all be on one line. Just modify in a text editor before adding to TFE.
```bash
GOOGLE_CREDENTIALS: {"type": "service_account","project_id": "klaas","private_key_id":.......... 
````
1. Fill out terraform.tfvars with your values

2. plan/apply
```bash
terraform apply --auto-approve;
```

3. Go into GCP console and copy the command for  "connecting" to your k8s cluster. The command is shown in the Terraform output.
```bash
gcloud container clusters get-credentials your-k8s-cluster --zone us-east1-b --project your_project
```

4. Deploy Consul/Vault/Mariadb/Python-transit-app. This takes a minute or two as there are a bunch of sleeps setup in the script. We also need to pass the "private_ip" variable to the script. Grab the variable comes from the Terraform output. This allows the K8s Consul "datacenter" to wan join the VM consul "datacenter".
```bash
cd demo
./full_stack_deploy.sh 10.128.0.29
```
cat that script if you want to see how to deploy each of the above by hand/manually.


## Teardown
```bash
demo/cleanup.sh
```

## UI
Refresh your browser tab when they initally open up. They are started by nohup commands using kubectl port-forward. see demo/vault/vault.sh and demo/consul/consul.sh
```bash
#Consul
http://localhost:8500

#Vault
http://localhost:8200
```

## Consul Connect
use the "f-connect" branch to run this demo using Consul Connect.