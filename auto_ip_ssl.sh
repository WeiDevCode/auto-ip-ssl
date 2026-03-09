#!/bin/bash
set -e  # 遇到错误立即退出

# ======================== 1. 函数定义 ========================
# 提示用户输入并验证IP格式
input_ip() {
    local ip=""
    while true; do
        read -p "请输入要生成证书的IP地址: " ip
        
        # 简单的IP格式验证
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # 拆分IP段验证数值范围
            IFS='.' read -r a b c d <<< "$ip"
            if (( a >= 0 && a <= 255 && b >= 0 && b <= 255 && c >= 0 && c <= 255 && d >= 0 && d <= 255 )); then
                break
            fi
        fi
        echo "❌ 无效的IP地址格式，请重新输入！"
    done
    echo "$ip"
}

# 提示用户输入国家代码并验证
input_country_code() {
    local country=""
    while true; do
        read -p "请输入2位国家代码(如CN/US): " country
        
        # 验证国家代码格式（2位大写字母）
        if [[ $country =~ ^[A-Z]{2}$ ]]; then
            break
        fi
        echo "❌ 无效的国家代码格式（必须是2位大写字母），请重新输入！"
    done
    echo "$country"
}

# 生成SSL配置文件
generate_san_config() {
    local ip=$1
    local country=$2
    local config_file="san.cnf"
    
    # 写入配置文件
    cat > "$config_file" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = $country
ST = State
L = City
O = Organization
OU = Department
CN = $ip
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = $ip
EOF
    echo "已生成SSL配置文件：$config_file"
}

# 生成SSL证书
generate_ssl_cert() {
    local ip=$1
    local country=$2
    
    # 1. 生成私钥
    echo -e "\n步骤1：生成2048位RSA私钥..."
    openssl genrsa -out server.key 2048
    
    # 2. 生成配置文件
    echo "步骤2：生成SAN配置文件..."
    generate_san_config "$ip" "$country"
    
    # 3. 生成自签名证书（有效期10年）
    echo "步骤3：生成自签名SSL证书..."
    openssl req -new -x509 -days 3650 -key server.key -out server.crt -config san.cnf -extensions v3_req
    
    # 4. 验证证书
    echo "步骤4：验证证书信息..."
    openssl x509 -in server.crt -text -noout
    
    echo -e "\n✅ SSL证书生成完成！"
    echo "生成的文件："
    echo "  - 私钥：server.key"
    echo "  - 证书：server.crt"
    echo "  - 配置文件：san.cnf"
}

# ======================== 2. 主流程 ========================
echo "===== 手动输入参数生成SSL证书脚本 ====="

# 提示用户输入IP地址
LOCAL_IP=$(input_ip)
echo "✅ 确认IP地址：$LOCAL_IP"

# 提示用户输入国家代码
COUNTRY_CODE=$(input_country_code)
echo "✅ 确认国家代码：$COUNTRY_CODE"

# 生成SSL证书
generate_ssl_cert "$LOCAL_IP" "$COUNTRY_CODE"
