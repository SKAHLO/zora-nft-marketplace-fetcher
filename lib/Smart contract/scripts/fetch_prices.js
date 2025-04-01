const { ethers } = require("hardhat");

async function main() {
  // Replace with your deployed contract address
  const PRICE_FETCHER_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
  
  // Replace with the NFT contract and token ID you want to check
  const NFT_CONTRACT = "0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63"; // Example: Blitmap
  const TOKEN_ID = 1;
  
  const priceFetcher = await ethers.getContractAt("ZoraNFTPriceFetcher", PRICE_FETCHER_ADDRESS);
  
  // Check if NFT is listed
  const isListed = await priceFetcher.isNFTListed(NFT_CONTRACT, TOKEN_ID);
  console.log(`NFT Listed on Zora: ${isListed}`);
  
  if (isListed) {
    // Get fixed price listing
    const fixedPrice = await priceFetcher.getFixedPriceListing(NFT_CONTRACT, TOKEN_ID);
    console.log("Fixed Price Listing:", {
      exists: fixedPrice.exists,
      price: ethers.utils.formatEther(fixedPrice.price) + " ETH",
      seller: fixedPrice.seller
    });
    
    // Get auction details
    const auction = await priceFetcher.getAuctionDetails(NFT_CONTRACT, TOKEN_ID);
    console.log("Auction:", {
      exists: auction.exists,
      reservePrice: ethers.utils.formatEther(auction.reservePrice) + " ETH",
      highestBid: ethers.utils.formatEther(auction.highestBid) + " ETH",
      highestBidder: auction.highestBidder,
      endTime: auction.endTime > 0 ? new Date(auction.endTime * 1000).toLocaleString() : "Not started",
      active: auction.active
    });
    
    // Get best price
    const bestPrice = await priceFetcher.getBestPrice(NFT_CONTRACT, TOKEN_ID);
    console.log("Best Price:", {
      available: bestPrice.available,
      price: ethers.utils.formatEther(bestPrice.bestPrice) + " ETH",
      isAuction: bestPrice.isAuction
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
