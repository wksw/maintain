#-*- coding:utf8 -*-

'''
解析依赖关系为router路由表和文档
'''

import argparse
import commands
import yaml
import os
import  sys
reload(sys)                                 
sys.setdefaultencoding( "utf-8" ) 

root_dir = os.path.dirname(os.path.realpath(__file__))
version_script = os.path.join(root_dir, "paasport.sh")


'''
解析成md表格
request:
    data: 要解析的数据
response:
    table: 生成的表格
'''
def parse_to_md(input):
    if input["services"].has_key("gateway-microservice") and input["services"]["gateway-microservice"].has_key("version"):
        input["version"] = input["services"]["gateway-microservice"]["version"]
        
    md = "### v{}\n----\n\n".format(input["version"] if input.has_key("version") else "")
    md += "| 服务 "
    data = input["services"] if input.has_key("services") else input
    service_keys = sorted(data.keys())
    # 生成头
    for sv in service_keys:
        md += "| {} ".format(data[sv]["name"] if data[sv].has_key("name") else sv)
    md += "|\n|:-----:"
    for sv in service_keys:
        md += "|:-----:"
    md += "|\n"
    # 生成依赖关系
    for sv in service_keys:
        md += "| {} ".format(data[sv]["name"] if data[sv].has_key("name") else sv)
        for dp in service_keys:
            if sv == dp and data[sv].has_key("version"):
                version = data[sv]["version"]
                version_str = version.replace(".", "")
                service_name = data[sv]["name"] if data[sv].has_key("name") else sv
                md += "| [v{}](./{}/#v{}) ".format(version,service_name, version_str)
                continue
            if data[sv].has_key("dependices"):
                if data[sv]["dependices"].has_key(dp) and data[sv]["dependices"][dp].has_key("version"):
                    version = data[sv]["dependices"][dp]["version"]
                    version_str = version.replace(".", "")
                    service_name = data[dp]["name"] if data[dp].has_key("name") else dp
                    md += "| [v{}](./{}/#v{}) ".format(version,service_name, version_str)
                else:
                    md += "| x "
            else:
                md += "| x "

        md += "|\n"
    return md
    


'''
解析成服务路由表
request:
    data: 要解析的数据
    service: 要获取的服务的路由表
response:
    data: 生成的路由表
'''
def parse_to_route(input, service_name):
    data = input["services"] if input.has_key("services") else input 
    route = '''---
servicecomb:
    routeRule:'''
    if not data.has_key(service_name):
        return ""
    if not data[service_name].has_key("dependices"):
        return ""
    for dp in data[service_name]["dependices"]:
        if data[service_name]["dependices"][dp].has_key("version"):
            current_version = data[service_name]["dependices"][dp]["version"]
            status, last_version = commands.getstatusoutput("/bin/sh -c '. {} >/dev/null && compute_pre_version {}'".format(version_script, current_version))
            if status == 0 and last_version:
                route += '''
        {}: |
            - precedence: 100
              route:
              - tags:
                    version: {}
            - precedence: 1
              route:
              - tags:
                    version: {}'''.format(dp, current_version, last_version)
    return route

'''
获取谁依赖于该服务
request:
    data: 要解析的数据
    service_name: 要依赖的服务
response:
    services: 依赖于该服务的服务列表
'''
def get_who_dependice(data, service_name):
    services = []
    for service in data["services"].keys():
        if data["services"][service].has_key("dependices") and service_name in data["services"][service]["dependices"].keys():
            services.append(service)
    return services

'''
解析依赖关系
request: 
    data: 要解析的数据
response:
    data: 解析后的数据
'''
def parse(data):
    for service_name in data["services"].keys():
        data = parse_dependice(data, service_name)
    return data

def parse_dependice(data, service_name):
    # print "start parse service '{}'".format(service_name)
    # print " dependice services '{}'".format(get_who_dependice(data, service_name))
    for dependice in get_who_dependice(data, service_name):
        # 如果所依赖的服务版本和本版本不一致则将所依赖的服务的版本修改为本版本
        if data["services"][dependice]["dependices"][service_name].has_key("version") and data["services"][service_name].has_key("version"):
            if data["services"][dependice]["dependices"][service_name]["version"] != data["services"][service_name]["version"]:
                # 如果所依赖的服务的版本号发生了变更则所在的服务版本号也应该发生变更
                dependice_upgraded = False
                if data["services"][dependice].has_key("upgraded"):
                    dependice_upgraded = data["services"][dependice]["upgraded"]
                if not dependice_upgraded:
                    status, next_version = commands.getstatusoutput("/bin/sh -c '. {} >/dev/null && compute_next_version {}'".format(version_script, data["services"][dependice]["version"]))
                    if status == 0 and next_version:
                        # print " upgrade service '{}' version to next version '{}'".format(dependice, next_version)
                        data["services"][dependice]["version"] = next_version
                        data["services"][dependice]["upgraded"] = True
                    data = parse_dependice(data, dependice)         
                data["services"][dependice]["dependices"][service_name]["version"] = data["services"][service_name]["version"]
    return data


def get_route_data(yaml_file):
    file = open(yaml_file, 'r')
    data = file.read()
    file.close()
    yaml_data = yaml.load(data,Loader=yaml.Loader)
    return yaml_data

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.description = "生成版本依赖关系或服务路由表"
    parser.add_argument("-o", "--output", help="版本依赖关系表或者服务路由表(table|route|version|latest)", type=str, default="table")
    parser.add_argument("-s", "--service_name",  help="服务名称，当output为route时生效", type=str, default="account-microservice")
    parser.add_argument("-d", "--dependices", help="服务依赖关系文件", type=str, default=os.path.join(root_dir, "route.yaml"))
    args = parser.parse_args()

    output = args.output
    service_name = args.service_name
    dependices_file = args.dependices

    data = get_route_data(dependices_file)
    data = parse(data)

    if output == "table":
        print parse_to_md(data)
    elif output == "route":
        print parse_to_route(data, service_name)
    elif output == "latest":
        for key in data["services"].keys():
            if data["services"][key].has_key("upgraded"):
                data["services"][key]["upgraded"] = False
                # del data[key]["upgraded"]
        with open(os.path.join(root_dir, "./route-latest.yaml"), "w") as f:
            yaml.dump(data, f, allow_unicode=True)
    else:
        print data["services"][service_name]["version"] if data["services"].has_key(service_name) and data["services"][service_name].has_key("version") else ""

