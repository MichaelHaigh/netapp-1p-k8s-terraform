#!/bin/bash
set -euo pipefail

BACKEND_NAME="backend-${anf_capacity_pool}"

download_trident() {
        echo "    --> downloading and unpacking Trident"
        wget -nc https://github.com/NetApp/trident/releases/download/v${aks_trident_version}/trident-installer-${aks_trident_version}.tar.gz
        tar -xf trident-installer-${aks_trident_version}.tar.gz
}

install_trident() {
        echo "    --> installing Trident via Helm"
        helm install trident -n trident --create-namespace trident-installer/helm/trident-operator*.tgz
}

create_backend_secret() {
        echo "    --> creating Trident backend secret"
        kubectl -n trident create secret generic backend-tbc-anf-secret --from-literal=clientID=${sp_creds_app_id} --from-literal=clientSecret="${sp_creds_password}"
}

create_backend() {
        echo "    --> creating Trident backend"
        kubectl apply -f - <<EOF
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: ${BACKEND_NAME}
  namespace: trident
spec:
  version: 1
  storageDriverName: azure-netapp-files
  subscriptionID: ${sp_creds_subscription}
  tenantID: ${sp_creds_tenant}
  location: ${azr_region}
  serviceLevel: ${anf_service_level}
  capacityPools:
  - "${anf_capacity_pool}"
  credentials:
    name: backend-tbc-anf-secret
  virtualNetwork: ${aks_network_name}
  subnet: ${aks_subnet_name}
EOF
}

create_storageclass() {
        echo "    --> updating default storage class and creating ANF storage class and volume snapshot class"
        kubectl patch storageclass default -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
        cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
allowVolumeExpansion: true
metadata:
  name: azure-netapp-files-${anf_service_level_lc}
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
parameters:
  backendType: azure-netapp-files
  fsType: nfs
provisioner: csi.trident.netapp.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-trident-snapclass
driver: csi.trident.netapp.io
deletionPolicy: Delete
EOF
}

##################
# Get Kubeconfig #
##################
echo "--> getting cluster kubeconfig via az"
az aks get-credentials --resource-group ${aks_rg_name} --name ${aks_cluster_name} --overwrite-existing

###################
# Install Trident #
###################
echo "--> determining if Trident needs to installed"
set +e
kubectl get ns trident >> /dev/null 2>&1
NS_EXISTS=$?
set -e
if [[ $NS_EXISTS -eq 0 ]]; then
        echo "    --> Trident namespace already exists, skipping installation"
else
        download_trident
        install_trident
        echo "--> sleeping for 2 minutes for Trident pods to start up"
        sleep 120
fi

##################
# Create Backend #
##################
echo "--> determining if Trident backend needs to be created"
set +e
kubectl -n trident get TridentBackendConfig ${BACKEND_NAME} >> /dev/null 2>&1
BACKEND_EXISTS=$?
set -e
if [[ $BACKEND_EXISTS -eq 0 ]]; then
        echo "     --> Trident backend already exists, skipping creation"
else
        create_backend_secret
        create_backend
        echo "--> sleeping for 10 seconds"
        sleep 10
fi

#######################
# Create StorageClass #
#######################
echo "--> determining if ANF storage class needs to be created"
set +e
kubectl get sc azure-netapp-files-${anf_service_level_lc} >> /dev/null 2>&1
SC_EXISTS=$?
set -e
if [[ $SC_EXISTS -eq 0 ]]; then
        echo "     --> ANF storage class already exists, skipping creation"
else
        create_storageclass
fi
