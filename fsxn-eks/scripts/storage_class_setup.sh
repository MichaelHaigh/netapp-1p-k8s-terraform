#!/bin/bash
set -euo pipefail

FSXN_NAS_SC_NAME="fsx-netapp-file"
FSXN_SAN_SC_NAME="fsx-netapp-block"
BACKEND_NAME_PREFIX="backend-fsx-ontap"

volume_snapshot() {
        kubectl -n kube-system apply -f ${vscrd_release}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
        kubectl -n kube-system apply -f ${vscrd_release}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
        kubectl -n kube-system apply -f ${vscrd_release}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
        sleep 15
        kubectl -n kube-system apply -f ${vscrd_release}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
        kubectl -n kube-system apply -f ${vscrd_release}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
        sleep 15
}

create_backend() {
        suffix=$1
        echo "    --> creating ${suffix} Trident backend"
        kubectl apply -f - <<EOF
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: ${BACKEND_NAME_PREFIX}-${suffix}
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-${suffix}
  svm: ${eks_svm_name}
  aws:
    fsxFilesystemID: ${fsx_filesystem_id}
  credentials:
    name: ${svm_password}
    type: awsarn
EOF
}

create_block_storageclass() {
        echo "    --> creating FSxN Block storage class"
        cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${FSXN_SAN_SC_NAME}
provisioner: csi.trident.netapp.io
parameters:
  backendType: 'ontap-san'
  fsType: 'ext4'
allowVolumeExpansion: True
EOF
}

create_file_storageclass() {
        echo "    --> updating default storage class and creating FSxN File storage class"
        kubectl patch storageclass gp2 -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
        cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${FSXN_NAS_SC_NAME}
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: csi.trident.netapp.io
parameters:
  backendType: 'ontap-nas'
  fsType: 'ext4'
allowVolumeExpansion: True
EOF
}

create_helm_repo() {
        echo "    --> creating EKS Helm Repo"
        helm repo add --force-update eks https://aws.github.io/eks-charts
        helm repo update
}

create_loadbalancer() {
        echo "    --> creating AWS LoadBalancer Controller"
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${eks_lb_arn}
EOF
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
            --set clusterName=${eks_cluster_name} --set serviceAccount.create=false \
            --set serviceAccount.name=aws-load-balancer-controller
}

##################
# Get Kubeconfig #
##################
echo "--> getting cluster kubeconfig via aws"
aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}

######################################
# Install Volume Snapshot Components #
######################################
echo "--> installing volume snapshot components"
volume_snapshot

###########################
# Create Trident Backends #
###########################
for suffix in "san" "nas"; do
        echo "--> determining if Trident ${suffix} backend needs to be created"
        set +e
        kubectl -n trident get TridentBackendConfig ${BACKEND_NAME_PREFIX}-${suffix} >> /dev/null 2>&1
        BACKEND_EXISTS=$?
        set -e
        if [[ $BACKEND_EXISTS -eq 0 ]]; then
                echo "     --> Trident ${suffix} backend already exists, skipping creation"
        else
                create_backend "${suffix}"
                echo "--> sleeping for 10 seconds"
                sleep 10
        fi
done

#############################
# Create Block StorageClass #
#############################
echo "--> determining if FSxN Block storage class needs to be created"
set +e
kubectl get sc ${FSXN_SAN_SC_NAME} >> /dev/null 2>&1
SC_EXISTS=$?
set -e
if [[ $SC_EXISTS -eq 0 ]]; then
        echo "     --> FSxN Block storage class already exists, skipping creation"
else
        create_block_storageclass
fi

############################
# Create File StorageClass #
############################
echo "--> determining if FSxN File storage class needs to be created"
set +e
kubectl get sc ${FSXN_NAS_SC_NAME} >> /dev/null 2>&1
SC_EXISTS=$?
set -e
if [[ $SC_EXISTS -eq 0 ]]; then
        echo "     --> FSxN File storage class already exists, skipping creation"
else
        create_file_storageclass
fi

######################################
# Create AWS LoadBalancer Controller #
######################################
echo "--> determining if AWS LoadBalancer Controller needs to be created"
set +e
helm repo list | grep ^eks >> /dev/null 2>&1
HR_EXISTS=$?
kubectl -n kube-system get serviceaccount aws-load-balancer-controller >> /dev/null 2>&1
SA_EXISTS=$?
set -e
if [[ $SA_EXISTS -eq 0 ]]; then
        echo "     --> AWS LoadBalancer Controller already exists, skipping creation"
else
        if [[ $HR_EXISTS -eq 0 ]]; then
                echo "     --> EKS Helm Repo exists, skipping creation"
        else
                create_helm_repo
        fi
        create_loadbalancer
fi
