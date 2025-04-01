import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nft_market_provider.dart';

class NFTMarketScreen extends StatefulWidget {
  const NFTMarketScreen({Key? key}) : super(key: key);

  @override
  State<NFTMarketScreen> createState() => _NFTMarketScreenState();
}

class _NFTMarketScreenState extends State<NFTMarketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contractAddressController = TextEditingController();
  final _tokenIdController = TextEditingController();

  @override
  void dispose() {
    _contractAddressController.dispose();
    _tokenIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zora NFT Market Info'),
        backgroundColor: Colors.purple[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchForm(),
            const SizedBox(height: 20),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search NFT Market Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contractAddressController,
                decoration: const InputDecoration(
                  labelText: 'NFT Contract Address',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.token),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a contract address';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Please enter a valid Ethereum address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tokenIdController,
                decoration: const InputDecoration(
                  labelText: 'Token ID',
                  hintText: 'Enter token ID (e.g., 1234)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a token ID';
                  }
                  try {
                    BigInt.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _fetchNFTData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Fetch Market Data',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: Consumer<NFTMarketProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (provider.isListed == null) {
            return const Center(
              child: Text(
                'Enter an NFT contract address and token ID to see market data',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListingStatusCard(provider),
                const SizedBox(height: 16),
                if (provider.fixedPriceData != null &&
                    provider.fixedPriceData!['exists'])
                  _buildFixedPriceCard(provider),
                if (provider.fixedPriceData != null &&
                    provider.fixedPriceData!['exists'])
                  const SizedBox(height: 16),
                if (provider.auctionData != null &&
                    provider.auctionData!['exists'])
                  _buildAuctionCard(provider),
                if (provider.auctionData != null &&
                    provider.auctionData!['exists'])
                  const SizedBox(height: 16),
                if (provider.bestPriceData != null &&
                    provider.bestPriceData!['available'])
                  _buildBestPriceCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingStatusCard(NFTMarketProvider provider) {
    return Card(
      elevation: 3,
      color: provider.isListed! ? Colors.green[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              provider.isListed! ? Icons.check_circle : Icons.cancel,
              color: provider.isListed! ? Colors.green : Colors.grey,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isListed!
                        ? 'NFT is Listed on Zora'
                        : 'NFT is Not Listed on Zora',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: provider.isListed!
                          ? Colors.green[800]
                          : Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Contract: ${_truncateAddress(_contractAddressController.text)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Token ID: ${_tokenIdController.text}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedPriceCard(NFTMarketProvider provider) {
    return Card(
      elevation: 3,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sell, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Fixed Price Listing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Price:', '${provider.fixedPriceData!['priceEth']} ETH'),
            _buildInfoRow('Seller:',
                _truncateAddress(provider.fixedPriceData!['seller'])),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(NFTMarketProvider provider) {
    final endTime = provider.auctionData!['endTime'] as BigInt;
    String endTimeStr = 'Not started';

    if (endTime > BigInt.zero) {
      final endDateTime =
          DateTime.fromMillisecondsSinceEpoch(endTime.toInt() * 1000);
      endTimeStr = '${endDateTime.toLocal()}';
    }

    return Card(
      elevation: 3,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Auction ${provider.auctionData!['active'] ? '(Active)' : ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Reserve Price:',
                '${provider.auctionData!['reservePriceEth']} ETH'),
            _buildInfoRow(
              'Highest Bid:',
              provider.auctionData!['highestBid'] > BigInt.zero
                  ? '${provider.auctionData!['highestBidEth']} ETH'
                  : 'No bids yet',
            ),
            if (provider.auctionData!['highestBid'] > BigInt.zero)
              _buildInfoRow('Highest Bidder:',
                  _truncateAddress(provider.auctionData!['highestBidder'])),
            _buildInfoRow('End Time:', endTimeStr),
            _buildInfoRow('Status:',
                provider.auctionData!['active'] ? 'Active' : 'Inactive'),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPriceCard(NFTMarketProvider provider) {
    return Card(
      elevation: 3,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Best Available Price',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Price:', '${provider.bestPriceData!['bestPriceEth']} ETH'),
            _buildInfoRow(
              'Type:',
              provider.bestPriceData!['isAuction'] ? 'Auction' : 'Fixed Price',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _fetchNFTData() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<NFTMarketProvider>(context, listen: false);
      provider.fetchNFTMarketData(
        _contractAddressController.text,
        _tokenIdController.text,
      );
    }
  }
}
