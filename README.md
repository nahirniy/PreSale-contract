# Solar Green Tokenization Project

## Overview

This repository contains the solution for the Dexola Solidity Bootcamp application task, featuring Solidity smart contracts for electricity tokenization and sale.

## Smart Contracts

1. **ERC20 Token Contract**: The SolarGreen contract is an ERC20 token with additional functionalities for burning tokens, minting new tokens, and managing a blacklist of addresses. It leverages OpenZeppelin's ERC20 and AccessControl contracts to provide secure and flexible token management capabilities.
2. **Token Sale Contract**: The TokenSale contract enables the sale of SolarGreen tokens through USDT or Ethereum purchases, incorporating features for pricing, sale duration management, and token claims after vesting period. Additionally, it allows the contract owner to withdraw ETH, USDT, and tokens from the contract.

## Technologies Used

- **Solidity**: Smart contracts wrote in Solidity, a programming language specifically designed for Ethereum smart contracts.
- **OpenZeppelin Library**: Utilized for building secure and standard-compliant ERC20 tokens and Access Control roles.
- **Hardhat Framework**: Used for development, testing, and deployment of smart contracts.
- **Unit Tests**: Comprehensive unit tests wrote to ensure the functionality and security of the smart contracts.
- **Ethereum Sepolia Testnet**: Contracts deployed and tested on the Ethereum test network.
- **Chainlink Oracle**: For obtaining real-time ETH/USD price feeds

## Contracts Information

- _SolarGreen address:_ 0xe1885Cc79F4CeAf8A491Ae5D964b978121a9ce91
- _TokenSale address:_ 0xB62c0e0374d2c46C3DFDa5911196730d353aeb89
- _SolarGreen etherscan:_ [Etherscan link](https://sepolia.etherscan.io/address/0xe1885Cc79F4CeAf8A491Ae5D964b978121a9ce91#code)
- _TokenSale etherscan:_ [Etherscan link](https://sepolia.etherscan.io/address/0xB62c0e0374d2c46C3DFDa5911196730d353aeb89#code)

## How to Buy tokens?

1. Use the ethBuyHelper and usdtBuyHelper functions to calculate the required amount of ether or usdt to buy a certain number of tokens. Enter the number of tokens in 18-decimal format, the amount will also be returned in 18-decimal format. (it's free, no gas)
2. If you want to buy tokens for the test dollar, you should go to this [link](https://sepolia.etherscan.io/address/0x1531bc5de10618c511349f8007c08966e45ce8ef#writeContract), then mint the amount of dollars and make an approval. In the approval, specify the TokenSale address. If you did, use the BuyWithUSDT function, add the number of zeros to 18. And specify the amount of token.
3. If you want to buy tokens for test ether. use the BuyWithETH function, add the number of zeros to 18. And specify the amount of token. In the payable field, enter the amount of ether required for the purchase. Don't worry about if you sent more ether than necessary excess will be returned.
4. After your transaction has been completed successfully, you can view your token balance in the checkUserBalance function, enter your wallet address there. (it's free, no gas)
5. After 2023.12.31 you will be able to claim your tokens using the claimTokens function, enter your wallet address there. You can do it from any wallet, the main thing is to specify the address from which the tokens were bought and they will come to that wallet

## Running the Project

1. Clone the repository.
2. Install dependencies using `npm install`.
3. Compile the smart contracts using `npx hardhat compile`.
4. Run tests using `npx hardhat test`.
5. Deploy the contracts to the Ethereum testnet using `npx hardhat run scripts/deploy.ts --network sepolia`.

### Contact Information

For any inquiries or clarifications regarding this project, please contact [Telegram](https://t.me/nahirniy) or [Email](nahirniyy@gamil.com).

### Disclaimer

This project is for educational and testing purposes only. The deployed smart contracts on testnets should not be used in a production environment without proper auditing and security considerations.
