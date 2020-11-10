#!/bin/bash

# 使用kubectl卸载部署在kubernetes中的服务

SCRIPT_PATH=$(cd $(dirname $0);pwd)

# 项目路径
PROJECT_PATH=${1:-"$SCRIPT_PATH/../../.."}
# 部署目录
MANIFESTS_PATH=$PROJECT_PATH/manifests

# 加载环境变量
. $MANIFESTS_PATH/.env
. $SCRIPT_PATH/.env
. $SCRIPT_PATH/kube.sh

delete_version $VERSION