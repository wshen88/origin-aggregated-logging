#!/bin/bash

set -ex

mkdir -p ${HOME}
ln -s /usr/share/elasticsearch /usr/share/java/elasticsearch

/usr/share/elasticsearch/bin/plugin install io.fabric8/elasticsearch-cloud-kubernetes/${ES_CLOUD_K8S_VER}

# install or build
MANPATH="" source /opt/rh/rh-maven33/enable
set +e
mvn dependency:get -Dartifact=io.fabric8.elasticsearch:openshift-elasticsearch-plugin:${OSE_ES_VER}
res=$?
set -e
if [ 0 -eq $res ]; then
  OSE_ES_URL=io.fabric8.elasticsearch/openshift-elasticsearch-plugin/${OSE_ES_VER}
else
  pushd /tmp/lib/openshift-elasticsearch-plugin
    mvn clean verify -DskipTests
    OSE_ES_URL=file:///tmp/lib/openshift-elasticsearch-plugin/target/releases/openshift-elasticsearch-plugin-${OSE_ES_VER}.zip
  popd
fi
/usr/share/elasticsearch/bin/plugin install $OSE_ES_URL


mkdir /elasticsearch
mkdir -p $ES_CONF
chmod -R og+w $ES_CONF
chmod -R og+w /usr/share/java/elasticsearch ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch
chmod +x /usr/share/elasticsearch/plugins/openshift-elasticsearch/sgadmin.sh

PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $PASSWD
CONF

