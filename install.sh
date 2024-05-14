#!/bin/bash

# 创建 update_geosite.sh 文件并赋予执行权限
cat << 'EOF' > /usr/local/bin/update_geosite.sh
#!/bin/bash

# 获取所有运行中的容器ID
containers=$(docker ps -q)

# 循环遍历每个容器
for container in $containers; do
    # 获取容器的镜像名
    image=$(docker inspect --format '{{.Config.Image}}' $container)

    # 检查镜像是否是 vaxilu/soga:latest
    if [[ "$image" == "vaxilu/soga:latest" ]]; then
        # 获取挂载的目录
        mounts=$(docker inspect --format '{{range .HostConfig.Binds}}{{println .}}{{end}}' $container)

        echo "容器 $container 的挂载信息：$mounts"

        mount=""

        # 遍历挂载信息，查找目标挂载目录
        while IFS= read -r line; do
            source=$(echo $line | cut -d':' -f1)
            destination=$(echo $line | cut -d':' -f2)

            if [[ "$destination" == "/etc/soga/" ]]; then
                mount=$source
                break
            fi
        done <<< "$mounts"

        echo "容器 $container 的挂载目录：$mount"

        # 检查是否成功获取挂载目录
        if [[ -n "$mount" ]]; then
            # 下载最新的 geosite.dat 文件
            wget -O "$mount/geosite.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
            
            # 下载最新的 geoip.dat 文件
            wget -O "$mount/geoip.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

            # 重启容器
            docker restart $container
        else
            echo "未找到容器 $container 的挂载目录"
        fi
    fi
done
EOF

chmod +x /usr/local/bin/update_geosite.sh

# 设置 cron 任务，每天凌晨2点运行 update_geosite.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/update_geosite.sh") | crontab -
