import 'package:flutter/material.dart';
import '../services/web3_service.dart';

class NFTMarketProvider extends ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  bool _isLoading = false;
  String _errorMessage = '';

  Map<String, dynamic>? _fixedPriceData;
  Map<String, dynamic>? _auctionData;
  Map<String, dynamic>? _bestPriceData;
  bool? _isListed;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get fixedPriceData => _fixedPriceData;
  Map<String, dynamic>? get auctionData => _auctionData;
  Map<String, dynamic>? get bestPriceData => _bestPriceData;
  bool? get isListed => _isListed;

  NFTMarketProvider() {
    _initWeb3();
  }

  Future<void> _initWeb3() async {
    try {
      await _web3Service.init();
    } catch (e) {
      _errorMessage = 'Failed to initialize Web3: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch all NFT market data
  Future<void> fetchNFTMarketData(String tokenContract, String tokenId) async {
    if (tokenContract.isEmpty || tokenId.isEmpty) {
      _errorMessage = 'Token contract and token ID are required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final tokenIdBigInt = BigInt.parse(tokenId);

      // Fetch data in parallel
      final results = await Future.wait([
        _web3Service.isNFTListed(tokenContract, tokenIdBigInt),
        _web3Service.getFixedPriceListing(tokenContract, tokenIdBigInt),
        _web3Service.getAuctionDetails(tokenContract, tokenIdBigInt),
        _web3Service.getBestPrice(tokenContract, tokenIdBigInt),
      ]);

      _isListed = results[0] as bool;
      _fixedPriceData = results[1] as Map<String, dynamic>;
      _auctionData = results[2] as Map<String, dynamic>;
      _bestPriceData = results[3] as Map<String, dynamic>;

      // Add ETH values for better display
      if (_fixedPriceData!['exists']) {
        _fixedPriceData!['priceEth'] =
            _web3Service.weiToEth(_fixedPriceData!['price']);
      }

      if (_auctionData!['exists']) {
        _auctionData!['reservePriceEth'] =
            _web3Service.weiToEth(_auctionData!['reservePrice']);
        _auctionData!['highestBidEth'] =
            _web3Service.weiToEth(_auctionData!['highestBid']);
      }

      if (_bestPriceData!['available']) {
        _bestPriceData!['bestPriceEth'] =
            _web3Service.weiToEth(_bestPriceData!['bestPrice']);
      }
    } catch (e) {
      _errorMessage = 'Error fetching NFT data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _web3Service.dispose();
    super.dispose();
  }
}
