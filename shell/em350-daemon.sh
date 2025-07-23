#!/bin/sh /etc/rc.common
# OpenWRT EM350 4G模块守护进程脚本 - 完全修正版

START=99
STOP=10

SERIAL_DEVICE="/dev/ttyUSB2"
BAUD_RATE=115200
POLL_INTERVAL=10
INITIAL_DELAY=90
POST_DIAL_DELAY=30
MICROCOM_TIMEOUT=2000
RESPONSE_FILE="/tmp/em350_response.tmp"

start() {
    echo "启动EM350 4G模块守护进程(完全修正版)..."
    sleep $INITIAL_DELAY

    while true; do
        > $RESPONSE_FILE
        echo "发送AT^NDISSTATQRY?查询命令..."
        echo -e "AT^NDISSTATQRY?\r\n" | microcom -t $MICROCOM_TIMEOUT -s $BAUD_RATE $SERIAL_DEVICE > $RESPONSE_FILE
        sleep 1

        # 处理响应中的回车符
        RESPONSE=$(tr -d '\r' < $RESPONSE_FILE)
        rm -f $RESPONSE_FILE

        # 调试输出
        echo "原始响应:"
        echo "$RESPONSE"

        # 提取状态行（考虑Windows和Unix换行格式）
        STATUS_LINE=$(echo "$RESPONSE" | grep -m 1 "NDISSTATQRY:")

        if [ -n "$STATUS_LINE" ]; then
            # 提取第一个状态值（0或1）
            STATUS=$(echo "$STATUS_LINE" | sed -n 's/.*NDISSTATQRY: \([0-9]\),.*/\1/p')

            case $STATUS in
                1)
                    echo "状态：已连接 (状态码: $STATUS)"
                    ;;
                0)
                    echo "状态：未连接 (状态码: $STATUS)，开始拨号..."
                    echo -e "AT^NDISDUP=1,1\r\n" | microcom -t $MICROCOM_TIMEOUT -s $BAUD_RATE $SERIAL_DEVICE
                    sleep 5
                    echo "执行DHCP获取IP..."
                    udhcpc -i wwan0
                    sleep $POST_DIAL_DELAY
                    ;;
                *)
                    echo "未知状态值: $STATUS"
                    echo "完整状态行: $STATUS_LINE"
                    ;;
            esac
        else
            echo "错误：未找到状态行"
            echo "十六进制响应:"
            echo "$RESPONSE" | hexdump -C
        fi

        sleep $POLL_INTERVAL
    done
}

stop() {
    echo "停止EM350 4G模块守护进程..."
    killall $(basename $0)
    rm -f $RESPONSE_FILE
}

restart() {
    stop
    sleep 2
    start
}