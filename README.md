# zora-nft-marketplace-fetcher
A Flutter mobile and web app that is used to retrieve the details of NFTs listed on Zora by calling an inbuilt smart contract that makes use of Zora's module interface. Make sure to refer to readme file to learn how to deploy the smart contract using your own Infura and Ehterscan API key.
1.	This contract uses Zora's actual interfaces to fetch pricing information from their modules.
2.	The contract supports both fixed price listings (Asks) and auctions.
3.	The getBestPrice function helps users find the lowest available price for an NFT.
4.	The contract is designed to be gas-efficient by caching module addresses.
5.	Error handling is implemented to handle cases where NFTs are not listed.
6.	The contract uses Zora's mainnet module manager address. For testnets, you would need to update this address.
How to Deploy and Test
1.	First, install the required dependencies:
npm init -y
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers
2.	Initialize Hardhat:
npx hardhat init
3.	Deploy the contract:
npx hardhat run scripts/deploy_price_fetcher.js --network mainnet
4.	Run the price fetching script:
npx hardhat run scripts/fetch_prices.js --network mainnet
