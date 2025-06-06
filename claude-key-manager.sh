#!/bin/bash

KEYS_FILE="$HOME/claude-api-project-keys.json"
CLAUDE_CONFIG="$HOME/.claude.json"

check_dependencies() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed. Please install jq first."
        echo "On macOS: brew install jq"
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        exit 1
    fi
}

initialize_files() {
    check_dependencies
    if [ ! -f "$KEYS_FILE" ]; then
        echo '{}' > "$KEYS_FILE"
    fi
    if [ ! -f "$CLAUDE_CONFIG" ]; then
        echo '{}' > "$CLAUDE_CONFIG"
    fi
}

parse_json_keys() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    grep -o '"[^"]*"[[:space:]]*:' "$file" | sed 's/"//g' | sed 's/[[:space:]]*://' | grep -v '^$'
}

get_json_value() {
    local file="$1"
    local key="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | sed 's/.*":[[:space:]]*"//' | sed 's/".*//'
}

get_current_key() {
    if [ -f "$CLAUDE_CONFIG" ]; then
        get_json_value "$CLAUDE_CONFIG" "primaryApiKey"
    fi
}

save_current_as_default() {
    local current_key=$(get_current_key)
    if [ -n "$current_key" ]; then
        local existing_keys=$(parse_json_keys "$KEYS_FILE")
        local key_exists=false
        
        while IFS= read -r key; do
            local stored_key=$(get_json_value "$KEYS_FILE" "$key")
            if [ "$stored_key" = "$current_key" ]; then
                key_exists=true
                break
            fi
        done <<< "$existing_keys"
        
        if [ "$key_exists" = false ]; then
            add_key_internal "Default Key" "$current_key"
        fi
    fi
}

list_keys() {
    if [ ! -f "$KEYS_FILE" ]; then
        echo "No keys file found."
        return 1
    fi
    
    keys=$(parse_json_keys "$KEYS_FILE")
    if [ -z "$keys" ]; then
        echo "No keys found."
        return 1
    fi
    
    echo "$keys"
}

add_key_internal() {
    local project_name="$1"
    local api_key="$2"
    
    initialize_files
    
    if [ -s "$KEYS_FILE" ] && [ "$(cat "$KEYS_FILE")" != "{}" ]; then
        sed -i "" "s/}$/,\"$project_name\":\"$api_key\"}/" "$KEYS_FILE"
    else
        echo "{\"$project_name\":\"$api_key\"}" > "$KEYS_FILE"
    fi
}

add_key() {
    read -p "Enter project name: " project_name
    read -p "Enter API key: " api_key
    
    if [ -z "$project_name" ] || [ -z "$api_key" ]; then
        echo "Project name and API key cannot be empty."
        return 1
    fi
    
    add_key_internal "$project_name" "$api_key"
    echo "Key added for project: $project_name"
}

remove_key() {
    keys=$(list_keys)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "Available keys:"
    i=1
    while IFS= read -r key; do
        echo "$i) $key"
        i=$((i + 1))
    done <<< "$keys"
    
    read -p "Enter number of key to remove: " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return 1
    fi
    
    selected_key=$(echo "$keys" | sed -n "${choice}p")
    if [ -z "$selected_key" ]; then
        echo "Invalid choice."
        return 1
    fi
    
    temp_file=$(mktemp)
    grep -v "\"$selected_key\"" "$KEYS_FILE" > "$temp_file"
    
    sed -i "" 's/,{/\n{/g; s/},{/}\n{/g' "$temp_file"
    sed -i "" '/^$/d' "$temp_file"
    sed -i "" 's/,,/,/g; s/,}/}/g; s/{,/{/g' "$temp_file"
    
    if [ ! -s "$temp_file" ] || [ "$(cat "$temp_file" | tr -d '[:space:]')" = "{}" ]; then
        echo '{}' > "$KEYS_FILE"
    else
        mv "$temp_file" "$KEYS_FILE"
    fi
    
    rm -f "$temp_file"
    echo "Key removed for project: $selected_key"
}

update_claude_config() {
    local api_key="$1"
    
    initialize_files
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    if grep -q "primaryApiKey" "$CLAUDE_CONFIG"; then
        # If primaryApiKey exists, update it
        if jq --arg key "$api_key" '.primaryApiKey = $key' "$CLAUDE_CONFIG" > "$temp_file"; then
            mv "$temp_file" "$CLAUDE_CONFIG"
            echo "Updated Claude configuration with selected key."
        else
            echo "Error: Failed to update Claude configuration."
            rm -f "$temp_file"
            return 1
        fi
    else
        # If primaryApiKey doesn't exist, add it
        if jq --arg key "$api_key" '. + {"primaryApiKey": $key}' "$CLAUDE_CONFIG" > "$temp_file"; then
            mv "$temp_file" "$CLAUDE_CONFIG"
            echo "Updated Claude configuration with selected key."
        else
            echo "Error: Failed to update Claude configuration."
            rm -f "$temp_file"
            return 1
        fi
    fi
}

main_menu() {
    echo
    echo "Claude API Key Manager"
    echo "======================"
    
    keys=$(list_keys)
    if [ $? -eq 0 ]; then
        echo "Select a key:"
        i=1
        while IFS= read -r key; do
            echo "$i) $key"
            i=$((i + 1))
        done <<< "$keys"
        echo
        read -p "Choose a key (1-$((i-1))): " choice
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid choice. Please enter a number."
            return 1
        fi
        
        key_count=$(echo "$keys" | wc -l)
        
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$key_count" ]; then
            selected_key=$(echo "$keys" | sed -n "${choice}p")
            api_key=$(get_json_value "$KEYS_FILE" "$selected_key")
            update_claude_config "$api_key"
            echo "Selected key for project: $selected_key"
        else
            echo "Invalid choice."
            return 1
        fi
    else
        echo "No keys available. Please add a key first using: $0 add"
        return 1
    fi
}

# Only execute commands when called directly with arguments
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    case "$1" in
        "add")
            initialize_files
            add_key
            ;;
        "remove")
            initialize_files
            remove_key
            ;;
        *)
            echo "Usage: $0 [add|remove]"
            echo "For the full menu interface, run menu.sh"
            ;;
    esac
fi