import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class AssetPage extends StatefulWidget {
  const AssetPage(this.asset, {super.key});

  final Asset asset;

  @override
  State<AssetPage> createState() => _AssetPageState();
}

final _sdk = KomodoDefiSdk();

class _AssetPageState extends State<AssetPage> {
  AssetPubkeys? _pubkeys;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPubkeys();
  }

  Future<void> _loadPubkeys() async {
    setState(() => _isLoading = true);
    try {
      final pubkeys = await _sdk.pubkeys.getPubkeys(widget.asset);
      setState(() => _pubkeys = pubkeys);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewAddress() async {
    setState(() => _isLoading = true);
    try {
      final newPubkey = await _sdk.pubkeys.createNewPubkey(widget.asset);
      setState(() {
        _pubkeys?.keys.add(newPubkey);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsMultipleAddresses =
        widget.asset.pubkeyStrategy.supportsMultipleAddresses;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset.id.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPubkeys,
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                SizedBox(height: 32),
                AssetHeader(widget.asset, _pubkeys),
                SizedBox(height: 32),
                Expanded(
                  child: _AddressesSection(
                    pubkeys: _pubkeys == null
                        ? AssetPubkeys(
                            keys: [],
                            assetId: widget.asset.id,
                            availableAddressesCount: 0,
                            syncStatus: SyncStatus.inProgress,
                          )
                        : _pubkeys!,
                    onGenerateNewAddress:
                        supportsMultipleAddresses ? _generateNewAddress : null,
                    supportsMultipleAddresses: supportsMultipleAddresses,
                  ),
                ),
              ],
            ),
    );
  }
}

class AssetHeader extends StatefulWidget {
  const AssetHeader(this.asset, this.pubkeys, {super.key});

  final Asset asset;
  final AssetPubkeys? pubkeys;

  @override
  State<AssetHeader> createState() => _AssetHeaderState();
}

class _AssetHeaderState extends State<AssetHeader> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActions(context),
        SizedBox(height: 16),
        _buildBalanceOverview(context),
      ],
    );
  }

  Widget _buildBalanceOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Total', style: Theme.of(context).textTheme.bodySmall),
            Text(
              // TODO: Stream-based
              (widget.pubkeys?.syncStatus == SyncStatus.inProgress)
                  ? 'Loading...'
                  : (widget.pubkeys?.balance ?? Balance.zero()).toString(),
            ),
          ],
        ),
      ),
    );
  }

  //TODO: Eradicate this widget helper function
  Widget _buildActions(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.send),
          label: const Text('Send'),
        ),
        FilledButton.tonalIcon(
          onPressed: () {},
          icon: const Icon(Icons.qr_code),
          label: const Text('Receive'),
        ),
      ],
    );
  }
}

class _AddressesSection extends StatelessWidget {
  const _AddressesSection({
    required this.pubkeys,
    required this.onGenerateNewAddress,
    required this.supportsMultipleAddresses,
  });

  final AssetPubkeys pubkeys;
  final VoidCallback? onGenerateNewAddress;
  final bool supportsMultipleAddresses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text('Addresses'),
              if (supportsMultipleAddresses)
                ElevatedButton.icon(
                  onPressed: onGenerateNewAddress,
                  label: const Text('New'),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pubkeys.keys.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(index.toString()),
                subtitle: Text(pubkeys.keys[index].toJson().toJsonString()),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: pubkeys.keys[index].address),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
