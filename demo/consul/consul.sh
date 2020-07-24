#!/bin/bash
set -v

echo "Installing Consul from Helm chart repo..."
helm install consul hashicorp/consul -f values.yaml --version=0.23.1

kubectl wait --timeout=180s --for=condition=Ready $(kubectl get pod --selector=app=consul -o name)
sleep 1s

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

nohup kubectl port-forward service/consul-consul-ui 8500:80 --pod-running-timeout=10m &
sleep 1s

#Configure ingress gateway to transit/transform app
# consul config write ingress.hcl
# consul config write router.hcl
# consul config write splitter.hcl
# consul config write resolver.hcl

echo ""
echo -n "Your Consul UI is at: http://localhost:8500"

open http://localhost:8500
