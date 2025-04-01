const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying ZoraNFTPriceFetcher...");
  
  const ZoraNFTPriceFetcher = await ethers.getContractFactory("ZoraNFTPriceFetcher");
  const priceFetcher = await ZoraNFTPriceFetcher.deploy();
  
  await priceFetcher.deployed();
  
  console.log("ZoraNFTPriceFetcher deployed to:", priceFetcher.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
