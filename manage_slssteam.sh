#!/bin/bash

# Проверка прав выполнения
if [ ! -x "$0" ]; then
    echo "Используйте: chmod +x ${0} для установки прав на выполнение"
    exit 1
fi

# Configuration variables
CONFIG_DIR="$HOME/SLSsteam/config"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
PROFILES_DIR="$CONFIG_DIR/Profiles"
CACHE_FILE="$CONFIG_DIR/applist_cache.json"
CACHE_TTL=86400  # 24 hours

install_slssteam() {
    if [ -d "$HOME/SLSsteam" ]; then
        zenity --info --title="Статус SLSsteam" --width=250 --height=100 --text="SLSsteam уже установлен\nПуть: $HOME/SLSsteam"
        return 0
    fi

    zenity --question --text="SLSsteam не установлен. Установить сейчас?" --ok-label="Установить" --cancel-label="Отмена"
    if [ $? -ne 0 ]; then
        return 1
    fi

    mkdir -p "$HOME/SLSsteam/config/Profiles" || {
        zenity --error --text="Ошибка создания директорий!"
        return 1
    }

    # Создаем директорию если ее нет
    mkdir -p "$HOME/SLSsteam" || {
        zenity --error --text="Ошибка создания директории SLSsteam!"
        return 1
    }

    # Копируем только SLSsteam.so
    if [ -f "bin/SLSsteam.so" ]; then
        cp "bin/SLSsteam.so" "$HOME/SLSsteam/" || {
            zenity --error --text="Ошибка копирования SLSsteam.so!"
            return 1
        }
    else
        zenity --error --text="Файл bin/SLSsteam.so не найден!"
        return 1
    fi

    # Копируем дополнительные файлы
    mkdir -p "$HOME/SLSsteam" || {
        zenity --error --text="Ошибка создания директории SLSsteam!"
        return 1
    }

    zenity --info --text="SLSsteam успешно установлен!"
    return 0
}

uninstall_slssteam() {
    if [ ! -d "$HOME/SLSsteam" ]; then
        zenity --info --text="SLSsteam не установлен!"
        return 0
    fi

    zenity --question --text="Удалить SLSsteam? Все настройки будут потеряны." --ok-label="Удалить" --cancel-label="Отмена"
    if [ $? -ne 0 ]; then
        return 1
    fi

    rm -rf "$HOME/SLSsteam" || {
        zenity --error --text="Ошибка удаления SLSsteam!"
        return 1
    }

    zenity --info --text="SLSsteam успешно удален!"
    return 0
}

check_installed() {
    if [ -d "$HOME/SLSsteam" ]; then
        zenity --info --title="Статус SLSsteam" --width=250 --height=100 --text="SLSsteam установлен\nПуть: $HOME/SLSsteam"
    else
        zenity --info --title="Статус SLSsteam" --width=250 --height=100 --text="SLSsteam не установлен"
    fi
}

add_appid() {
    local appid_input=$1

    # Проверка что введено число
    if ! [[ "$appid_input" =~ ^[0-9]+$ ]]; then
        zenity --error --text="Ошибка: $appid_input не является валидным APPID"
        return 1
    fi

    # Добавление в конфиг
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "AdditionalApps: []" > "$CONFIG_FILE"
    fi

    if yq eval ".AdditionalApps += [$appid_input]" -i "$CONFIG_FILE"; then
        return 0
    else
        zenity --error --text="Ошибка добавления APPID $appid_input"
        return 1
    fi
}

get_app_list() {
    # Проверяем существование кэша
    if [ ! -f "$CACHE_FILE" ]; then
        # Создаем новый кэш
        curl -s "https://api.steampowered.com/ISteamApps/GetAppList/v2/" > "$CACHE_FILE" || {
            zenity --error --text="Ошибка загрузки списка игр"
            exit 1
        }
    else
        # Проверяем возраст кэша (просто по размеру файла)
        if [ $(stat -c %s "$CACHE_FILE") -lt 1000 ]; then
            curl -s "https://api.steampowered.com/ISteamApps/GetAppList/v2/" > "$CACHE_FILE" || {
                zenity --error --text="Ошибка обновления списка игр"
                exit 1
            }
        fi
    fi

    # Возвращаем содержимое кэша
    cat "$CACHE_FILE"
}

search_game() {
    local search_term=$(zenity --entry --title="Поиск игры" \
        --text="Введите название игры:" --ok-label="Искать" --cancel-label="Назад")
    [ $? -ne 0 ] && return 1
    [ -z "$search_term" ] && return 1

    local normalized_search=$(echo "$search_term" | tr -d "'[:space:]" | tr '[:upper:]' '[:lower:]')
    local games=$(get_app_list | \
        jq -r '.applist.apps[] | "\(.appid)|\(.name)"' | \
        awk -F'|' -v pattern="$normalized_search" '{
            original = $2
            gsub(/[\x27[:space:]]/, "", $2)
            normalized = tolower($2)
            if (index(normalized, pattern) > 0) print $1 "|" original
        }' | \
        sort -t'|' -k2 | uniq)

    [ -z "$games" ] && zenity --info --text="Совпадений не найдено!" && return 1

    local zenity_list=$(echo "$games" | awk -F'|' '{printf "FALSE\n%s\n%s\n", $1, $2}')
    local selected=$(echo "$zenity_list" | zenity --list --title="Результаты поиска" --checklist \
        --column="Выбрать" --column="APPID" --column="Название игры" \
        --print-column=2 --height=400 --width=600 \
        --ok-label="Выбрать" --cancel-label="Назад")

    [ -n "$selected" ] && {
        IFS='|' read -ra appids <<< "$selected"
        for appid in "${appids[@]}"; do
            add_appid "$appid" || break
        done
        
        zenity --question --title="Сохранение профиля" \
            --text="Сохранить текущую конфигурацию как профиль?" \
            --ok-label="Сохранить" --cancel-label="Пропустить"
        [ $? -eq 0 ] && create_profile
    }
}

get_profiles() {
    find "$PROFILES_DIR" -maxdepth 1 -name "*.yaml" -exec basename {} .yaml \; 2>/dev/null
}

create_profile() {
    local profile_name
    while : ; do
        profile_name=$(zenity --entry --title="Имя профиля" \
            --text="Введите имя профиля:" --ok-label="Сохранить" --cancel-label="Отмена")
        [ $? -ne 0 ] && return 1
        [ -n "$profile_name" ] && break
        zenity --error --text="Имя профиля не может быть пустым!"
    done

    local profile_file="$PROFILES_DIR/${profile_name}.yaml"
    if cp "$CONFIG_FILE" "$profile_file"; then
        zenity --info --text="Профиль успешно сохранён:\n$profile_file"
        return 0
    else
        zenity --error --text="Ошибка сохранения профиля!"
        return 1
    fi
}

main_menu() {
    while true; do
        # Получаем список профилей
        local profiles=($(get_profiles))
        menu_items=(
            "Установить" "Установить/Проверить SLSsteam"
            "Удалить" "Удалить SLSsteam"
            "Добавить APPID" "Добавить APPID в конфигурацию"
            "Поиск APPID" "Поиск APPID по названию"
        )

        # Добавляем профили в меню
        for profile in "${profiles[@]}"; do
            menu_items+=("$profile" "Загрузить профиль")
        done

        choice=$(zenity --list --title="Управление SLSsteam" \
            --column="Опция" --column="Описание" \
            --height=400 --width=600 \
            --cancel-label="Выход" \
            "${menu_items[@]}")
        
        # Если нажата Cancel/Выход
        [ $? -ne 0 ] && exit 0
        
        case "$choice" in
            "Установить")
                install_slssteam
                ;;
            "Удалить")
                uninstall_slssteam
                ;;
            "Добавить APPID")
                add_appid
                ;;
            "Поиск APPID")
                search_game
                ;;
            *)
                # Проверяем, является ли выбор профилем
                for profile in "${profiles[@]}"; do
                    if [ "$choice" == "$profile" ]; then
                        local profile_file="$PROFILES_DIR/${profile}.yaml"
                        if [ -f "$profile_file" ]; then
                            cp -f "$profile_file" "$CONFIG_FILE"
                            zenity --info --text="Профиль '$profile' успешно загружен!"
                        else
                            zenity --error --text="Профиль '$profile' не найден!"
                        fi
                        break
                    fi
                done
                ;;
        esac
    done
}

# Запуск главного меню
main_menu
