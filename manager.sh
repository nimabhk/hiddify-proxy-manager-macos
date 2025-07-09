#!/bin/bash

# ==============================================================================
#  Hiddify Smart Proxy Manager for macOS (Version 8.0 - Public Release)
#
#      Author: Nima Behkar [9.2025] (moderndesigner@outlook.com)
#
#  This script provides intelligent, automatic management of macOS system
#  proxies based on the Hiddify-Next client's connection status.
# ==============================================================================

# --- CONFIGURATION ---
# This value is automatically set by the installer.
HIDDIFY_PORT="PLACEHOLDER_PORT"
HIDDIFY_SERVER="127.0.0.1"

# --- INTERNAL VARIABLES ---
STATE_FILE="/tmp/hiddify_manager.state.json"
LOG_FILE="/tmp/hiddify_proxy.log"
PROXY_TYPES=("http" "https" "socks")

# --- HELPER FUNCTIONS ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

get_active_network_service() {
    local interface
    interface=$(route -n get default | grep 'interface:' | awk '{print $2}')
    if [ -n "$interface" ]; then
        networksetup -listallhardwareports | awk -v iface="$interface" '/Hardware Port:/{port=$3} /Device:/{dev=$2; if(dev==iface) print port}'
    fi
}

is_hiddify_connected() {
    if lsof -iTCP:"$HIDDIFY_PORT" -sTCP:LISTEN -n -P > /dev/null; then return 0; else return 1; fi
}

get_proxy_settings_as_json() {
    local service="$1"
    local json_str="{"
    for p_type in "${PROXY_TYPES[@]}"; do
        local cmd_type
        case $p_type in
            http)  cmd_type="web" ;;
            https) cmd_type="secureweb" ;;
            socks) cmd_type="socksfirewall" ;;
        esac
        
        local settings enabled server port
        settings=$(networksetup -get${cmd_type}proxy "$service")
        enabled=$(grep -q 'Enabled: Yes' <<< "$settings" && echo "true" || echo "false")
        server=$(grep 'Server:' <<< "$settings" | awk '{print $2}')
        port=$(grep 'Port:' <<< "$settings" | awk '{print $2}')
        
        json_str+="\"$p_type\":{\"enabled\":$enabled,\"server\":\"$server\",\"port\":\"$port\"},"
    done
    json_str="${json_str%,}}"
    echo "$json_str"
}

json_get() {
    local json="$1"; local query="$2"
    if command -v jq &>/dev/null; then
        jq -r "$query" <<< "$json" 2>/dev/null
    else
        local key1 key2; key1=$(echo "$query" | cut -d. -f2); key2=$(echo "$query" | cut -d. -f3)
        grep -o "\"$key1\": *{[^}]*}" <<< "$json" | grep -o "\"$key2\": *\"[^\"]*\"" | sed -e "s/\"$key2\": *\"//" -e 's/"$//' | head -n 1
    fi
}

are_settings_hiddify_compliant() {
    local settings_json="$1"
    for p_type in "${PROXY_TYPES[@]}"; do
        if [[ $(json_get "$settings_json" ".${p_type}.enabled") != "true" || \
              $(json_get "$settings_json" ".${p_type}.server") != "$HIDDIFY_SERVER" || \
              $(json_get "$settings_json" ".${p_type}.port") != "$HIDDIFY_PORT" ]]; then
            return 1
        fi
    done
    return 0
}

# --- ACTION FUNCTIONS ---

apply_settings_from_json() {
    local service="$1"; local settings_json="$2"; local source_name="$3"
    log "[ACTION] Applying settings from '$source_name' source..."
    for p_type in "${PROXY_TYPES[@]}"; do
        local enabled server port state_cmd
        enabled=$(json_get "$settings_json" ".${p_type}.enabled")
        server=$(json_get "$settings_json" ".${p_type}.server")
        port=$(json_get "$settings_json" ".${p_type}.port")
        case $p_type in
            http)  state_cmd="setwebproxy" ;;
            https) state_cmd="setsecurewebproxy" ;;
            socks) state_cmd="setsocksfirewallproxy" ;;
        esac
        
        if [[ "$enabled" == "true" ]]; then
            log "[SUB-ACTION] Setting '$p_type' proxy to: $server:$port (Enabled)"
            networksetup -${state_cmd}state "$service" on
            networksetup -${state_cmd} "$service" "$server" "$port"
        else
            log "[SUB-ACTION] Setting '$p_type' proxy to: (Disabled)"
            networksetup -${state_cmd}state "$service" off
        fi
    done
}

# --- MAIN LOGIC ---

log "--- Script Run (v8.0) ---"
ACTIVE_SERVICE=$(get_active_network_service)
if [ -z "$ACTIVE_SERVICE" ]; then
    log "[ERROR] No active network service found. Exiting."
    exit 1
fi

SYS_SETTINGS_JSON=$(get_proxy_settings_as_json "$ACTIVE_SERVICE")
if is_hiddify_connected; then HIDDIFY_STATUS="connected"; else HIDDIFY_STATUS="disconnected"; fi

PREV_STATE_JSON="{}"
if [ -f "$STATE_FILE" ]; then PREV_STATE_JSON=$(cat "$STATE_FILE"); fi
PREV_HIDDIFY_STATUS=$(json_get "$PREV_STATE_JSON" ".hiddify_status")
FOREIGN_BACKUP_JSON=$(json_get "$PREV_STATE_JSON" ".foreign_proxy_backup")
OVERRIDE_ACK=$(json_get "$PREV_STATE_JSON" ".override_acknowledged")

if [[ "$HIDDIFY_STATUS" == "connected" ]]; then
    IDEAL_HIDDIFY_JSON="{\"http\":{\"enabled\":true,\"server\":\"$HIDDIFY_SERVER\",\"port\":\"$HIDDIFY_PORT\"},\"https\":{\"enabled\":true,\"server\":\"$HIDDIFY_SERVER\",\"port\":\"$HIDDIFY_PORT\"},\"socks\":{\"enabled\":true,\"server\":\"$HIDDIFY_SERVER\",\"port\":\"$HIDDIFY_PORT\"}}"

    if [[ "$PREV_HIDDIFY_STATUS" != "connected" ]]; then
        log "[INFO] New Hiddify session started. Resetting state."
        FOREIGN_BACKUP_JSON=""
        OVERRIDE_ACK="false"
        
        IS_FOREIGN=false
        for p_type in "${PROXY_TYPES[@]}"; do
            if [[ $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.enabled") == "true" && $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.server") != "$HIDDIFY_SERVER" ]]; then
                IS_FOREIGN=true; break
            fi
        done
        if [[ "$IS_FOREIGN" == true ]]; then
            log "[BACKUP] Foreign proxy settings detected. Creating backup."
            FOREIGN_BACKUP_JSON="$SYS_SETTINGS_JSON"
        fi
    fi

    if ! are_settings_hiddify_compliant "$SYS_SETTINGS_JSON"; then
        if [[ "$OVERRIDE_ACK" == "true" ]]; then
            log "[INFO] Continuing to respect manual override. No action will be taken."
        elif [[ "$PREV_HIDDIFY_STATUS" != "connected" ]]; then
            apply_settings_from_json "$ACTIVE_SERVICE" "$IDEAL_HIDDIFY_JSON" "Hiddify"
        else
            log "[INFO] Manual override detected. Settings differ from Hiddify's ideal state. Acknowledging."
            OVERRIDE_ACK="true"
        fi
    else
        if [[ "$OVERRIDE_ACK" == "true" ]]; then OVERRIDE_ACK="false"; fi # Reset if user fixes it
        log "[INFO] Hiddify is ON and all proxies are correctly set. No action needed."
    fi
else
    OVERRIDE_ACK="false"
    NEEDS_CORRECTION=false
    for p_type in "${PROXY_TYPES[@]}"; do
        if [[ $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.enabled") == "true" && $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.server") == "$HIDDIFY_SERVER" && $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.port") == "$HIDDIFY_PORT" ]]; then
            NEEDS_CORRECTION=true; break
        fi
    done

    if [[ "$NEEDS_CORRECTION" == true ]]; then
        log "[WARN] Misconfigured Hiddify proxies detected while Hiddify is OFF. Disabling..."
        for p_type in "${PROXY_TYPES[@]}"; do
            if [[ $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.enabled") == "true" && $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.server") == "$HIDDIFY_SERVER" && $(json_get "$SYS_SETTINGS_JSON" ".${p_type}.port") == "$HIDDIFY_PORT" ]]; then
                case $p_type in
                    http)  networksetup -setwebproxystate "$ACTIVE_SERVICE" off ;;
                    https) networksetup -setsecurewebproxystate "$ACTIVE_SERVICE" off ;;
                    socks) networksetup -setsocksfirewallproxystate "$ACTIVE_SERVICE" off ;;
                esac
            fi
        done
    elif [[ -n "$FOREIGN_BACKUP_JSON" ]]; then
        if [[ "$PREV_HIDDIFY_STATUS" == "connected" ]]; then
            log "[RESTORE] Hiddify is OFF. Restoring previously backed-up foreign proxy settings."
            apply_settings_from_json "$ACTIVE_SERVICE" "$FOREIGN_BACKUP_JSON" "Backup"
            FOREIGN_BACKUP_JSON=""
        else
            log "[INFO] Hiddify is OFF. No state change. No action taken."
        fi
    else
        log "[INFO] Hiddify is OFF and no Hiddify-related proxies are active. No action needed."
    fi
fi

# Save the final state
printf '{"hiddify_status":"%s", "foreign_proxy_backup":%s, "override_acknowledged":"%s"}\n' \
    "$HIDDIFY_STATUS" \
    "${FOREIGN_BACKUP_JSON:-null}" \
    "${OVERRIDE_ACK:-false}" \
    > "$STATE_FILE"

log "--- Script End ---"