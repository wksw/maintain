#!/bin/bash

delete_version() {
    version=$1
    echo "delete version '$version'"
    # 删除configmap
    [ -n "$(kubectl get configmap -n $NAMESPACE |grep ${SERVICE_NAME}-${version})" ] && kubectl delete configmap -n $NAMESPACE ${SERVICE_NAME}-${version}-config
    # 删除hpa
    [ -n "$(kubectl get hpa -n $NAMESPACE |grep ${SERVICE_NAME}-${version//./})" ] && kubectl delete hpa -n $NAMESPACE ${SERVICE_NAME}-${version//./}
    # 删除secret
    [ -n "$(kubectl get secret -n $NAMESPACE |grep ${SERVICE_NAME}-${version})" ] && kubectl delete secret -n $NAMESPACE ${SERVICE_NAME}-${version}-secret
    # 删除deployment
    [ -n "$(kubectl get deployment -n $NAMESPACE |grep ${SERVICE_NAME}-${version//./})" ] && kubectl delete deployment -n $NAMESPACE ${SERVICE_NAME}-${version//./}
}