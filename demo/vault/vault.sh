#!/bin/bash
set -v

# Clone the repo
rm -rf ./vault-helm
git clone https://github.com/hashicorp/vault-helm.git
cd vault-helm; git checkout 9d92922c9dc1500642278b172a7150c32534de0b; cd ..
helm install vault -f ./values.yaml ./vault-helm

sleep 60s

nohup kubectl port-forward service/consul-consul-ui 8500:80 --pod-running-timeout=10m &
nohup kubectl port-forward service/vault 8200:8200 --pod-running-timeout=10m &

echo ""
echo -n "Your Vault UI is at: http://localhost:8200"

open http://localhost:8200
