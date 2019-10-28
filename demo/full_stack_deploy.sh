#!/bin/bash
set -v

cd tiller
./helm-init.sh
cd ..

kubectl wait --timeout=120s --for=condition=Ready $(kubectl get pod --selector=app=helm -o name -n kube-system) -n kube-system
sleep 1s

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
sleep 60s
./vault_setup.sh
cd ..

kubectl apply -f ./application_deploy
kubectl get svc k8s-transit-app

echo ""
echo "use the following command to get your demo IP, port is 5000"
echo "$ kubectl get svc k8s-transit-app"
