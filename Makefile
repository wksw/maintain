# 命令相关(无需修改)
GO_CMD=go
GO_BUILD=GOPROXY=https://mirrors.aliyun.com/goproxy/ GO111MODULE=on CGO_ENABLED=0 GOARCH=amd64 $(GO_CMD) build -ldflags="-s -w" -v
GO_CLEAN=$(GO_CMD) clean
GO_TEST=$(GO_CMD) test

DOCKER_CMD=docker
DOCKER_RUN=$(DOCKER_CMD) run --rm
DOCKER_BUILD=$(DOCKER_CMD) build
DOCKER_PULL=$(DOCKER_CMD) pull
DOCKER_PUSH=$(DOCKER_CMD) push

GIT_CMD=git
GIT_SUBMODULE=$(GIT_CMD) submodule

## 版本号
VERSION=$(shell cat version)

## 项目名称
PROJECT=$(PROJECT_NAME)
ifdef PROJECT_NAME
	PROJECT = $(PROJECT_NAME)
else
	PROJECT = wksw
endif

# 项目配置相关
## 项目名称, 使用下划线防止部署到k8s中出现问题
SERVICENAME=$(SERVICE_NAME)
ifdef SERVICE_NAME
	SERVICENAME = $(SERVICE_NAME)
else
	SERVICENAME = go-chassis-demo
endif

## dockerhub推送镜像地址
DOCKERHUBPUSHHOST=$(REGISTRY_ADDRESS)
ifdef REGISTRY_ADDRESS
	DOCKERHUBPUSHHOST = $(REGISTRY_ADDRESS)
else
	DOCKERHUBPUSHHOST = dockerhub.contoso.com
endif
## dockerhub拉取镜像地址
DOCKERHUBPULLHOST=$(REGISTRY_INTERNAL_ADDRESS)
ifdef REGISTRY_INTERNAL_ADDRESS
	DOCKERHUBPULLHOST = $(REGISTRY_INTERNAL_ADDRESS)
else
	DOCKERHUBPULLHOST = dockerhub.contoso.com
endif

## 命名空间
NAME_SPACE=$(NAMESPACE)
ifdef NAMESPACE
	NAME_SPACE = $(NAMESPACE)
else
	NAME_SPACE = passport
endif

## git仓库地址
GITREPO=$(GIT_REPO)
ifdef GIT_REPO
	GITREPO = $(GIT_REPO)
else
	GITREPO = github.com
endif

## 部署环境，和配置文件后缀相关
DEPLOYENV=$(DEPLOY_ENV)
ifdef DEPLOY_ENV
	DEPLOYENV = $(DEPLOY_ENV)
else
	DEPLOYENV = a
endif

## 编译镜像
BUILDIMAGE=$(BUILD_IMAGE)
ifdef BUILD_IMAGE
	BUILDIMAGE = $(BUILD_IMAGE)
else
	BUILDIMAGE = paasport/chassis_v2.0.2:build_base
endif

## linux环境下包名
SERVICE_NAME_LINUX=$(SERVICENAME)_linux
## mac环境下包名
SERVICE_NAME_MAC=$(SERVICENAME)_mac
## windows环境下包名
SERVICE_NAME_WIN=$(SERVICENAME)_win.exe


all: help

help: ## 显示帮助
	@echo  "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\033[36m\1\\033[m:\2/' | column -c2 -t -s :)"
