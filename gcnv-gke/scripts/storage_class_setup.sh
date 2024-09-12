#!/bin/bash
set -euo pipefail

BACKEND_NAME="backend-${gcnv_storage_pool}"

download_trident() {
        echo "    --> downloading and unpacking Trident"
        wget -nc https://github.com/NetApp/trident/releases/download/v${gke_trident_version}/trident-installer-${gke_trident_version}.tar.gz
        tar -xf trident-installer-${gke_trident_version}.tar.gz
}

install_trident() {
        echo "    --> installing Trident via Helm"
        helm install trident -n trident --create-namespace trident-installer/helm/trident-operator*.tgz
}

create_backend_secret() {
        echo "    --> creating Trident backend secret"
        kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${BACKEND_NAME}-secret
  namespace: trident
type: Opaque
stringData:
  private_key_id: ${sa_creds_private_key_id}
  private_key: |
    ${sa_creds_private_key}
EOF
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
  storageDriverName: google-cloud-netapp-volumes
  projectNumber: '${gcp_project_number}'
  location: ${gcp_region}
  serviceLevel: ${gcnv_service_level}
  storagePools:
  - ${gcnv_storage_pool}
  apiKey:
    type: ${sa_creds_type}
    project_id: ${sa_creds_project_id}
    auth_provider_x509_cert_url: ${sa_creds_auth_provider}
    auth_uri: ${sa_creds_auth_uri}
    client_email: ${sa_creds_client_email}
    client_id: '${sa_creds_client_id}'
    client_x509_cert_url: ${sa_creds_client_cert_url}
    token_uri: ${sa_creds_token_uri}
  credentials:
    name: ${BACKEND_NAME}-secret
EOF
}

create_storageclass() {
        echo "    --> updating default storage class and creating GCNV storage class and volume snapshot class"
        kubectl patch storageclass standard-rwo -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
        cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
allowVolumeExpansion: true
metadata:
  name: 'netapp-gcnv-${gcnv_service_level}'
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
parameters:
  backendType: google-cloud-netapp-volumes
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
echo "--> getting cluster kubeconfig via gcloud"
gcloud container clusters get-credentials ${gke_name} --region ${gke_zone}

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
echo "--> determining if GCNV storage class needs to be created"
set +e
kubectl get sc netapp-gcnv-${gcnv_service_level} >> /dev/null 2>&1
SC_EXISTS=$?
set -e
if [[ $SC_EXISTS -eq 0 ]]; then
        echo "     --> GCNV storage class already exists, skipping creation"
else
        create_storageclass
fi
