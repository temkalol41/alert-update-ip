#!/bin/bash

# Конфигурационные параметры
API_LOGIN="API_USER"
API_PASSWORD="API_PASSWORD"
DOMAINS=("a.domain.com" "b.domain.com")
LAST_IP_FILE="/sh-scripts/last_ip"
TELEGRAM_BOT_TOKEN="TG_BOT_TOKEN"
TELEGRAM_CHAT_ID="TG_CHAT_ID"

# Функция для получения текущего публичного IP
get_current_ip() {
    curl -s https://api.ipify.org
}

# Функция для обновления IP-адреса у регистратора
update_dns_record() {
    local domain=$1
    local new_ip=$2
    curl -s "https://api.beget.com/api/dns/changeRecords?login=${API_LOGIN}&passwd=${API_PASSWORD}&input_format=json&output_format=json&input_data={\"fqdn\":\"${domain}\",\"records\":{\"A\":[{\"priority\":10,\"value\":\"${new_ip}\"}]}}"
}

# Функция для отправки сообщения в Telegram
send_telegram_message() {
    local message="$1"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML"
}

# Получаем текущий публичный IP-адрес
current_ip=$(get_current_ip)

# Проверяем, существует ли файл с последним IP-адресом
if [ -f "$LAST_IP_FILE" ]; then
    last_ip=$(cat "$LAST_IP_FILE")
else
    last_ip=""
fi

# Если IP-адрес изменился, обновляем DNS-записи и отправляем уведомление в Telegram
if [ "$current_ip" != "$last_ip" ]; then
    echo "IP-адрес изменился с $last_ip на $current_ip. Обновляем DNS-записи..."
    for domain in "${DOMAINS[@]}"; do
        update_dns_record "$domain" "$current_ip"
    done
    # Отправляем уведомление в Telegram
    message="IP-адрес изменился с $last_ip на $current_ip. Обновлены DNS-записи."
    send_telegram_message "$message"

    # Обновляем файл с последним IP-адресом
    echo "$current_ip" > "$LAST_IP_FILE"
else
    echo "IP-адрес не изменился. Обновление не требуется."
fi
