/*
    ~1. Научиться делать view транзакции~
    ~2. Научиться делать view транзакции с инфурой~
    ~3. Научиться подключать герли и делать view транзакции~
    4. Научиться колл транзакции делать
    5. Сделать верификацию для двух голосований
    6. Научиться юзать Axum
    7. API
*/

use std::sync::Arc;

use clap::Parser;

use electron_rs::verifier::near::*;

use ethers::prelude::*;

const WETH_ADDRESS: &str = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    rpc: String,
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

    let provider = Provider::<Http>::try_from(rpc)?;

    let block_number = provider.get_block_number().await?;

    println!("{block_number}");

    // let address: Address = WETH_ADDRESS.parse()?;
    // let client = Arc::new(provider);

    // let contract = IERC20::new(address, client);

    // let total_supply = contract.total_supply().call().await.unwrap();

    // println!("{total_supply:?}");

    Ok(())
}
