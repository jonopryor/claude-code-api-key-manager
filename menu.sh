#!/bin/bash

# Include the key manager functions
source "$(dirname "$0")/claude-key-manager.sh"

show_main_menu() {
    clear
    echo "========================================"
    echo "      Claude API Key Manager Menu      "
    echo "========================================"
    echo
    echo "1) List all saved keys"
    echo "2) Add a new key"
    echo "3) Remove a key"
    echo "4) Switch to a different key"
    echo "5) Show current active key"
    echo "6) Save current key as default"
    echo "7) Exit"
    echo
    read -p "Please select an option (1-7): " choice
    echo
}

show_current_key() {
    current_key=$(get_current_key)
    if [ -n "$current_key" ]; then
        echo "Current active key: $current_key"
        
        # Find which project this key belongs to
        keys=$(parse_json_keys "$KEYS_FILE" 2>/dev/null)
        if [ -n "$keys" ]; then
            while IFS= read -r key; do
                stored_key=$(get_json_value "$KEYS_FILE" "$key")
                if [ "$stored_key" = "$current_key" ]; then
                    echo "Project: $key"
                    break
                fi
            done <<< "$keys"
        fi
    else
        echo "No active key found."
    fi
}

switch_key() {
    echo "Available projects:"
    keys=$(list_keys)
    if [ $? -ne 0 ]; then
        echo "No keys available. Please add a key first."
        return 1
    fi
    
    i=1
    while IFS= read -r key; do
        echo "$i) $key"
        i=$((i + 1))
    done <<< "$keys"
    
    echo
    read -p "Enter number of key to switch to: " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice."
        return 1
    fi
    
    selected_key=$(echo "$keys" | sed -n "${choice}p")
    if [ -z "$selected_key" ]; then
        echo "Invalid choice."
        return 1
    fi
    
    api_key=$(get_json_value "$KEYS_FILE" "$selected_key")
    update_claude_config "$api_key"
    echo "Switched to project: $selected_key"
}

list_all_keys() {
    echo "Saved API keys:"
    keys=$(list_keys)
    if [ $? -eq 0 ]; then
        i=1
        while IFS= read -r key; do
            api_key=$(get_json_value "$KEYS_FILE" "$key")
            masked_key="${api_key:0:8}...${api_key: -4}"
            echo "$i) $key: $masked_key"
            i=$((i + 1))
        done <<< "$keys"
    else
        echo "No keys found."
    fi
}

main_loop() {
    while true; do
        show_main_menu
        
        case $choice in
            1)
                list_all_keys
                ;;
            2)
                add_key
                ;;
            3)
                remove_key
                ;;
            4)
                switch_key
                ;;
            5)
                show_current_key
                ;;
            6)
                save_current_as_default
                echo "Current key saved as default (if not already saved)."
                ;;
            7)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option. Please select 1-7."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Initialize files and start the menu
initialize_files
main_loop