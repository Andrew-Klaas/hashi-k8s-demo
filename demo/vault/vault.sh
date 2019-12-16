#!/bin/bash
set -v

# Clone the repo
git clone https://github.com/hashicorp/vault-helm.git
helm install  --name=vault -f ./values.yaml ./vault-helm

sleep 30s

nohup kubectl port-forward service/vault --address 0.0.0.0 8200:8200 --pod-running-timeout=1m &

echo ""
echo -n "Your Vault UI is at: http://localhost:8200"

open http://localhost:8200
