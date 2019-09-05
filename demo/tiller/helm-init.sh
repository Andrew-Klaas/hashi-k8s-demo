    
#!/bin/bash

# Create an account for Tiller and grant it permissions.
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

# Let Helm deploy and configure the Tiller service.
helm init --service-account tiller
