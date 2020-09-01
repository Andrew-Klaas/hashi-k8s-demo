#!/bin/bash
set -v

nohup kubectl port-forward service/vault 8200:8200 --pod-running-timeout=10m &
nohup kubectl port-forward service/consul-consul-ui 8500:80 --pod-running-timeout=10m &

export VAULT_ADDR=http://127.0.0.1:8200
export CONSUL_ADDR=http://127.0.0.1:8500

cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

curl \
  --silent \
  --request PUT \
  --data '{"secret_shares": 1, "secret_threshold": 1}' \
  ${VAULT_ADDR}/v1/sys/init | tee \
  >(jq -r '.root_token' > /tmp/root-token) \
  >(jq -r '.keys[0]' > /tmp/unseal-key)

curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/unseal-key -d $(cat /tmp/unseal-key)
curl -sfX PUT 127.0.0.1:8500/v1/kv/service/vault/root-token -d $(cat /tmp/root-token)

vault operator unseal $(cget unseal-key)
export ROOT_TOKEN=$(cget root-token)
vault login $ROOT_TOKEN


#Create admin user
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault_admin -
vault auth enable userpass
vault write auth/userpass/users/vault password=vault policies=vault_admin

#################################
# Transit-app-example Vault setup
#################################

vault login -method=userpass username=vault password=vault

# Enable our secret engine
vault secrets enable -path=lob_a/workshop/database database
vault secrets enable -path=lob_a/workshop/kv kv
vault write lob_a/workshop/kv/transit-app-example username=vaultadmin password=vaultadminpassword


# Configure our secret engine
vault write lob_a/workshop/database/config/ws-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mariadb.default.svc.cluster.local:3306)/" \
    allowed_roles="workshop-app" \
    username="root" \
    password="vaultadminpassword"

# Create our role
vault write lob_a/workshop/database/roles/workshop-app-long \
    db_name=ws-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON *.* TO '{{name}}'@'%';" \
    default_ttl="12h" \
    max_ttl="24h"

vault write lob_a/workshop/database/roles/workshop-app \
    db_name=ws-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL ON *.* TO '{{name}}'@'%';" \
    default_ttl="12h" \
    max_ttl="24h"

vault secrets enable -path=lob_a/workshop/transit transit
vault write -f lob_a/workshop/transit/keys/customer-key
vault write -f lob_a/workshop/transit/keys/archive-key

#transform
# vault secrets enable transform
# vault write transform/role/ssns transformations=ssn-fpe
# vault write transform/transformation/ssn-fpe \
#   type=fpe \
#   template=builtin/socialsecuritynumber \
#   tweak_source=internal \
#   allowed_roles=ssns

#ciphertext=$(vault write transform/encode/ssns value=123456789)
#vault write transform/decode/ssns value=$ciphertext


#Create Vault policy used by Nomad job
cat << EOF > transit-app-example.policy
path "lob_a/workshop/database/creds/workshop-app" {
    capabilities = ["read", "list", "create", "update", "delete"]
}
path "lob_a/workshop/database/creds/workshop-app-long" {
    capabilities = ["read", "list", "create", "update", "delete"]
}
path "lob_a/workshop/transit/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
}
path "lob_a/workshop/kv/*" {
    capabilities = ["read", "list", "create", "update", "delete"]
}
path "*" {
    capabilities = ["read", "list", "create", "update", "delete"]
}
EOF
vault policy write transit-app-example transit-app-example.policy


kubectl create serviceaccount vault-auth

kubectl apply --filename vault-auth-service-account.yaml

# Set VAULT_SA_NAME to the service account you created earlier
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}" | awk '{ print $1 }')

# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

export K8S_HOST="https://kubernetes.default.svc:443"
vault auth enable kubernetes

vault write auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="$K8S_HOST" \
        kubernetes_ca_cert="$SA_CA_CRT"

vault write auth/kubernetes/role/example \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default \
        policies=transit-app-example \
        ttl=72h

#go-movies-app
vault write auth/kubernetes/role/go-movies-app \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default \
        policies=transit-app-example \
        ttl=72h

#transit setup
vault secrets enable transit
vault write -f transit/keys/my-key

##database setup
vault secrets enable database

vault write database/config/my-postgresql-database \
plugin_name=postgresql-database-plugin \
allowed_roles="my-role" \
connection_url="postgresql://{{username}}:{{password}}@pq-postgresql-default.service.consul:5432/movies?sslmode=disable" \
username="postgres" \
password="password"

vault write database/roles/my-role \
db_name=my-postgresql-database \
creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
ALTER USER \"{{name}}\" WITH SUPERUSER;" \
default_ttl="1h" \
max_ttl="24h"

vault read database/creds/my-role