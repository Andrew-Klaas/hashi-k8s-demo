#!/bin/bash

echo "Installing Consul from Helm chart repo..."
git clone https://github.com/hashicorp/consul-helm.git
helm install --name=consul -f ./values.yaml ./consul-helm

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

sleep 30s

nohup kubectl port-forward service/consul-consul-ui 8500:80 --pod-running-timeout=1m &

consul intention create -replace -deny "*" "*"
consul intention create -replace -allow k8s-transit-app vault
consul intention create -replace -allow k8s-transit-app mariadb

echo ""
echo -n "Your Consul UI is at: http://localhost:8500"

open http://localhost:8500