# Hiddify Smart Proxy Manager for macOS 

An intelligent script to automatically manage macOS system proxies when using the Hiddify App client. This script dynamically enables and disables system proxies based on Hiddify's connection status, resolving common issues like proxies remaining active after disconnection.

[![macOS](https://img.shields.io/badge/macOS-Sonoma%2B-blue.svg)](https://www.apple.com/macos/sonoma/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-lightgrey.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

[**Persian Readme (نسخه فارسی)**](./README.fa.md)

---

### The Problem This Solves

Many users prefer running the Hiddify App in **System Proxy** mode instead of **VPN (TUN)** mode, especially when using other VPN-based applications like AdGuard. However, the proxy mode has its drawbacks:
- **Stuck Proxies:** Sometimes, after disconnecting or an unexpected crash of Hiddify, the system proxy settings are not reverted, leading to a loss of internet connectivity.
- **Conflict with Other Proxies:** Managing Hiddify's proxy alongside other configurations (e.g., a work proxy) can be cumbersome.
- **Manual Toggling:** Manually enabling and disabling proxies with every connection is tedious.

This script intelligently manages this entire process for you, running silently in the background.

### ✨ Features

- **Auto Toggle:** System proxies are automatically **enabled** when you connect to Hiddify and **disabled** upon disconnection.
- **Smart Backup & Restore:** If you use another proxy before connecting to Hiddify, the script **backs up** its settings and **restores** them after you disconnect from Hiddify.
- **Respects User Overrides:** If you manually change or disable a proxy while connected, the script detects this, **respects your choice**, and will not interfere until the next connection cycle.
- **Automatic Cleanup:** Identifies and disables proxies that are incorrectly left active with Hiddify's configuration.
- **Comprehensive Logging:** All actions are logged for easy troubleshooting.
- **User-Friendly Installer:** Comes with an easy-to-use installer that automates the entire setup.

### ✅ Prerequisites

- **macOS:** Tested and debugged on macOS Sequoia (15.5) and Sonoma (14.x).
- **Hiddify App Client:** The script is designed for the official Hiddify client (v2.5.7+).
- **Terminal Access:** Required for installation.

---

### 🚀 Installation

There are two methods for installation: Easy (Recommended) and Manual.

#### Method 1: Easy Install (Recommended)

1.  Clone or download this repository as a ZIP file and unzip it.
2.  Open the **Terminal** app.
3.  Navigate to the downloaded folder using the `cd` command. For example: `cd ~/Downloads/hiddify-proxy-manager-main`
4.  Run the installer script:
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
5.  The installer will ask for your Hiddify **Mixed Port**. The default is `12334`. You can find this in your Hiddify App under `Config Options > Inbound Options > Mixed Port`.
6.  Follow the final instructions provided by the installer to grant **Full Disk Access**, which is a necessary step.

#### Method 2: Manual Installation

<details>
<summary>Click here for manual installation steps</summary>

1.  **Place the Files:**
    -   Copy `manager.sh` to a permanent location, for example: `mkdir -p ~/scripts && cp manager.sh ~/scripts/`
    -   Copy `template.plist` to the same directory.

2.  **Configure the Script:**
    -   Open `~/scripts/manager.sh` with a text editor.
    -   In the `CONFIGURATION` section, change the `HIDDIFY_PORT` value to your Hiddify's Mixed Port.

3.  **Configure the Service File:**
    -   Open `~/scripts/template.plist`.
    -   Replace the placeholder `PLACEHOLDER_SCRIPT_PATH` with the absolute path to your `manager.sh` file (e.g., `/Users/your_username/scripts/manager.sh`).
    -   Rename the file to `com.user.hiddifyproxymanager.plist`.

4.  **Deploy and Load the Service:**
    -   Move the configured plist file to the `LaunchAgents` directory: `mv ~/scripts/com.user.hiddifyproxymanager.plist ~/Library/LaunchAgents/`
    -   Load the service using Terminal:
        ```bash
        launchctl load ~/Library/LaunchAgents/com.user.hiddifyproxymanager.plist
        ```

5.  **Grant Full Disk Access:**
    -   Go to `System Settings > Privacy & Security > Full Disk Access`.
    -   Click the `+` button, press `Cmd+Shift+G`, and enter `/bin/bash`.
    -   Select the `bash` executable and enable the switch next to it in the list.

</details>

---

### 🔧 Troubleshooting

If the script isn't working as expected, the log files are your best friend. You can find them in the `/tmp/` directory:
- **Main Log:** `/tmp/hiddify_proxy.log`
- **Error Log:** `/tmp/hiddify_proxy.stderr.log`

You can watch the script's activity live with this command in Terminal:
```bash
tail -f /tmp/hiddify_proxy.log
```
The most common issue is not granting **Full Disk Access** to `/bin/bash`, which results in `Operation not permitted` errors in the `stderr.log`.

### 🗑️ Uninstall

To completely remove the script and its components, run the installer with the `uninstall` argument from the project directory:
```bash
./install.sh uninstall
```
This will stop the service, remove all installed files, and clean up the logs.

---

### 💼 Commercial Use & Licensing

This software is free for personal, non-commercial use. You are free to edit, upgrade, and redistribute it under the condition that attribution is given to the original GitHub repository. Any redistribution must be under the same license.

**A paid license is required for:**
-   Use in companies with 5 or more employees.
-   Any direct commercial use (even by a single person).
-   Inclusion or use of any part of this script in another software product.

For commercial licensing inquiries, please contact me at: **moderndesigner AT outlook dot com**

### 💰 Donations

If you find this script useful and wish to support its development, you can donate via the following addresses. Thank you!

- **BTC (Bitcoin):** `bc1pjrvk5r5um3hy4q8zzp40ecmfmhcpwhlx4t9nxrdc8etupz8qnmfqx2weqp`
- **BTCB, ETH, USDT, BNB n all EVMs (Evm, Bsc Bep20, Arbitrom):** `0xbb1F9f7868416C3eB9DEfc075aD3d1Fb5c36699F`
- **USDT (TRC20 Tron):** `TAcUvvVNU1c6F21cfkKKwdm2RUE5YnTzsS`
- **TON (TON):** `UQC0fjghhRzO-Xo-n0MmMa8eSvn10Y8UB1s8qr09LT6DXVjO`
- **SOL (Solana):** `Fp4uWu1dLRDeWvSxufh8BWm48FnFsLQwXNLDk6bbYFr1`
- **XRP (Ripple):** `rUXpNRn989XQ1nJyvfHvL2BgndAgZToL33`

### 🤝 Contribution & Hiddify Team Referral

If you find this script useful, feel free to introduce it to the Hiddify App developers. The best way is to create a "Discussion" or "Issue" in the [official Hiddify App GitHub repository](https://github.com/hiddify/hiddify-app).

You can explain the problem this script solves for macOS users in proxy mode and provide a link to this repository. This could help improve the user experience for everyone.

### 📜 License

This project is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).
