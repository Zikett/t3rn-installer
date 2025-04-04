## ⚙️ T3rn Executor Installer

> **Note:** This script is an unofficial installer that helps you install and manage the [T3rn Executor](https://github.com/t3rn/executor-release) — an open-source project by the T3rn team.
> It does not modify or replace the official binaries
---

## 🚀 Features

- ✅ Checks required dependencies (`curl`, `wget`, `tar`, `jq`)
- 📦 Install latest or custom Executor version
- ⚙️ Creates a `systemd` service for background execution
- 🌐 RPC Manager
- 🔐 Set or update `PRIVATE_KEY_LOCAL`
- ⛽ Configure `EXECUTOR_MAX_L3_GAS_PRICE`
- 🧠 Toggle flags:
  - `EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API`
  - `EXECUTOR_PROCESS_ORDERS_API_ENABLED`
- 📜 Live log viewer via `journalctl`
- 🔁 Restart executor
- 🧹 Full uninstall
- 📋 `systemd` status check

---

## 🛡️ Privacy & Security

> Your data stays **completely local**.

- 🔐 **Private keys** are only stored in-memory as environment variables and **never saved to disk**.
- 📡 **No data is transmitted externally** except direct calls to public APIs (e.g. GitHub for release versions).
- 📝 **No persistent logs** or local log files are created by the script.
- 📁 All files and configurations are stored under your `$HOME/t3rn/` directory.
- ❌ Nothing is uploaded, shared, or tracked. This tool is fully offline and privacy-respecting by design.

---

## 📦 Installation & Usage

## 🔧 Option 1: One-Liner Quick Install

You can run the installer instantly with a single command:

```bash
bash <(wget -qO - https://raw.githubusercontent.com/Zikett/t3rn-installer/main/t3rn-installer.sh)
```

## ⚡ Option 2: Clone & Run

```bash
git clone https://github.com/Zikett/t3rn-installer.git
cd t3rn-installer
chmod +x t3rn-installer.sh
./t3rn-installer.sh
```
## 📋 Menu Options Overview

## 📦 Installation
- **1) Install / Update Executor**  
  Downloads and installs the T3rn Executor (latest or specific version), configures it, and sets it up as a systemd service.

- **2) Uninstall Installer & Executor**  
  Completely removes the T3rn installation, including configuration and systemd service.

## 🛠️ Configuration

- **3) View Executor Logs**  
  Streams the latest logs from the executor service via `journalctl`.

- **4) Show Configured RPCs**  
  Displays the currently configured RPC endpoints for supported networks.

- **5) Edit RPC Endpoints**  
  Allows you to update the RPC URLs for each supported network.
  
  ⚠️ **Note:** Custom RPC endpoints set via this option are temporary — they are not saved between script runs.  
  They are applied to the currently running executor and will remain active until you restart it.  
  **If you restart the executor later, you'll need to re-apply the custom RPCs using this menu option again.**

- **6) Set Max L3 Gas Price**  
  Changes the maximum allowed Layer 3 gas price for the executor.

- **7) Configure Order API Flags**  
  Enables or disables flags related to processing orders via the API.

- **8) Set / Update Private Key**  
  Sets or updates the private key used by the executor (without `0x` prefix).

## 🔁 Executor Control

- **9) Restart Executor**  
  Rebuilds the configuration and restarts the T3rn executor systemd service.

- **10) View Executor Status [systemd]**  
  Shows the current status of the executor using `systemctl`.

## 🔚 Exit
- **0) Exit**  
  Closes the installer menu.


## ✅ Requirements

Make sure these tools are installed:

```bash
sudo apt update && sudo apt install -y curl wget tar jq
```

---

## 📄 License

MIT License
