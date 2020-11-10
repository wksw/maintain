#!/bin/bash

# 使用kubectl升级部署在kubernetes中的服务

SCRIPT_PATH=$(cd $(dirname $0);pwd)

# 项目路径
PROJECT_PATH=${1:-"$SCRIPT_PATH/../../.."}
# 部署目录
MANIFESTS_PATH=$PROJECT_PATH/manifests

# 加载环境变量
. $SCRIPT_PATH/.env
. $MANIFESTS_PATH/.env
. $SCRIPT_PATH/../scripts/paasport.sh > /dev/null
. $SCRIPT_PATH/kube.sh

# 降级旧版本
if [ "$DECREASE_OLD_VERSION" == "true" ];then
    for hpa in $(kubectl get hpa -n $NAMESPACE |grep $SERVICE_NAME|awk '{print $1}')
    do
        if [ "$hpa" != "${SERVICE_NAME}-${VERSION//./}" ];then
            echo "decrease hpa '$hpa'"
            kubectl patch hpa -n $NAMESPACE $hpa -p '{"spec":{"maxReplicas":'${REPLICAS}',"minReplicas":1}}'
        fi
    done
fi

# 等待新版本起来， 防止只有一个版本的时候服务中断
while true
do
    pod_ready=$(kubectl get pods -n $NAMESPACE|grep ${SERVICE_NAME}-${VERSION//./}|awk '{print $2}'|head -n 1)
    total=$(echo $pod_ready|awk -F '/' '{print $2}')
    running=$(echo $pod_ready|awk -F '/' '{print $1}')
    echo "waiting pods start $running/$total"
    if [ "$total" == "$running" ];then
        break
    fi
    sleep 3
done

last_version=$VERSION
# 被保留的旧版本
hold_versions="$last_version"
while [ ${MAX_VERSIONS} -gt 1 ] 
do
    last_version=$(compute_pre_version ${last_version})
    hold_versions="$hold_versions ${last_version}"
    MAX_VERSIONS=$((MAX_VERSIONS-1)) 
done

# 删除旧版本
if [ "$DELETE_OLD_VERSION" == "true" ];then
    for version in $(kubectl get deployment -n $NAMESPACE -o custom-columns=NAME:.metadata.name,VERSION:.metadata.labels.version|grep $SERVICE_NAME |awk '{print $2}')
    do
        exist=false
        for hold_version in $hold_versions
        do
             if [ "$version" == "$hold_version" ];then
                exist=true
                break           
            fi
        done
        if [ "$exist" == "false" ];then
            delete_version $version
        fi
    done
fi