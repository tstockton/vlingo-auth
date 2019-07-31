#!/bin/bash
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

server=$1
if [ -z "${server}" ]; then
  server=localhost
fi

echo "Using ${server} as keycloak server..."
sleep 40
url=http://${server}:8080/auth

export PATH=$PATH:/opt/jboss/keycloak/bin
export VLINGO_PASSWORD=Limahana#kalele

echo 'Authenticating admin...'
kcadm.sh config credentials \
  --server http://${server}:8080/auth \
  --realm master \
  --user ${KEYCLOAK_USER} \
  --password ${KEYCLOAK_PASSWORD}

REALMS="
  vlingo-internal.json
"

for realm in ${REALMS}; do
  echo "Importing realm ${realm}..."
  kcadm.sh create realms -f "${SRCDIR}/${realm}"
done

function generate_user
{
  realm=$1
  username=$2
  password=$3
  roles=$4
  echo "Creating ${username} in ${realm}..."
  id=$( \
    kcadm.sh create users \
      --target-realm ${realm} \
      --set username=${username} \
      --set email=${username} \
      --set firstName=Generated \
      --set lastName=User \
      --set enabled=true \
      --set emailVerified=true \
      --id \
  )
  kcadm.sh set-password \
      --target-realm ${realm} \
      --username ${username} \
      --new-password ${password}

  kcadm.sh add-roles \
      --target-realm ${realm} \
      --uusername ${username} \
      --cclientid realm-management \
      --rolename realm-admin

  for role in ${roles}; do
    kcadm.sh add-roles \
        --target-realm ${realm} \
        --uusername ${username} \
        --rolename ${role}
  done
}

## parentId is the "id" for the realm
#
function set_fixed_key
{
  realm=$1

  kcadm.sh create components \
      -r ${realm} \
      -s name=rsa \
      -s providerId=rsa \
      -s providerType=org.keycloak.keys.KeyProvider \
      -s parentId=${realm} \
      -s 'config.priority=["200"]' \
      -s 'config.enabled=["true"]' \
      -s 'config.active=["true"]' \
      -s 'config.privateKey=["MIICXAIBAAKBgQCrVrCuTtArbgaZzL1hvh0xtL5mc7o0NqPVnYXkLvgcwiC3BjLGw1tGEGoJaXDuSaRllobm53JBhjx33UNv+5z/UMG4kytBWxheNVKnL6GgqlNabMaFfPLPCF8kAgKnsi79NMo+n6KnSY8YeUmec/p2vjO2NjsSAVcWEQMVhJ31LwIDAQABAoGAfmO8gVhyBxdqlxmIuglbz8bcjQbhXJLR2EoS8ngTXmN1bo2L90M0mUKSdc7qF10LgETBzqL8jYlQIbt+e6TH8fcEpKCjUlyq0Mf/vVbfZSNaVycY13nTzo27iPyWQHK5NLuJzn1xvxxrUeXI6A2WFpGEBLbHjwpx5WQG9A+2scECQQDvdn9NE75HPTVPxBqsEd2z10TKkl9CZxu10Qby3iQQmWLEJ9LNmy3acvKrE3gMiYNWb6xHPKiIqOR1as7L24aTAkEAtyvQOlCvr5kAjVqrEKXalj0Tzewjweuxc0pskvArTI2Oo070h65GpoIKLc9jf+UA69cRtquwP93aZKtW06U8dQJAF2Y44ks/mK5+eyDqik3koCI08qaC8HYq2wVl7G2QkJ6sbAaILtcvD92ToOvyGyeE0flvmDZxMYlvaZnaQ0lcSQJBAKZU6umJi3/xeEbkJqMfeLclD27XGEFoPeNrmdx0q10Azp4NfJAY+Z8KRyQCR2BEG+oNitBOZ+YXF9KCpH3cdmECQHEigJhYg+ykOvr1aiZUMFT72HU0jnmQe2FVekuG+LJUt2Tm7GtMjTFoGpf0JwrVuZN39fOYAlo+nTixgeW7X8Y="]' \
      -s 'config.certificate=[]'
}

set_fixed_key vlingo-internal

generate_user vlingo-internal system@kalele.io.com Limahana#Kalele
