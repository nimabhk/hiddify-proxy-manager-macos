#!/bin/bash

# ==============================================================================
#  Installer for Hiddify Smart Proxy Manager for macOS by NimaBehkar (moderndesigner@outlook.com)
# ==============================================================================

# --- Configuration ---
SCRIPT_NAME="hiddify-proxy-manager.sh"
PLIST_TEMPLATE_NAME="template.plist"
PLIST_FINAL_NAME="com.user.hiddifyproxymanager.plist"
INSTALL_DIR="$HOME/.local/share/hiddify-proxy-manager"
PLIST_DIR="$HOME/Library/LaunchAgents"

# --- Colors for output ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

# --- Functions ---

install() {
    echo -e "${C_BLUE}--- Starting Hiddify Smart Proxy Manager Installation ---${C_NC}"

    # 1. Get user configuration
    read -p "Please enter your Hiddify Mixed Port (default: 12334): " HIDDIFY_PORT
    HIDDIFY_PORT=${HIDDIFY_PORT:-12334}
    echo -e "${C_GREEN}Port set to $HIDDIFY_PORT.${C_NC}"

    # 2. Create installation directory
    echo "Creating installation directory at: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    # 3. Copy and configure the main script
    echo "Copying and configuring the main script..."
    cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    # Replace placeholder with user-provided port
    sed -i '' "s/PLACEHOLDER_PORT/$HIDDIFY_PORT/g" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

    # 4. Copy and configure the launchd plist file
    echo "Copying and configuring the service file..."
    FULL_SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
    cp "$PLIST_TEMPLATE_NAME" "$PLIST_DIR/$PLIST_FINAL_NAME"
    # Replace placeholder with the full script path
    sed -i '' "s|PLACEHOLDER_SCRIPT_PATH|$FULL_SCRIPT_PATH|g" "$PLIST_DIR/$PLIST_FINAL_NAME"

    # 5. Load the service
    echo "Loading the background service..."
    # Unload first to ensure a clean start
    launchctl unload "$PLIST_DIR/$PLIST_FINAL_NAME" 2>/dev/null
    launchctl load "$PLIST_DIR/$PLIST_FINAL_NAME"
    
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}Service loaded successfully.${C_NC}"
    else
        echo -e "${C_RED}Error: Failed to load the service. Aborting.${C_NC}"
        uninstall
        exit 1
    fi

    # 6. Final instructions for the user
    echo -e "\n${C_YELLOW}--- ⚠️ IMPORTANT: Manual Action Required ---${C_NC}"
    echo "For the script to work, it needs Full Disk Access."
    echo "1. Go to System Settings > Privacy & Security > Full Disk Access."
    echo "2. Click the '+' button."
    echo "3. Press Command+Shift+G, type '/bin/bash' and click Go."
    echo "4. Select the 'bash' file and click Open."
    echo "5. Make sure the switch next to 'bash' is enabled in the list."
    echo -e "\nThe service might need a moment to start. You can check its status with:"
    echo -e "${C_BLUE}tail -f /tmp/hiddify_proxy.log${C_NC}"

    echo -e "\n${C_GREEN}🎉 Installation finished successfully!${C_NC}"
}

uninstall() {
    echo -e "${C_BLUE}--- Uninstalling Hiddify Smart Proxy Manager ---${C_NC}"

    # 1. Unload the service
    echo "Stopping and unloading the service..."
    launchctl unload "$PLIST_DIR/$PLIST_FINAL_NAME" 2>/dev/null

    # 2. Remove files
    echo "Removing files..."
    rm -f "$PLIST_DIR/$PLIST_FINAL_NAME"
    rm -rf "$INSTALL_DIR"
    rm -f /tmp/hiddify_manager.state.json
    rm -f /tmp/hiddify_proxy.log
    rm -f /tmp/hiddify_proxy.stderr.log
    rm -f /tmp/hiddify_proxy.stdout.log

    echo -e "\n${C_GREEN}✅ Uninstallation complete.${C_NC}"
}

# --- Main Logic ---
if [ "$1" == "uninstall" ]; then
    uninstall
else
    install
fi
