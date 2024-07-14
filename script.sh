#!/bin/bash

# Fungsi untuk mencetak teks berwarna
print_color() {
    local color=$1
    local text=$2
    echo -e "\033[${color}m${text}\033[0m"
}

# Fungsi untuk meminta input dengan validasi
get_input() {
    local prompt=$1
    local var_name=$2
    local validation=$3
    while true; do
        print_color "1;34" "$prompt"
        read $var_name
        if [[ -n "$validation" ]] && ! eval "$validation"; then
            print_color "1;31" "Input tidak valid. Silakan coba lagi."
        else
            break
        fi
    done
}

# Meminta input dengan validasi
get_input "Enter RPC URL of the network:" providerURL
get_input "Enter private key:" privateKeys
get_input "Enter contract address:" contractAddress '[[ $contractAddress =~ ^0x[a-fA-F0-9]{40}$ ]]'
get_input "Enter transaction data (in hex):" transactionData '[[ $transactionData =~ ^0x[a-fA-F0-9]+$ ]]'
get_input "Enter gas limit:" gasLimit '[[ $gasLimit =~ ^[0-9]+$ ]]'
get_input "Enter gas price (in gwei):" gasPrice '[[ $gasPrice =~ ^[0-9]+(\.[0-9]+)?$ ]]'
get_input "Enter number of transactions to send:" numberOfTransactions '[[ $numberOfTransactions =~ ^[0-9]+$ ]]'

# Memeriksa dan menginstal ethers jika diperlukan
if ! npm list ethers@5.5.4 >/dev/null 2>&1; then
    print_color "1;34" "Installing ethers..."
    npm install ethers@5.5.4
else
    print_color "1;34" "Ethers is already installed."
fi

# Membuat file JavaScript sementara
temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)
cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "${providerURL}";
const provider = new ethers.providers.JsonRpcProvider(providerURL);
const privateKeys = "${privateKeys}";
const contractAddress = "${contractAddress}";
const transactionData = "${transactionData}";
const numberOfTransactions = ${numberOfTransactions};

async function sendTransaction(wallet, nonce) {
    const tx = {
        to: contractAddress,
        value: 0,
        gasLimit: ethers.BigNumber.from(${gasLimit}),
        gasPrice: ethers.utils.parseUnits("${gasPrice}", 'gwei'),
        data: transactionData,
        nonce: nonce,
    };
    try {
        const transactionResponse = await wallet.sendTransaction(tx);
        console.log("\033[1;35mTx Hash:\033[0m", transactionResponse.hash);
        await transactionResponse.wait();
        console.log("\033[1;32mTransaction confirmed\033[0m");
    } catch (error) {
        console.error("\033[1;31mError sending transaction:\033[0m", error.message);
    }
}

async function main() {
    const wallet = new ethers.Wallet(privateKeys, provider);
    const startNonce = await wallet.getTransactionCount();
    
    console.log("\033[1;34mStarting balance:\033[0m", ethers.utils.formatEther(await wallet.getBalance()), "ETH");
    
    for (let i = 0; i < numberOfTransactions; i++) {
        console.log(`\n\033[1;36mSending transaction ${i + 1} of ${numberOfTransactions}\033[0m`);
        await sendTransaction(wallet, startNonce + i);
    }
    
    console.log("\n\033[1;34mEnding balance:\033[0m", ethers.utils.formatEther(await wallet.getBalance()), "ETH");
}

main().catch(console.error);
EOF

# Menjalankan script Node.js
NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

# Membersihkan file sementara
rm $temp_node_file

print_color "1;34" "Don't forget to follow my twitter @makanbitcoin"
