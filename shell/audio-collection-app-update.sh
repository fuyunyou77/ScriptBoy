#!/bin/bash

# 设置错误处理：遇到错误立即退出，并打印错误信息
set -e

IP_CHANGE=0
GW_CHANGE=0

# 检查参数数量
if [ $# -eq 0 ]; then
    echo "信息: 跳过IP和网关修改"
elif [ $# -eq 3 ] && [ "$1" == "id" ]; then
    echo "信息: 只进行ID替换"
    IP_CHANGE=1
    SEARCH_STR=$2
    REPLACE_STR=$3
elif [ $# -eq 2 ] && [ "$1" == "gw" ]; then
    echo "信息: 只进行网关替换"
    GW_CHANGE=1
    GATEWAY_STR=$2
elif [ $# -eq 5 ] && [ "$1" == "id" ] && [ "$4" == "gw" ]; then
    echo "信息: 进行ID和网关替换"
    IP_CHANGE=1
    GW_CHANGE=1
    SEARCH_STR=$2
    REPLACE_STR=$3
    GATEWAY_STR=$5
else
    echo "Usage: $0 [id <search_string> <replace_string>] [gw <gateway_string>]"
    exit 1
fi

# 验证目录是否存在
echo "检查目标目录..."
required_dirs=("/app" "/run/media/mmcblk1p1" "/etc/init.d")
for dir in "${required_dirs[@]}"; do  # 修复：添加[@]
    if [ ! -d "$dir" ]; then
        echo "严重错误: 必需目录 $dir 不存在"
        exit 1
    fi
done

SEARCH_STR=$1
REPLACE_STR=$2

# 获取脚本所在目录
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 修改config.yml文件（如果存在）
if [ $IP_CHANGE -eq 1 ] || [ $GW_CHANGE -eq 1 ]; then
    echo "开始修改config.yml文件..."
    CONFIG_FILE="$SCRIPT_DIR/config.yml"

    if [ -f "$CONFIG_FILE" ]; then
        # 备份原始文件
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
        echo "信息:备份config文件"

        # 执行ID替换
        if [ $IP_CHANGE -eq 1 ]; then
            lines_to_modify=(2 36 37)
            modified=0

            for line in "${lines_to_modify[@]}"; do
                if sed -i "${line}s/${SEARCH_STR}/${REPLACE_STR}/g" "$CONFIG_FILE"; then
                    echo "第 $line 行修改成功"
                    modified=1
                else
                    echo "错误: 无法修改第 $line 行"
                fi
            done

            if [ $modified -eq 0 ]; then
                echo "警告: 没有找到匹配的内容进行替换"
            fi
        fi

        # 执行网关替换
        if [ $GW_CHANGE -eq 1 ]; then
            if sed -i "s/^    gateway: .*/    gateway: ${GATEWAY_STR}/g" "$CONFIG_FILE"; then
                echo "网关修改成功"
            else
                echo "错误: 无法修改网关"
            fi
        fi
    else
        echo "信息: config.yml 不存在，跳过修改"
    fi
    echo
fi


# 2. 记录所有存在的文件的MD5值
echo "记录原始文件的MD5值..."
declare -A original_md5s
files=("app.bin" "adctrl" "app.yml" "config.yml" "config_multi.sh" "config_single_bd.sh"
       "config_single_gps.sh" "app" "daemon" "system.dtb" "uImage")

for file in "${files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        original_md5s["$file"]=$(md5sum "$SCRIPT_DIR/$file" | awk '{print $1}')
        echo "$file: ${original_md5s[$file]}"
    else
        echo "信息: 跳过不存在的文件 $file"
    fi
done
echo

# 3. 执行文件移动操作（仅移动存在的文件）
echo "开始移动文件..."

# (1) 移动第一组文件到/app
group1=("app.bin" "adctrl" "app.yml" "config.yml" "config_multi.sh"
        "config_single_bd.sh" "config_single_gps.sh" "daemon")

for file in "${group1[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        mv "$SCRIPT_DIR/$file" /app/
        chmod 777 "/app/$file"
        echo "移动 $file 到 /app 并设置权限为777"
        sync
    else
        echo "信息: 跳过不存在的文件 $file"
    fi
done
echo

# (2) 移动第二组文件到/run/media/mmcblk1p1
group2=("system.dtb" "uImage")

for file in "${group2[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        cp -f "$SCRIPT_DIR/$file" /run/media/mmcblk1p1/
        rm "$SCRIPT_DIR/$file"
        echo "通过复制覆盖 $file 到 /run/media/mmcblk1p1"
        sync
    else
        echo "信息: 跳过不存在的文件 $file"
    fi
done
echo

# (3) 移动app文件到/etc/init.d
if [ -f "$SCRIPT_DIR/app" ]; then
    mv "$SCRIPT_DIR/app" /etc/init.d/
    chmod 777 /etc/init.d/app
    echo "移动 app 到 /etc/init.d 并设置权限为777"
    sync
else
    echo "信息: app 文件不存在，跳过移动"
fi
echo

# (4) 检查并移动S49app文件
if [ -f "/app/S49app" ]; then
    mv "/app/S49app" /etc/rc5.d/
    chmod 777 /etc/rc5.d/S49app
    echo "移动 S49app 到 /etc/rc5.d 并设置权限为777"
    sync
else
    echo "信息: /app/S49app 不存在，跳过移动"
fi
echo

# 4. 验证文件移动后的MD5值（仅验证实际移动的文件）
echo "验证文件移动后的MD5值..."
all_success=1

# 检查第一组文件
for file in "${group1[@]}"; do
    if [[ -f "/app/$file" && -v original_md5s["$file"] ]]; then  # 只检查实际移动过的文件
        new_md5=$(md5sum "/app/$file" | awk '{print $1}')
        if [ "${original_md5s[$file]}" == "$new_md5" ]; then
            echo "验证成功: /app/$file MD5匹配"
        else
            echo "错误: /app/$file MD5不匹配 (原: ${original_md5s[$file]}, 新: $new_md5)"
            all_success=0
        fi
    fi
done
echo

# 检查第二组文件
for file in "${group2[@]}"; do
    if [[ -f "/run/media/mmcblk1p1/$file" && -v original_md5s["$file"] ]]; then
        new_md5=$(md5sum "/run/media/mmcblk1p1/$file" | awk '{print $1}')
        if [ "${original_md5s[$file]}" == "$new_md5" ]; then
            echo "验证成功: /run/media/mmcblk1p1/$file MD5匹配"
        else
            echo "错误: /run/media/mmcblk1p1/$file MD5不匹配 (原: ${original_md5s[$file]}, 新: $new_md5)"
            all_success=0
        fi
    fi
done
echo

# 检查app文件
if [[ -f "/etc/init.d/app" && -v original_md5s["app"] ]]; then
    new_md5=$(md5sum "/etc/init.d/app" | awk '{print $1}')
    if [ "${original_md5s[app]}" == "$new_md5" ]; then
        echo "验证成功: /etc/init.d/app MD5匹配"
    else
        echo "错误: /etc/init.d/app MD5不匹配 (原: ${original_md5s[app]}, 新: $new_md5)"
        all_success=0
    fi
fi
echo

if [ $all_success -eq 1 ]; then
    echo "所有文件更新验证成功!"
else
    echo "警告: 部分文件验证失败!"
    exit 1
fi

echo "软件更新完成!"