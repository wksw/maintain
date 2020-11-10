> 公共维护脚本

```shell
├── kube/                      // k8s相关
    ├── .env                   // k8s环境变量相关
    ├── kube.sh                // k8s通用脚本
    ├── kubectl_delete.sh      // 使用kubectl卸载部署
    ├── kubectl_deploy.sh      // 使用kubectl部署
    ├── kubectl_rollback.sh    // 部署回滚
    ├── kubectl_upgrade.sh     // 部署升级
├── scripts/                   // 通用脚本
    ├── paasport.sh            // 其中包含版本计算
    ├── parse_route.py         // 版本计算，路由解析
    ├── route.yaml             // parse_route.py的配置文件
├── Makefile                   // 通用makefile，包含一些配置
```

