# Demo application for learning Consul on Kubernetes

This repository contains

To deploy the app run the following scripts in order. This assumes you have a
Kubernetes cluster available. This repository has been tested with Minikube and Kind.

## Download Official Consul Helm chart

`helm repo add hashicorp https://helm.releases.hashicorp.com`

## Minimal Consul install

`helm install -f minimal-consul-values.yaml consul hashicorp/consul --wait`

## Deploy example workload

`kubectl apply -f app`

## View application

`kubectl port-forward deploy/frontend 8080:80`
