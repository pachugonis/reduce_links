#!/bin/bash

# =============================================================================
# Скрипт автоматической установки URL Shortener на Ubuntu 24
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Проверка прав root
# =============================================================================
if [ "$EUID" -ne 0 ]; then
    print_error "Этот скрипт должен быть запущен с правами root (sudo)"
    exit 1
fi

# =============================================================================
# Запрос параметров установки
# =============================================================================
echo ""
echo "========================================"
echo "  Установка URL Shortener"
echo "========================================"
echo ""

# Домен или IP
read -p "Введите домен или IP-адрес сервера (по умолчанию: localhost): " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-localhost}

# Email для SSL
read -p "Введите email для SSL сертификата (по умолчанию: admin@$SERVER_NAME): " SSL_EMAIL
SSL_EMAIL=${SSL_EMAIL:-admin@$SERVER_NAME}

# Порт
read -p "Введите порт для веб-сервера (по умолчанию: 80): " WEB_PORT
WEB_PORT=${WEB_PORT:-80}

# Директория установки
read -p "Введите директорию для установки (по умолчанию: /var/www/reduce_links): " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-/var/www/reduce_links}

# =============================================================================
# Генерация случайных паролей
# =============================================================================
print_info "Генерация случайных паролей..."

DB_ROOT_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
DB_USER="urlshortener_$(openssl rand -hex 4)"
DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)
DB_NAME="url_shortener"

print_success "Пароли сгенерированы"

# =============================================================================
# Обновление системы
# =============================================================================
print_info "Обновление пакетов системы..."
apt-get update -qq
apt-get upgrade -y -qq
print_success "Система обновлена"

# =============================================================================
# Установка необходимых пакетов
# =============================================================================
print_info "Установка необходимых пакетов..."

# Apache, PHP, MySQL и другие зависимости
apt-get install -y -qq \
    apache2 \
    php \
    php-pdo \
    php-mysql \
    php-mbstring \
    php-json \
    php-curl \
    php-xml \
    php-zip \
    mysql-server \
    unzip \
    curl \
    certbot \
    python3-certbot-apache \
    ufw \
    fail2ban

print_success "Пакеты установлены"

# =============================================================================
# Настройка MySQL
# =============================================================================
print_info "Настройка MySQL..."

# Запуск и включение MySQL
systemctl start mysql
systemctl enable mysql

# Ожидание полного запуска MySQL
sleep 3

# Функция для сброса пароля MySQL через skip-grant-tables
reset_mysql_password() {
    local NEW_PASS="$1"
    
    print_info "Сброс пароля MySQL через режим восстановления..."
    
    # Останавливаем MySQL полностью
    systemctl stop mysql 2>/dev/null || true
    sleep 2
    pkill -9 mysqld 2>/dev/null || true
    pkill -9 mysqld_safe 2>/dev/null || true
    sleep 2
    
    # Создаем директорию для запуска mysqld_safe
    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/run/mysqld 2>/dev/null || true
    
    # Запускаем MySQL в фоне с skip-grant-tables
    nohup mysqld_safe --skip-grant-tables --skip-networking > /dev/null 2>&1 &
    
    # Ждем запуска с проверкой
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
            print_info "MySQL запущен в режиме восстановления"
            break
        fi
        sleep 1
        attempts=$((attempts + 1))
    done
    
    if ! mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        print_error "Не удалось подключиться к MySQL в режиме восстановления"
        return 1
    fi
    
    # Сбрасываем пароль root (разные команды для MySQL 5.7 и 8.0+)
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    # Пробуем разные варианты сброса пароля
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${NEW_PASS}';" 2>/dev/null || \
    mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${NEW_PASS}');" 2>/dev/null || \
    mysql -u root -e "UPDATE mysql.user SET authentication_string=PASSWORD('${NEW_PASS}') WHERE User='root';" 2>/dev/null || \
    mysql -u root -e "UPDATE mysql.user SET password=PASSWORD('${NEW_PASS}') WHERE User='root';" 2>/dev/null
    
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    # Останавливаем MySQL в режиме восстановления
    pkill -9 mysqld 2>/dev/null || true
    pkill -9 mysqld_safe 2>/dev/null || true
    sleep 3
    
    # Запускаем MySQL нормально
    systemctl start mysql
    sleep 5
    
    # Проверяем подключение с новым паролем
    local check_attempts=0
    while [ $check_attempts -lt 10 ]; do
        if mysql -u root -p"${NEW_PASS}" -e "SELECT 1;" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        check_attempts=$((check_attempts + 1))
    done
    
    return 1
}

# Проверяем возможность подключения к MySQL
MYSQL_CONNECTED=false

# Попытка 1: Подключение без пароля (socket auth)
if mysql -e "SELECT 1;" > /dev/null 2>&1; then
    MYSQL_CMD="mysql"
    MYSQL_CONNECTED=true
    print_info "Подключение к MySQL без пароля (socket auth)"
fi

# Попытка 2: Подключение как root без пароля
if [ "$MYSQL_CONNECTED" = false ] && mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
    MYSQL_CMD="mysql -u root"
    MYSQL_CONNECTED=true
    print_info "Подключение к MySQL как root без пароля"
fi

# Попытка 3: Поиск временного пароля в логах (MySQL 8.0+)
if [ "$MYSQL_CONNECTED" = false ]; then
    TEMP_PASS=$(grep 'temporary password' /var/log/mysql/error.log 2>/dev/null | tail -1 | sed 's/.*temporary password is "\([^"]*\)".*/\1/')
    if [ -n "$TEMP_PASS" ] && mysql -u root -p"${TEMP_PASS}" -e "SELECT 1;" > /dev/null 2>&1; then
        MYSQL_CMD="mysql -u root -p${TEMP_PASS}"
        MYSQL_CONNECTED=true
        print_info "Найден и использован временный пароль MySQL"
    fi
fi

# Попытка 4: Сброс пароля принудительно
if [ "$MYSQL_CONNECTED" = false ]; then
    if reset_mysql_password "${DB_ROOT_PASS}"; then
        MYSQL_CMD="mysql -u root -p${DB_ROOT_PASS}"
        MYSQL_CONNECTED=true
        print_success "Пароль root MySQL успешно сброшен"
    else
        print_error "Не удалось автоматически настроить пароль MySQL"
        exit 1
    fi
fi

# Настройка безопасности MySQL
${MYSQL_CMD} -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_ROOT_PASS}';" 2>/dev/null || true

# После установки пароля используем его для дальнейших команд
MYSQL_CMD="mysql -u root -p${DB_ROOT_PASS}"

${MYSQL_CMD} -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
${MYSQL_CMD} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
${MYSQL_CMD} -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
${MYSQL_CMD} -e "FLUSH PRIVILEGES;"

# Создание базы данных и пользователя
${MYSQL_CMD} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
${MYSQL_CMD} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
${MYSQL_CMD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
${MYSQL_CMD} -e "FLUSH PRIVILEGES;"

print_success "MySQL настроен"

# =============================================================================
# Распаковка проекта
# =============================================================================
print_info "Установка проекта..."

# Создание директории
mkdir -p "$INSTALL_DIR"

# Определение пути к архиву
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE_PATH="${SCRIPT_DIR}/reduce_links.zip"

if [ ! -f "$ARCHIVE_PATH" ]; then
    print_error "Архив reduce_links.zip не найден в директории скрипта!"
    print_info "Ожидаемый путь: $ARCHIVE_PATH"
    exit 1
fi

# Распаковка
unzip -q "$ARCHIVE_PATH" -d "$INSTALL_DIR"

# Установка прав
chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

print_success "Проект распакован в $INSTALL_DIR"

# =============================================================================
# Импорт структуры базы данных
# =============================================================================
print_info "Импорт структуры базы данных..."

if [ -f "$INSTALL_DIR/database.sql" ]; then
    mysql -u root -p"${DB_ROOT_PASS}" "${DB_NAME}" < "$INSTALL_DIR/database.sql"
    print_success "База данных импортирована"
else
    print_warning "Файл database.sql не найден, пропускаем импорт"
fi

# =============================================================================
# Настройка конфигурации PHP
# =============================================================================
print_info "Настройка конфигурации PHP..."

CONFIG_FILE="$INSTALL_DIR/includes/config.php"

if [ -f "$CONFIG_FILE" ]; then
    # Создание резервной копии
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Обновление конфигурации
    cat > "$CONFIG_FILE" << EOF
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASS', '${DB_PASS}');

define('BASE_URL', 'http://${SERVER_NAME}');

try {
    \$pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch (PDOException \$e) {
    die("Database connection failed: " . \$e->getMessage());
}
EOF
    
    chown www-data:www-data "$CONFIG_FILE"
    print_success "Конфигурация PHP обновлена"
else
    print_error "Файл конфигурации не найден: $CONFIG_FILE"
    exit 1
fi

# =============================================================================
# Настройка Apache
# =============================================================================
print_info "Настройка Apache..."

# Включение необходимых модулей
a2enmod rewrite
a2enmod ssl
a2enmod headers

# Создание виртуального хоста
VHOST_FILE="/etc/apache2/sites-available/reduce_links.conf"

cat > "$VHOST_FILE" << EOF
<VirtualHost *:80>
    ServerName ${SERVER_NAME}
    DocumentRoot ${INSTALL_DIR}/public
    
    <Directory ${INSTALL_DIR}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    <Directory ${INSTALL_DIR}>
        Options -Indexes
        Require all denied
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/reduce_links_error.log
    CustomLog \${APACHE_LOG_DIR}/reduce_links_access.log combined
</VirtualHost>
EOF

# Отключение дефолтного сайта и включение нашего
a2dissite 000-default.conf 2>/dev/null || true
a2ensite reduce_links.conf

# Перезапуск Apache
systemctl restart apache2
systemctl enable apache2

print_success "Apache настроен"

# =============================================================================
# Настройка SSL (Let's Encrypt)
# =============================================================================
if [ "$SERVER_NAME" != "localhost" ] && [ "$SERVER_NAME" != "127.0.0.1" ]; then
    print_info "Настройка SSL сертификата..."
    
    # Проверка, доступен ли домен извне
    if curl -s --max-time 10 "http://${SERVER_NAME}" > /dev/null 2>&1; then
        certbot --apache -d "$SERVER_NAME" --non-interactive --agree-tos --email "$SSL_EMAIL" 2>/dev/null || {
            print_warning "Не удалось автоматически получить SSL сертификат"
            print_info "Вы можете получить его позже командой: certbot --apache -d $SERVER_NAME"
        }
    else
        print_warning "Домен $SERVER_NAME недоступен извне, пропускаем получение SSL"
        print_info "Получите SSL позже командой: certbot --apache -d $SERVER_NAME"
    fi
else
    print_info "Локальная установка, SSL не требуется"
fi

# =============================================================================
# Настройка фаервола
# =============================================================================
print_info "Настройка фаервола..."

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow "Apache Full"
ufw --force enable

print_success "Фаервол настроен"

# =============================================================================
# Настройка Fail2Ban
# =============================================================================
print_info "Настройка Fail2Ban..."

systemctl start fail2ban
systemctl enable fail2ban

print_success "Fail2Ban настроен"

# =============================================================================
# Сохранение учетных данных
# =============================================================================
CREDENTIALS_FILE="${INSTALL_DIR}/.credentials.txt"

cat > "$CREDENTIALS_FILE" << EOF
========================================
  Учетные данные URL Shortener
========================================
Дата установки: $(date '+%Y-%m-%d %H:%M:%S')
Сервер: ${SERVER_NAME}
Директория: ${INSTALL_DIR}

--- MySQL Root ---
Пользователь: root
Пароль: ${DB_ROOT_PASS}

--- База данных приложения ---
База данных: ${DB_NAME}
Пользователь: ${DB_USER}
Пароль: ${DB_PASS}

--- Доступ к приложению ---
URL: http://${SERVER_NAME}
(или https://${SERVER_NAME} если SSL настроен)

========================================
ВАЖНО: Сохраните этот файл в безопасном месте!
========================================
EOF

chmod 600 "$CREDENTIALS_FILE"
chown root:root "$CREDENTIALS_FILE"

# =============================================================================
# Проверка установки
# =============================================================================
print_info "Проверка установки..."

# Проверка Apache
if systemctl is-active --quiet apache2; then
    print_success "Apache работает"
else
    print_error "Apache не запущен"
fi

# Проверка MySQL
if systemctl is-active --quiet mysql; then
    print_success "MySQL работает"
else
    print_error "MySQL не запущен"
fi

# Проверка подключения к БД
if mysql -u "${DB_USER}" -p"${DB_PASS}" -e "USE ${DB_NAME}; SELECT 1;" > /dev/null 2>&1; then
    print_success "Подключение к базе данных работает"
else
    print_error "Не удалось подключиться к базе данных"
fi

# =============================================================================
# Вывод информации
# =============================================================================
echo ""
echo "========================================"
echo "  Установка завершена успешно!"
echo "========================================"
echo ""
echo -e "Приложение доступно по адресу: ${GREEN}http://${SERVER_NAME}${NC}"
if [ "$SERVER_NAME" != "localhost" ] && [ "$SERVER_NAME" != "127.0.0.1" ]; then
    echo -e "(или ${GREEN}https://${SERVER_NAME}${NC} если SSL настроен)"
fi
echo ""
echo "Учетные данные сохранены в: ${CREDENTIALS_FILE}"
echo ""
echo "--- MySQL Root ---"
echo "Пользователь: root"
echo "Пароль: ${DB_ROOT_PASS}"
echo ""
echo "--- База данных приложения ---"
echo "База данных: ${DB_NAME}"
echo "Пользователь: ${DB_USER}"
echo "Пароль: ${DB_PASS}"
echo ""
echo "========================================"
echo "ВАЖНО: Сохраните учетные данные!"
echo "========================================"
echo ""

# Предложение удалить архив
read -p "Удалить установочный архив reduce_links.zip? (y/n): " DELETE_ARCHIVE
if [[ $DELETE_ARCHIVE =~ ^[Yy]$ ]]; then
    rm -f "$ARCHIVE_PATH"
    print_success "Архив удален"
fi

echo ""
print_success "Готово!"
