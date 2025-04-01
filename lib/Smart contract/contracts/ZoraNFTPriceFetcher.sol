// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Zora interfaces
interface IZoraModuleManager {
    function getModuleAddress(bytes4 moduleTypeId) external view returns (address);
}

interface IZoraAsksCoreEth {
    struct Ask {
        address seller;
        uint256 price;
        uint256 findersFeeBps;
    }
    
    function askForNFT(address tokenContract, uint256 tokenId) external view returns (Ask memory);
}

interface IZoraReserveAuctionCoreEth {
    struct Auction {
        address seller;
        uint256 reservePrice;
        uint256 sellerFundsRecipient;
        uint256 highestBid;
        address highestBidder;
        uint256 duration;
        uint256 startTime;
        uint256 firstBidTime;
        uint8 status;
    }
    
    function auctionForNFT(address tokenContract, uint256 tokenId) external view returns (Auction memory);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ZoraNFTPriceFetcher
 * @dev Contract to fetch NFT market prices on Zora
 */
contract ZoraNFTPriceFetcher {
    // Zora module manager address (mainnet)
    address public constant ZORA_MODULE_MANAGER = 0x9458E29713B98BF452ee9B2C099289f533A5F377;
    
    // Module type IDs
    bytes4 public constant ASKS_MODULE_TYPE = 0x7e1a1c0e; // Asks v1.1 module type
    bytes4 public constant RESERVE_AUCTION_MODULE_TYPE = 0x93771e2e; // Reserve auction module type
    
    // Cached module addresses
    address private asksModuleAddress;
    address private reserveAuctionModuleAddress;
    
    constructor() {
        // Initialize module addresses
        IZoraModuleManager moduleManager = IZoraModuleManager(ZORA_MODULE_MANAGER);
        asksModuleAddress = moduleManager.getModuleAddress(ASKS_MODULE_TYPE);
        reserveAuctionModuleAddress = moduleManager.getModuleAddress(RESERVE_AUCTION_MODULE_TYPE);
    }
    
    /**
     * @notice Get the fixed price listing for an NFT if it exists
     * @param tokenContract The NFT contract address
     * @param tokenId The NFT token ID
     * @return exists Whether a fixed price listing exists
     * @return price The listing price (0 if no listing)
     * @return seller The seller address (zero address if no listing)
     */
    function getFixedPriceListing(address tokenContract, uint256 tokenId) 
        external 
        view 
        returns (bool exists, uint256 price, address seller) 
    {
        try IZoraAsksCoreEth(asksModuleAddress).askForNFT(tokenContract, tokenId) returns (IZoraAsksCoreEth.Ask memory ask) {
            if (ask.seller != address(0)) {
                return (true, ask.price, ask.seller);
            }
        } catch {
            // No listing found or error
        }
        
        return (false, 0, address(0));
    }
    
    /**
     * @notice Get the auction details for an NFT if it exists
     * @param tokenContract The NFT contract address
     * @param tokenId The NFT token ID
     * @return exists Whether an auction exists
     * @return reservePrice The auction reserve price
     * @return highestBid The current highest bid
     * @return highestBidder The current highest bidder
     * @return endTime The auction end time (0 if not started)
     * @return active Whether the auction is currently active
     */
    function getAuctionDetails(address tokenContract, uint256 tokenId) 
        external 
        view 
        returns (
            bool exists, 
            uint256 reservePrice, 
            uint256 highestBid, 
            address highestBidder,
            uint256 endTime,
            bool active
        ) 
    {
        try IZoraReserveAuctionCoreEth(reserveAuctionModuleAddress).auctionForNFT(tokenContract, tokenId) returns (IZoraReserveAuctionCoreEth.Auction memory auction) {
            if (auction.seller != address(0)) {
                // Calculate end time if auction has started
                uint256 calculatedEndTime = 0;
                if (auction.firstBidTime > 0) {
                    calculatedEndTime = auction.firstBidTime + auction.duration;
                }
                
                // Auction is active if it has started and not ended
                bool isActive = auction.firstBidTime > 0 && 
                               (auction.status == 1) && // Assuming 1 is ACTIVE status
                               (calculatedEndTime > block.timestamp);
                
                return (
                    true, 
                    auction.reservePrice, 
                    auction.highestBid, 
                    auction.highestBidder,
                    calculatedEndTime,
                    isActive
                );
            }
        } catch {
            // No auction found or error
        }
        
        return (false, 0, 0, address(0), 0, false);
    }
    
    /**
     * @notice Get the best available price for an NFT (lowest between fixed price and auction)
     * @param tokenContract The NFT contract address
     * @param tokenId The NFT token ID
     * @return available Whether the NFT is available for purchase
     * @return bestPrice The best available price (0 if not available)
     * @return isAuction Whether the best price is from an auction
     */
    function getBestPrice(address tokenContract, uint256 tokenId) 
        external 
        view 
        returns (bool available, uint256 bestPrice, bool isAuction) 
    {
        // Check fixed price listing
        (bool fixedPriceExists, uint256 fixedPrice, ) = this.getFixedPriceListing(tokenContract, tokenId);
        
        // Check auction
        (bool auctionExists, uint256 reservePrice, uint256 highestBid, , , bool auctionActive) = 
            this.getAuctionDetails(tokenContract, tokenId);
        
        // Determine current auction price
        uint256 auctionPrice = 0;
        if (auctionExists && auctionActive) {
            auctionPrice = highestBid > 0 ? highestBid : reservePrice;
        }
        
        // Determine best price
        if (fixedPriceExists && auctionExists && auctionActive) {
            // Both options available, return the cheaper one
            if (fixedPrice <= auctionPrice) {
                return (true, fixedPrice, false);
            } else {
                return (true, auctionPrice, true);
            }
        } else if (fixedPriceExists) {
            return (true, fixedPrice, false);
        } else if (auctionExists && auctionActive) {
            return (true, auctionPrice, true);
        }
        
        // NFT not available for purchase
        return (false, 0, false);
    }
    
    /**
     * @notice Check if an NFT is listed on Zora (either fixed price or auction)
     * @param tokenContract The NFT contract address
     * @param tokenId The NFT token ID
     * @return isListed Whether the NFT is listed on Zora
     */
    function isNFTListed(address tokenContract, uint256 tokenId) external view returns (bool isListed) {
        (bool fixedPriceExists, , ) = this.getFixedPriceListing(tokenContract, tokenId);
        (bool auctionExists, , , , , ) = this.getAuctionDetails(tokenContract, tokenId);
        
        return fixedPriceExists || auctionExists;
    }
}
