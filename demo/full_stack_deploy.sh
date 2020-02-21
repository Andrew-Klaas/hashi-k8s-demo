#!/bin/bash
set -v

# Not required in Helm3 (Required for Helm2)
#cd tiller
#./helm-init.sh
#cd ..
#kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=helm -o name -n kube-system) -n kube-system
#sleep 1s
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

cd consul
./consul.sh
cd ..
kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=consul -o name)
sleep 1s

cd mariadb
./mariadb.sh
cd ..
kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=mariadb -o name)
sleep 1s

cd vault
./vault.sh
sleep 30s
./vault_setup.sh
cd ..
sleep 5s

kubectl apply -f ./application_deploy_sidecar
kubectl get svc k8s-transit-app

echo ""
echo "use the following command to get your demo IP, port is 5000"
echo "$ kubectl get svc k8s-transit-app"
