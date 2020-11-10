#!/bin/bash -e

usage() {
    echo '
useage: 显示此帮助
compute_next_version <版本号>: 下一个版本号计算
compute_pre_version <版本号>: 上一个版本号计算
    '
}

# 下一个版本计算计算
compute_next_version() {
    version=$1
    # 主版本号.子版本号.修正版本
    master_version=$(echo $version|awk -F '.' '{print $1}')
    child_version=$(echo $version|awk -F '.' '{print $2}')
    fix_version=$(echo $version|awk -F '.' '{print $3}')
    other_version=$(echo $version|cut -d '.' -f4-)

    fix_version=$((fix_version+1))
    # 如果修复版本加1大于10则子版本
    # 则置0并且子版本+1
    if [ $fix_version -gt 10 ];then
        fix_version=0
        child_version=$((child_version+1))
        # 如果子版本+1大于10
        # 则主版本号+1
        if [ $child_version -gt 10 ];then
            child_version=0
            master_version=$((master_version+1))
        fi
    fi
    if [ -n "${other_version}" ];then
        next_version="${master_version}.${child_version}.${fix_version}.${other_version}"
    else
         next_version="${master_version}.${child_version}.${fix_version}"
    fi
    echo $next_version
}

# 上一个版本计算
compute_pre_version() {
    version=$1
    # 主版本号.子版本号.修正版本
    master_version=$(echo $version|awk -F '.' '{print $1}')
    child_version=$(echo $version|awk -F '.' '{print $2}')
    fix_version=$(echo $version|awk -F '.' '{print $3}')
    other_version=$(echo $version|cut -d '.' -f4-)

    fix_version=$((fix_version-1))
    # 如果修复版本减1小于0
    # 则置0并且子版本-1
    if [ $fix_version -lt 0 ];then
        fix_version=10
        child_version=$((child_version-1))
        # 如果子版本+1大于10
        # 则主版本号+1
        if [ $child_version -lt 0 ];then
            child_version=10
            master_version=$((master_version-1))
            if [ $master_version -lt 0 ];then
                master_version=0
            fi
        fi
    fi
    if [ -n "${other_version}" ];then
        pre_version="${master_version}.${child_version}.${fix_version}.${other_version}"
    else
         pre_version="${master_version}.${child_version}.${fix_version}"
    fi
    echo $pre_version
}


echo 'input "usage" to get help'