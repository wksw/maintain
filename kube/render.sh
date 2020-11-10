#!/bin/bash

# 模版渲染

render_floder() {
    if [ ! -d $1 ];then
        echo "floder '$1' not found"
        return 1
    fi
    for file in $(find $1 -type f)
    do
        render_file $file
        if [ $? -ne 0 ];then
            return 1
        fi 
    done
}

render_file() {
    if [ ! -f $1 ];then
        echo "file '$1' not found"
        return 1
    fi
    for env in $(env)
    do
        key=$(echo $env |awk -F '=' '{print $1}')
        value=$(echo $env|awk -F '=' '{print $2}')
        if [ -n "$key" ];then
            sed -i "s#{{ ${key} }}#${value}#g" "$1"
            if [ $? -ne 0 ];then
                echo "render file '$1' fail"
                return 1
            fi
        fi
    done
}