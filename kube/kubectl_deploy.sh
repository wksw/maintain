#!/bin/bash

# 使用kubectl部署到kubernetes集群中的脚本
# 配置文件放在项目目录下的conf_{a,b,rc,rl}格式下的目录下
# 部署模版放在manifests/templates目录下
# 项目私有环境变量放在manifests/.env文件中

SCRIPT_PATH=$(cd $(dirname $0);pwd)

# 项目路径
PROJECT_PATH=${1:-"$SCRIPT_PATH/../../.."}
# 部署目录
MANIFESTS_PATH=$PROJECT_PATH/manifests
# 部署模版目录
TEMPLATES_PATH=$MANIFESTS_PATH/templates

# 加载公共环境变量
. $SCRIPT_PATH/.env

# 加载项目环境变量
if [ -f $MANIFESTS_PATH/.env ];then
    . $MANIFESTS_PATH/.env
fi

# 配置文件路径
CONF_PATH=$PROJECT_PATH/conf_${ENVIRONMENT}

# 配置文件渲染后的路径
CONF_RENDER_PATH=$MANIFESTS_PATH/conf_${ENVIRONMENT}_${VERSION}
# 部署模版渲染后的路径
DEPL_RENDER_PATH=$MANIFESTS_PATH/deploy_${ENVIRONMENT}_${VERSION}

rm -rf "$CONF_RENDER_PATH"
rm -rf "$DEPL_RENDER_PATH"
mkdir -p "$CONF_RENDER_PATH" 
mkdir -p "$DEPL_RENDER_PATH"

# 拷贝配置文件到渲染路径下
if [ -d $CONF_PATH ];then
    for cnf in $(find $CONF_PATH -maxdepth 1 -type f)
    do
        cp $cnf $CONF_RENDER_PATH
    done
fi
# 拷贝部署模版文件到渲染路径下
if [ -n "${K8S_PROVIDER}" ];then
    TEMPLATES_PATH=$TEMPLATES_PATH/$K8S_PROVIDER
fi
if [ ! -d $TEMPLATES_PATH ];then
    echo "floder '$TEMPLATES_PATH' not found"
    exit 1
fi
for yml in $(find $TEMPLATES_PATH -maxdepth 1 -type f -name '*.yaml')
do
    cp $yml $DEPL_RENDER_PATH
done

. $SCRIPT_PATH/render.sh
# 渲染配置文件
render_floder $CONF_RENDER_PATH
if [ $? -ne 0 ];then
    echo "render config templates fail"
    exit 1
fi
# 渲染部署文件
render_floder $DEPL_RENDER_PATH
if [ $? -ne 0 ];then
    echo "render deploy templates fail"
    exit 1
fi

# 创建命名空间
if [ -f $DEPL_RENDER_PATH/namespace.yml ];then
    kubectl apply -f $DEPL_RENDER_PATH/namespace.yml
fi
if [ -f $DEPL_RENDER_PATH/namespace.yaml ];then
    kubectl  apply -f $DEPL_RENDER_PATH/namespace.yaml
fi
# 创建configmap
[ -n "$(kubectl get configmap -n $NAMESPACE|grep ${SERVICE_NAME}-${VERSION})" ] &&  kubectl delete configmap -n ${NAMESPACE} ${SERVICE_NAME}-${VERSION}-config
kubectl create configmap ${SERVICE_NAME}-${VERSION}-config -n ${NAMESPACE} --from-file=$CONF_RENDER_PATH
# 创建服务
kubectl apply -f $DEPL_RENDER_PATH

