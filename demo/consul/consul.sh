#!/bin/bash
set -v

echo "Installing Consul from Helm chart repo..."
rm -rf ./consul-helm
git clone https://github.com/hashicorp/consul-helm.git
cd consul-helm; git checkout a70e71ea57f65d32ab725db573a7c159b37fb7cd ; cd ..
helm install consul -f ./values.yaml ./consul-helm

sleep 10s

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"consul": ["$(kubectl get svc consul-consul-dns -o jsonpath='{.spec.clusterIP}')"]}
EOF

sleep 10s

nohup kubectl port-forward service/consul-consul-ui 8500:80 --pod-running-timeout=10m &

echo ""
echo -n "Your Consul UI is at: http://localhost:8500"

open http://localhost:8500
