#!/bin/bash

# Ukraine Alarm OpenClaw Skill - Installation Script
# Автоматичне встановлення скіла для OpenClaw

set -e  # Зупинити при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функція для виводу кольорових повідомлень
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Початок встановлення
header "🇺🇦 Ukraine Alarm OpenClaw Skill - Встановлення"

# Перевірка, що скрипт запущено не з корневої директорії
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
info "Директорія скрипта: $SCRIPT_DIR"

# Перевірка наявності OpenClaw
info "Перевірка наявності OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    error "OpenClaw не знайдено!"
    echo ""
    echo "Будь ласка, встановіть OpenClaw спочатку:"
    echo "  npm install -g openclaw@latest"
    echo ""
    echo "Або відвідайте: https://docs.openclaw.ai/"
    exit 1
fi

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "невідомо")
success "OpenClaw встановлено (версія: $OPENCLAW_VERSION)"

# Визначення директорії workspace
if [ -d "$HOME/.openclaw/workspace/skills" ]; then
    SKILLS_DIR="$HOME/.openclaw/workspace/skills"
elif [ -d "$HOME/.openclaw/skills" ]; then
    SKILLS_DIR="$HOME/.openclaw/skills"
else
    # Створити директорію якщо не існує
    SKILLS_DIR="$HOME/.openclaw/workspace/skills"
    info "Створення директорії для скілів..."
    mkdir -p "$SKILLS_DIR"
    success "Директорія створена: $SKILLS_DIR"
fi

TARGET_DIR="$SKILLS_DIR/ukraine-alarm"
info "Цільова директорія: $TARGET_DIR"

# Перевірка чи скіл вже встановлено
if [ -d "$TARGET_DIR" ]; then
    warning "Скіл вже встановлено в $TARGET_DIR"
    echo ""
    read -p "Перезаписати існуючу версію? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Встановлення скасовано."
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

# Копіювання файлів скіла
info "Копіювання файлів скіла..."
cp -r "$SCRIPT_DIR" "$TARGET_DIR"
success "Файли скопійовано"

# Перевірка наявності curl
info "Перевірка залежностей..."
if ! command -v curl &> /dev/null; then
    error "curl не знайдено!"
    echo ""
    echo "Встановіть curl:"
    echo "  macOS: brew install curl"
    echo "  Linux (Debian/Ubuntu): sudo apt-get install curl"
    echo "  Linux (RHEL/CentOS): sudo yum install curl"
    exit 1
fi
success "curl встановлено"

# Перевірка наявності jq (опціонально)
if command -v jq &> /dev/null; then
    success "jq встановлено (опціонально)"
else
    warning "jq не встановлено (опціонально, але рекомендовано)"
    echo ""
    echo "Для кращого форматування JSON встановіть jq:"
    echo "  macOS: brew install jq"
    echo "  Linux (Debian/Ubuntu): sudo apt-get install jq"
    echo "  Linux (RHEL/CentOS): sudo yum install jq"
    echo ""
fi

# Конфігурація
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

header "Налаштування API ключа"

echo "Для роботи скіла потрібен API ключ від ukrainealarm.com"
echo ""
echo "Якщо у вас ще немає ключа:"
echo "  1. Відвідайте: https://api.ukrainealarm.com"
echo "  2. Заповніть форму для отримання безкоштовного API ключа"
echo "  3. Отримайте ключ на email"
echo ""

read -p "Введіть ваш API ключ (або натисніть Enter для налаштування пізніше): " API_KEY
echo ""

if [ -n "$API_KEY" ]; then
    # Перевірка наявності конфігураційного файлу
    if [ -f "$CONFIG_FILE" ]; then
        info "Оновлення існуючого конфігураційного файлу..."
        
        # Резервна копія
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
        success "Створено резервну копію: $CONFIG_FILE.backup"
        
        # Використовуємо jq якщо доступний, інакше додаємо вручну
        if command -v jq &> /dev/null; then
            # Додати або оновити секцію ukraine-alarm
            jq --arg key "$API_KEY" \
               '.skills.entries."ukraine-alarm" = {enabled: true, env: {UKRAINE_ALARM_API_KEY: $key}}' \
               "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
            success "Конфігурація оновлена"
        else
            warning "jq не знайдено - потрібно налаштувати вручну"
            echo ""
            echo "Додайте в $CONFIG_FILE:"
            echo ""
            echo '  "skills": {'
            echo '    "entries": {'
            echo '      "ukraine-alarm": {'
            echo '        "enabled": true,'
            echo '        "env": {'
            echo "          \"UKRAINE_ALARM_API_KEY\": \"$API_KEY\""
            echo '        }'
            echo '      }'
            echo '    }'
            echo '  }'
            echo ""
        fi
    else
        info "Створення нового конфігураційного файлу..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
{
  "skills": {
    "entries": {
      "ukraine-alarm": {
        "enabled": true,
        "env": {
          "UKRAINE_ALARM_API_KEY": "$API_KEY"
        }
      }
    }
  }
}
EOF
        success "Конфігурація створена"
    fi
else
    warning "API ключ не введено"
    echo ""
    echo "Для налаштування API ключа пізніше:"
    echo "  1. Відредагуйте файл: $CONFIG_FILE"
    echo "  2. Додайте секцію:"
    echo ""
    echo '     "skills": {'
    echo '       "entries": {'
    echo '         "ukraine-alarm": {'
    echo '           "enabled": true,'
    echo '           "env": {'
    echo '             "UKRAINE_ALARM_API_KEY": "ваш_api_ключ_тут"'
    echo '           }'
    echo '         }'
    echo '       }'
    echo '     }'
    echo ""
fi

# Підсумок встановлення
header "✅ Встановлення завершено!"

echo "📦 Скіл встановлено в: $TARGET_DIR"
echo ""
echo "📋 Наступні кроки:"
echo ""

if [ -z "$API_KEY" ]; then
    echo "  1. Отримайте API ключ на https://api.ukrainealarm.com"
    echo "  2. Налаштуйте API ключ в $CONFIG_FILE"
    echo "  3. Перезапустіть OpenClaw Gateway"
else
    echo "  1. Перезапустіть OpenClaw Gateway"
fi

echo ""
echo "Перезапуск Gateway:"
echo "  openclaw daemon restart"
echo "  # або"
echo "  openclaw gateway --port 18789"
echo ""
echo "📚 Документація:"
echo "  • README.md - Інструкція по використанню"
echo "  • SKILL.md - Технічна документація"
echo "  • EXAMPLES.md - Приклади запитів"
echo "  • REGIONS.md - Список ID регіонів"
echo ""
echo "🧪 Тестування:"
echo "  Після перезапуску відправте в OpenClaw:"
echo '  "Чи є зараз тривоги в Україні?"'
echo ""
echo "❓ Допомога:"
echo "  • API документація: https://api.ukrainealarm.com/swagger/index.html"
echo "  • OpenClaw документація: https://docs.openclaw.ai/"
echo ""

success "🇺🇦 Залишайтеся в безпеці!"
echo ""
