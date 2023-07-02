/*
    ~1. Научиться делать view транзакции~
    ~2. Научиться делать view транзакции с инфурой~
    ~3. Научиться подключать герли и делать view транзакции~
    ~4. Научиться колл транзакции делать~
    5. Сделать верификацию для двух голосований
    6. Научиться юзать Axum
    7. API
*/

use std::sync::Arc;

use clap::Parser;

use electron_rs::verifier::near::*;

use ethers::{prelude::*, utils::parse_ether};

const WETH_ADDRESS: &str = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6";

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    rpc: String,
    #[arg(short, long)]
    private_key: String,
}

abigen!(
    IERC20,
    r#"[
        function totalSupply() external view returns (uint256)
        function balanceOf(address account) external view returns (uint256)
        function transfer(address recipient, uint256 amount) external returns (bool)
        function allowance(address owner, address spender) external view returns (uint256)
        function approve(address spender, uint256 amount) external returns (bool)
        function transferFrom( address sender, address recipient, uint256 amount) external returns (bool)
        event Transfer(address indexed from, address indexed to, uint256 value)
        event Approval(address indexed owner, address indexed spender, uint256 value)
    ]"#,
);

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();
    let rpc = args.rpc;
    let private_key = args.private_key;

    let provider = Provider::<Http>::try_from(rpc)?;

    let wallet: LocalWallet = private_key.parse()?;
    let client = SignerMiddleware::new(provider, wallet.with_chain_id(5u64));

    let address: Address = "0x0".parse()?;

    let tx = TransactionRequest::pay(address, 100);
    client.send_transaction(tx, None).await?;

    Ok(())
}
