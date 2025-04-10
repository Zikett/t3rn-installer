#!/bin/bash
VERSION="v1.0.0"

if ! command -v sudo &>/dev/null; then
    echo "⚠️  'sudo' is not installed. It is required for this script to work properly."
    read -p "📦  Do you want to install 'sudo' now? (Y/n): " install_sudo
    install_sudo=${install_sudo,,}

    if [[ -z "$install_sudo" || "$install_sudo" == "y" || "$install_sudo" == "yes" ]]; then
        if command -v apt &>/dev/null; then
            echo "🔐  Installing sudo (root password will be required)..."
            su -c "apt update && apt install -y sudo"
        elif command -v yum &>/dev/null; then
            echo "🔐  Installing sudo (root password will be required)..."
            su -c "yum install -y sudo"
        else
            echo "❌  Unsupported package manager. Please install 'sudo' manually and rerun the script."
            exit 1
        fi

        if ! command -v sudo &>/dev/null; then
            echo "❌  Failed to install sudo. Please install it manually."
            exit 1
        fi
    else
        echo "❌  Cannot continue without 'sudo'. Exiting."
        exit 1
    fi
fi

required_tools=(sudo curl wget tar jq lsof)
missing=()
installed=()

for tool in "${required_tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        installed+=("$tool")
    else
        missing+=("$tool")
    fi
done

echo -n "🔧  Installed tools: "
echo "${installed[*]}"
echo ""
echo "🛠️  T3rn Installer — Version $VERSION"

for tool in "${missing[@]}"; do
    echo "❌  $tool is missing."
    read -p "📦  Do you want to install '$tool'? (Y/n): " reply
    reply=${reply,,}
    if [[ -z "$reply" || "$reply" == "y" || "$reply" == "yes" ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y "$tool"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "$tool"
        else
            echo "⚠️  Package manager not recognized. Please install '$tool' manually."
            exit 1
        fi
    else
        echo "⚠️  '$tool' is required. Exiting."
        exit 1
    fi
done

declare -A rpcs=(
    ["l2rn"]="https://b2n.rpc.caldera.xyz/http"
    ["arbt"]="https://arbitrum-sepolia-rpc.publicnode.com https://sepolia-rollup.arbitrum.io/rpc"
    ["bast"]="https://base-sepolia-rpc.publicnode.com https://sepolia.base.org"
    ["blst"]="https://sepolia.blast.io"
    ["opst"]="https://optimism-sepolia-rpc.publicnode.com https://sepolia.optimism.io"
    ["unit"]="https://unichain-sepolia-rpc.publicnode.com https://sepolia.unichain.org"
    ["mont"]="https://testnet-rpc.monad.xyz"
)

declare -A network_names=(
    ["l2rn"]="B2N Testnet"
    ["arbt"]="Arbitrum Sepolia"
    ["bast"]="Base Sepolia"
    ["blst"]="Blast Sepolia"
    ["opst"]="Optimism Sepolia"
    ["unit"]="Unichain Sepolia"
    ["mont"]="Monad Testnet"
)

install_executor() {
    while true; do
        echo ""
        echo "====== Executor Version Selection ======"
        echo "1) Install latest version"
        echo "2) Install specific version"
        echo ""
        echo "0) Back to main menu"
        echo ""
        read -p "Select an option [0–2] and press Enter: " ver_choice
        case $ver_choice in
            0) return;;
            1)
                TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
                break
                ;;
            2)
                read -p "🔢  Enter version (e.g. 0.60.0): " input_version
                input_version=$(echo "$input_version" | xargs)
                if [[ -z "$input_version" ]]; then
                    echo "↩️  No version entered. Returning to version selection."
                    continue
                fi
                if [[ $input_version != v* ]]; then
                    TAG="v$input_version"
                else
                    TAG="$input_version"
                fi
                break
                ;;
            *)
                echo "❌  Invalid option."
                ;;
        esac
    done

for dir in "$HOME/t3rn" "$HOME/executor"; do
    if [[ -d "$dir" ]]; then
        echo "📁  Directory '$(basename "$dir")' already exists."
        read -p "❓  Do you want to remove it? (y/N): " confirm_dir
        confirm_dir=$(echo "$confirm_dir" | tr '[:upper:]' '[:lower:]' | xargs)
        if [[ "$confirm_dir" == "y" || "$confirm_dir" == "yes" ]]; then
            if [[ "$(pwd)" == "$dir"* ]]; then
                cd ~ || exit 1
            fi
            echo "🧹  Removing $dir..."
            rm -rf "$dir"
        else
            echo "🚫  Installation cancelled due to existing directory: $dir"
            return
        fi
    fi
done

if lsof -i :9090 &>/dev/null; then
    echo "⚠️  Port 9090 is currently in use."
    pid_9090=$(lsof -ti :9090)
    echo "🔪  Killing process using port 9090 (PID: $pid_9090)..."
    kill -9 $pid_9090
    sleep 1
    echo "✅  Port 9090 is now free."
fi

    mkdir -p "$HOME/t3rn" && cd "$HOME/t3rn" || exit 1
    if [[ -z "$TAG" ]]; then
        echo "❌  Failed to determine executor version tag. Aborting installation."
        return
    fi
    echo "⬇️  Downloading executor version $TAG..."
    wget --quiet --show-progress https://github.com/t3rn/executor-release/releases/download/${TAG}/executor-linux-${TAG}.tar.gz
    tar -xzf executor-linux-${TAG}.tar.gz
    rm -f executor-linux-${TAG}.tar.gz
    cd executor/executor/bin || exit 1

    export ENVIRONMENT=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_PROCESS_ORDERS_ENABLED=true
    export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,blast-sepolia,unichain-sepolia,monad-testnet'
    export EXECUTOR_MAX_L3_GAS_PRICE=1000
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
    export EXECUTOR_PROCESS_BIDS_API_INTERVAL_SEC=30
    export EXECUTOR_MIN_BALANCE_THRESHOLD_ETH=1
    while true; do

    read -p "🔑  Enter PRIVATE_KEY_LOCAL (without 0x): " private_key
    private_key=$(echo "$private_key" | sed 's/^0x//' | xargs)
    if [[ -z "$private_key" ]]; then
        echo -e "⚠️  Private key is empty."
        while true; do
            echo -e "\n❓  Do you want to continue without setting the private key?"
            echo "1) 🔁  Go back and enter private key"
            echo "2) ⏩  Continue installation without private key"
            echo ""
            echo "0) ❌  Cancel installation"
            echo ""
            read -p "Select an option [0–2] and press Enter: " pk_choice
            case $pk_choice in
                1)
                    read -p "🔑  Enter PRIVATE_KEY_LOCAL (without 0x): " private_key
                    if [[ -n "$private_key" ]]; then
                        break
                    else
                        echo "⚠️  Still empty. Try again."
                    fi
                    ;;
                2)
                    echo "⚠️  Continuing without a private key. Executor may fail to start."
                    break
                    ;;
                0)
                    echo "❌  Installation cancelled."
                    return
                    ;;
                *)
                    echo "❌  Invalid option. Please choose 1, 2 or 0."
                    ;;
            esac
        done
    fi
    break
done

    export PRIVATE_KEY_LOCAL=$private_key

    rpc_json="{"
    for key in "l2rn" "arbt" "bast" "blst" "opst" "unit" "mont"; do
        urls_string=${rpcs[$key]}
        rpc_json+="\"$key\": ["
        for url in $urls_string; do
            rpc_json+="\"$url\", "
        done
        rpc_json="${rpc_json%, }], "
    done
    rpc_json="${rpc_json%, }"; rpc_json+='}'
    export RPC_ENDPOINTS="$rpc_json"

    if ! validate_config_before_start; then
        echo "❌ Aborting due to invalid configuration."
        return
    fi

    create_systemd_unit

    cd ../../..
}

validate_config_before_start() {
    echo -e "\n🧪 Validating configuration before starting executor..."
    local error=false

    if [[ -z "$PRIVATE_KEY_LOCAL" ]]; then
        echo "❌ PRIVATE_KEY_LOCAL is not set."
        error=true
    elif [[ ! "$PRIVATE_KEY_LOCAL" =~ ^[a-fA-F0-9]{64}$ ]]; then
        echo "❌ PRIVATE_KEY_LOCAL format is invalid. Should be 64 hex characters (without 0x)."
        error=true
    fi

    if [[ -z "$RPC_ENDPOINTS" ]]; then
        echo "❌ RPC_ENDPOINTS is empty or not set."
        error=true
    else
        if ! echo "$RPC_ENDPOINTS" | jq empty &>/dev/null; then
            echo "❌ RPC_ENDPOINTS is not valid JSON."
            error=true
        fi
    fi

    if [[ -z "$ENABLED_NETWORKS" ]]; then
        echo "❌ ENABLED_NETWORKS is not set."
        error=true
    fi

    local bin_path="$HOME/t3rn/executor/executor/bin/executor"
    if [[ ! -f "$bin_path" ]]; then
        echo "❌ Executor binary not found at: $bin_path"
        error=true
    elif [[ ! -x "$bin_path" ]]; then
        echo "❌ Executor binary is not executable. Try: chmod +x $bin_path"
        error=true
    fi

    for flag in EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API EXECUTOR_PROCESS_ORDERS_API_ENABLED; do
        val="${!flag}"
        if [[ "$val" != "true" && "$val" != "false" ]]; then
            echo "❌ $flag must be 'true' or 'false'. Got: '$val'"
            error=true
        fi
    done

    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if (( available_space < 500000 )); then
        echo "⚠️  Less than 500MB of free space available in home directory."
    fi

    if ! command -v systemctl &> /dev/null; then
        echo "❌ systemctl is not available. This script relies on systemd."
        error=true
    fi

    if ! sudo -n true 2>/dev/null; then
        echo "⚠️  You might be prompted for a sudo password during setup."
    fi

    if [[ "$error" == true ]]; then
        echo -e "\n⚠️  Configuration invalid. Please fix the above issues before proceeding.\n"
        return 1
    else
        echo "✅ All checks passed. Configuration looks valid!"
        return 0
    fi
}

create_systemd_unit() {
    UNIT_PATH="/etc/systemd/system/t3rn-executor.service"
    rpc_escaped=$(echo "$RPC_ENDPOINTS" | jq -c . | sed 's/"/\\"/g')

    sudo bash -c "cat > $UNIT_PATH" <<EOF
[Unit]
Description=T3rn Executor Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/t3rn/executor/executor/bin

Environment=ENVIRONMENT=testnet
Environment=LOG_LEVEL=${LOG_LEVEL}
Environment=LOG_PRETTY=${LOG_PRETTY}
Environment=EXECUTOR_PROCESS_BIDS_ENABLED=${EXECUTOR_PROCESS_BIDS_ENABLED}
Environment=EXECUTOR_PROCESS_ORDERS_ENABLED=${EXECUTOR_PROCESS_ORDERS_ENABLED}
Environment=EXECUTOR_PROCESS_CLAIMS_ENABLED=${EXECUTOR_PROCESS_CLAIMS_ENABLED}
Environment=EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=${EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API}
Environment=EXECUTOR_PROCESS_ORDERS_API_ENABLED=${EXECUTOR_PROCESS_ORDERS_API_ENABLED}
Environment=EXECUTOR_MAX_L3_GAS_PRICE=${EXECUTOR_MAX_L3_GAS_PRICE}
Environment=PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL}
Environment=ENABLED_NETWORKS=${ENABLED_NETWORKS}
Environment=NETWORKS_DISABLED='${NETWORKS_DISABLED}'
Environment=RPC_ENDPOINTS=$rpc_escaped
Environment=EXECUTOR_PROCESS_BIDS_API_INTERVAL_SEC=30
Environment=EXECUTOR_MIN_BALANCE_THRESHOLD_ETH=1

ExecStart=$HOME/t3rn/executor/executor/bin/executor
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now t3rn-executor
    echo "✅  Systemd service 't3rn-executor' installed and started."
    sleep 0.3

    if systemctl is-active --quiet t3rn-executor; then
        echo "🚀  Executor is running."
    else
        echo "❌  Executor failed to start. Run option 10 to check status."
    fi
}

rebuild_rpc_endpoints() {
    rpc_json=$(jq -n '{
        l2rn: $l2rn,
        arbt: $arbt,
        bast: $bast,
        blst: $blst,
        opst: $opst,
        unit: $unit,
        mont: $mont
    }' \
        --argjson l2rn "$(printf '%s\n' ${rpcs[l2rn]} | jq -R . | jq -s .)" \
        --argjson arbt "$(printf '%s\n' ${rpcs[arbt]} | jq -R . | jq -s .)" \
        --argjson bast "$(printf '%s\n' ${rpcs[bast]} | jq -R . | jq -s .)" \
        --argjson blst "$(printf '%s\n' ${rpcs[blst]} | jq -R . | jq -s .)" \
        --argjson opst "$(printf '%s\n' ${rpcs[opst]} | jq -R . | jq -s .)" \
        --argjson unit "$(printf '%s\n' ${rpcs[unit]} | jq -R . | jq -s .)" \
        --argjson mont "$(printf '%s\n' ${rpcs[mont]} | jq -R . | jq -s .)"
)

    export RPC_ENDPOINTS="$rpc_json"
}

edit_rpc_menu() {
    echo -e "\n🌐  Edit RPC Endpoints"
    local changes_made=false

    for net in "l2rn" "arbt" "bast" "blst" "opst" "unit" "mont"; do
        name=${network_names[$net]}
        echo "🔗  Enter new RPC URL(s) for $name, separated by space (or press Enter to keep current):"
        echo "    Current: ${rpcs[$net]}"
        read -p "> " input

        if [[ -n $input ]]; then
            rpcs[$net]="$input"
            echo "✅  RPCs updated."
            changes_made=true
        fi
    done

    if [[ "$changes_made" == true ]]; then
        rebuild_rpc_endpoints
        echo -e "✅  RPC endpoints updated."
        echo -e "🔄  Restart required to apply changes. Use option [11] in the main menu."
    else
        echo -e "\nℹ️  No RPC endpoints were changed."
    fi
}

uninstall_t3rn() {
    read -p "❗  Are you sure you want to completely remove T3rn Installer and Executor? (y/N): " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]' | xargs)

    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "🚫  Uninstall cancelled."
        return
    fi

    echo "🗑️  Uninstalling T3rn Installer and Executor..."

    sudo systemctl disable --now t3rn-executor.service 2>/dev/null
    sudo rm -f /etc/systemd/system/t3rn-executor.service
    sudo systemctl daemon-reload

    for dir in "$HOME/t3rn" "$HOME/executor"; do
        if [[ -d "$dir" ]]; then
            if [[ "$(pwd)" == "$dir"* ]]; then
                cd ~ || exit 1
            fi
            echo "🧹  Removing directory: $dir"
            rm -rf "$dir"
        fi
    done

    sudo journalctl --rotate
    sudo journalctl --vacuum-time=1s

    echo "✅  T3rn Installer and Executor have been removed."
}

configure_disabled_networks() {
    echo -e "\n🛑  Disable Networks"
    echo "Select networks you want to disable."
    echo "Enter the numbers (e.g. 1 3 5 or 135):"
    echo ""

    local i=1
    declare -A index_to_key

    for key in "${!network_names[@]}"; do
        echo "$i) ${network_names[$key]}"
        index_to_key[$i]="$key"
        ((i++))
    done

    echo ""
    read -p "➡️  Enter numbers of networks to disable: " raw_input

    input=$(echo "$raw_input" | tr -d '[:space:]')
    if [[ -z "$input" ]]; then
        echo "ℹ️  No input provided. No networks disabled."
        return
    fi

    if ! echo "$input" | grep -Eq '^[1-7]+$'; then
        echo "❌  Invalid input. Only digits 1 to 7 are allowed."
        return
    fi

    declare -A seen
    local disabled_networks=()
    for (( i=0; i<${#input}; i++ )); do
        digit="${input:$i:1}"
        if [[ -n "${seen[$digit]}" ]]; then continue; fi
        seen[$digit]=1

        short_key="${index_to_key[$digit]}"
        full_name="${network_names[$short_key]}"
        if [[ -n "$full_name" ]]; then
            id_name=$(echo "$full_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
            disabled_networks+=("$id_name")
        fi
    done

    if [[ ${#disabled_networks[@]} -eq 0 ]]; then
        echo "ℹ️  No valid selections made. No networks disabled."
    else
        export NETWORKS_DISABLED="$(IFS=','; echo "${disabled_networks[*]}")"

        echo -e "\n✅  Networks to be disabled:"
        for net in "${disabled_networks[@]}"; do
            readable_name=$(echo "$net" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            echo "   • $readable_name"
        done

        local enabled_networks=()
        for key in "${!network_names[@]}"; do
            name_kebab=$(echo "${network_names[$key]}" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
            if [[ ! " ${disabled_networks[*]} " =~ " $name_kebab " ]]; then
                enabled_networks+=("$name_kebab")
            fi
        done

        echo -e "\n🔄  Restart required to apply changes. Use option [11] in the main menu."
    fi
}


enable_networks() {
    echo -e "\n✅  Enable Networks"

    if [[ -z "$NETWORKS_DISABLED" ]]; then
        echo "ℹ️  No networks are currently disabled."
        return
    fi

    IFS=',' read -ra disabled <<< "$NETWORKS_DISABLED"

    echo "Currently disabled networks:"
    local i=1
    declare -A index_to_network
    for net in "${disabled[@]}"; do
        readable_name=$(echo "$net" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        echo "$i) $readable_name"
        index_to_network[$i]="$net"
        ((i++))
    done

    echo ""
    read -p "➡️  Enter numbers of networks to enable (e.g. 1 2 3 or 123): " raw_input

    input=$(echo "$raw_input" | tr -d '[:space:]')

    if [[ -z "$input" ]]; then
        echo "ℹ️  No input provided. Disabled networks remain unchanged."
        return
    fi

    local max_index=${#index_to_network[@]}
    if ! echo "$input" | grep -Eq "^[1-$max_index]+$"; then
        echo "❌  Invalid input. Only digits 1 to $max_index are allowed."
        return
    fi

    declare -A selected
    for (( i=0; i<${#input}; i++ )); do
        digit="${input:$i:1}"
        selected[$digit]=1
    done

    local remaining=()
    local reenabled=()
    for i in "${!index_to_network[@]}"; do
        if [[ -z "${selected[$i]}" ]]; then
            remaining+=("${index_to_network[$i]}")
        else
            reenabled+=("${index_to_network[$i]}")
        fi
    done

    if [[ ${#remaining[@]} -eq 0 ]]; then
        unset NETWORKS_DISABLED
        echo "✅  All networks enabled."
    else
        export NETWORKS_DISABLED="$(IFS=','; echo "${remaining[*]}")"
    fi

    echo -e "\n✅  Networks that were enabled:"
    for net in "${reenabled[@]}"; do
        readable_name=$(echo "$net" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        echo "   • $readable_name"
    done

    echo -e "\n🔄  Restart required to apply changes. Use option [11] in the main menu."
}


while true; do
    echo ""
    echo "====== ⚙️  T3rn Installer Menu ======"
    echo ""
    echo "📦  Installation"
    echo "1) Install / Update Executor"
    echo "2) Uninstall Installer & Executor"
    echo ""
    echo "🛠️  Configuration"
    echo "3) View Executor Logs"
    echo "4) Show Configured RPCs"
    echo "5) Edit RPC Endpoints"
    echo "6) Set Max L3 Gas Price"
    echo "7) Configure Order API Flags"
    echo "8) Set / Update Private Key"
    echo "9) Disable Networks"
    echo "10) Enable Networks"
    echo ""
    echo "🔁  Executor Control"
    echo "11) Restart Executor"
    echo "12) View Executor Status [systemd]"
    echo ""
    echo "0) Exit"
    echo ""
    read -p "➡️  Select an option [0–12] and press Enter: " opt

    case $opt in
        1) install_executor;;
        2) uninstall_t3rn;;
        3)
            echo "📜  Viewing executor logs (without timestamps/hostnames)..."
            sudo journalctl -u t3rn-executor -f --no-pager --output=cat;;
        4)
            echo -e "\n🌐  Current RPC Endpoints:"
            echo ""
            for net in "${!rpcs[@]}"; do
                echo "- ${network_names[$net]}:"
                for url in ${rpcs[$net]}; do
                    echo "   • $url"
                done
                echo ""
            done;;
        5) edit_rpc_menu;;

        6)
            read -p "⛽  Enter new Max L3 gas price: " gas

            if [[ -z "$gas" ]]; then
                echo "ℹ️  No input provided. Gas price unchanged."
            elif ! [[ "$gas" =~ ^[0-9]+$ ]]; then
                echo "❌  Invalid gas price. Must be a number."
            else
                export EXECUTOR_MAX_L3_GAS_PRICE=$gas
                echo "✅  New gas price set to $EXECUTOR_MAX_L3_GAS_PRICE."
                echo "🔄  Restart required to apply changes. Use option [11] in the main menu."
            fi
            ;;

        7)
            read -p "🔧  EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API (true/false, default: true): " val1
            read -p "🔧  EXECUTOR_PROCESS_ORDERS_API_ENABLED (true/false, default: true): " val2

            if [[ -z "$val1" && -z "$val2" ]]; then
                echo "ℹ️  No input provided. Flags remain unchanged."
            else
                valid=true
                for flag in "$val1" "$val2"; do
                    if [[ -n "$flag" && "$flag" != "true" && "$flag" != "false" ]]; then
                        echo "❌  Invalid value: '$flag'. Allowed values are 'true' or 'false'."
                        valid=false
                    fi
                done

                if [[ "$valid" == true ]]; then
                    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=${val1:-true}
                    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=${val2:-true}
                    echo "✅  Order processing flags updated."
                    echo "🔄  Restart required to apply changes. Use option [11] in the main menu."
                fi
            fi
            ;;

        8)
            read -p "🔑  Enter new PRIVATE_KEY_LOCAL (without 0x): " pk
            pk=$(echo "$pk" | sed 's/^0x//' | xargs)
            if [[ -n "$pk" ]]; then
                export PRIVATE_KEY_LOCAL=$pk
                echo "✅  Private key updated."
                echo "🔄  Restart required to apply changes. Use option [11] in the main menu."
            else
                echo "ℹ️  No input provided. Private key unchanged."
            fi;;
        11)
            echo "🔁  Restarting executor..."
            rebuild_rpc_endpoints
            create_systemd_unit
            if sudo systemctl restart t3rn-executor; then
                echo "✅  Executor restarted successfully."
            else
                echo "❌  Failed to restart executor. Please check the systemctl logs."
            fi;;
        12)
            echo "🔍  Checking Executor status using systemd..."
            sleep 0.3
            systemctl status t3rn-executor --no-pager || echo "❌  Executor is not running.";;

        9) configure_disabled_networks;;
        10) enable_networks;;

        0)
            echo "👋  Exiting. Goodbye!"
            exit 0;;
        *) echo "❌  Invalid option. Please try again.";;
    esac
done
