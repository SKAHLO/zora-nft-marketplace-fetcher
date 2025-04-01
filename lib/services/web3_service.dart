import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class Web3Service {
  late Web3Client _client;
  late String _rpcUrl;
  late DeployedContract _contract;

  // Initialize the service
  Future<void> init() async {
    await dotenv.load();

    // Set up Ethereum client
    _rpcUrl = 'https://mainnet.infura.io/v3/${dotenv.env['INFURA_API_KEY']}';
    _client = Web3Client(_rpcUrl, Client());

    // Load contract
    await _loadContract();
  }

  // Load contract ABI and address
  Future<void> _loadContract() async {
    final abiString =
        await rootBundle.loadString('assets/ZoraNFTPriceFetcher.json');
    final abiJson = jsonDecode(abiString);
    final contractAddress =
        EthereumAddress.fromHex(dotenv.env['CONTRACT_ADDRESS']!);

    _contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abiJson['abi']), 'ZoraNFTPriceFetcher'),
      contractAddress,
    );
  }

  // Check if an NFT is listed on Zora
  Future<bool> isNFTListed(String tokenContract, BigInt tokenId) async {
    final function = _contract.function('isNFTListed');
    final tokenAddress = EthereumAddress.fromHex(tokenContract);

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [tokenAddress, tokenId],
    );

    return result[0] as bool;
  }

  // Get fixed price listing details
  Future<Map<String, dynamic>> getFixedPriceListing(
      String tokenContract, BigInt tokenId) async {
    final function = _contract.function('getFixedPriceListing');
    final tokenAddress = EthereumAddress.fromHex(tokenContract);

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [tokenAddress, tokenId],
    );

    return {
      'exists': result[0] as bool,
      'price': result[1] as BigInt,
      'seller': (result[2] as EthereumAddress).hex,
    };
  }

  // Get auction details
  Future<Map<String, dynamic>> getAuctionDetails(
      String tokenContract, BigInt tokenId) async {
    final function = _contract.function('getAuctionDetails');
    final tokenAddress = EthereumAddress.fromHex(tokenContract);

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [tokenAddress, tokenId],
    );

    return {
      'exists': result[0] as bool,
      'reservePrice': result[1] as BigInt,
      'highestBid': result[2] as BigInt,
      'highestBidder': (result[3] as EthereumAddress).hex,
      'endTime': result[4] as BigInt,
      'active': result[5] as bool,
    };
  }

  // Get best price
  Future<Map<String, dynamic>> getBestPrice(
      String tokenContract, BigInt tokenId) async {
    final function = _contract.function('getBestPrice');
    final tokenAddress = EthereumAddress.fromHex(tokenContract);

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [tokenAddress, tokenId],
    );

    return {
      'available': result[0] as bool,
      'bestPrice': result[1] as BigInt,
      'isAuction': result[2] as bool,
    };
  }

  // Helper to convert wei to ETH
  String weiToEth(BigInt wei) {
    return EtherAmount.fromBigInt(EtherUnit.wei, wei)
        .getValueInUnit(EtherUnit.ether)
        .toString();
  }

  // Dispose resources
  void dispose() {
    _client.dispose();
  }
}
