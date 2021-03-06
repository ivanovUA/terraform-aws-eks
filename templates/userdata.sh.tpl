#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${cluster_name} \
    --b64-cluster-ca '${base64_cluster_ca}' \
    --apiserver-endpoint ${api_server_url} \
    --kubelet-extra-args "--node-labels=${node_labels} --register-with-taints=${node_taints} ${kubelet_more_extra_args}" \
    --use-max-pods ${use_max_pods}

