#!/bin/sh



# kube-apiserver haproxy IP
export KUBE_APISERVER_PROXY="https://10.138.232.140:19999"
export HOST_IP="10.138.48.164"
export BOOTSTRAP_TOKEN="dec0ac166ff2dbf8eab068ca47decaa4"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="10.254.0.2"
# 集群 DNS 域名
export CLUSTER_DNS_DOMAIN="cluster.local."

# set-cluster
../bin/kubernetes/client/kubectl config set-cluster kubernetes \
  --certificate-authority=../ca/cluster-root-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER_PROXY} \
  --kubeconfig=./kubelet00.conf

# set-credentials
../bin/kubernetes/client/kubectl config set-credentials system:node:node00 \
  --client-certificate=../ca/kubernetes-rbac-kubelet-node-00-ca.pem \
  --client-key=../ca/kubernetes-rbac-kubelet-node-00-ca-key.pem \
  --embed-certs=true \
  --kubeconfig=./kubelet00.conf

# set-context
../bin/kubernetes/client/kubectl config set-context system:node:node00@kubernetes \
  --cluster=kubernetes \
  --user=system:node:node00 \
  --kubeconfig=./kubelet00.conf

# set default context
../bin/kubernetes/client/kubectl config use-context system:node:node00@kubernetes --kubeconfig=./kubelet00.conf

# 配置集群
../bin/kubernetes/client/kubectl config set-cluster kubernetes \
  --certificate-authority=../ca/cluster-root-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER_PROXY} \
  --kubeconfig=./bootstrap.kubeconfig

# 配置客户端认证

../bin/kubernetes/client/kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=./bootstrap.kubeconfig


# 配置关联

../bin/kubernetes/client/kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=./bootstrap.kubeconfig


# 配置默认关联
../bin/kubernetes/client/kubectl config use-context default --kubeconfig=./bootstrap.kubeconfig

# 启动kubelet
../bin/kubernetes/server/kubelet \
--api-servers==${KUBE_APISERVER_PROXY} \
--address=${HOST_IP} \
--hostname-override=${HOST_IP} \
--pod-infra-container-image=gcr.io/google_containers/pause-amd64:3.0 \
--experimental-bootstrap-kubeconfig=./bootstrap.kubeconfig \
--kubeconfig=./kubelet00.conf \
--require-kubeconfig=true \
--cert-dir=./kubelet-ca \
--cluster-dns=${CLUSTER_DNS_SVC_IP} \
--cluster-domain=${CLUSTER_DNS_DOMAIN} \
--pod-manifest-path=./kubernetes-manifests \
--network-plugin=cni \
--hairpin-mode promiscuous-bridge \
--allow-privileged=true \
--authorization-mode=AlwaysAllow \
--serialize-image-pulls=false \
--logtostderr=true \
--v=0 \


