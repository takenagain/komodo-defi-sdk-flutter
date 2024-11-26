// lib/src/assets/config_transform.dart
import 'package:flutter/foundation.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

// ignore: one_member_abstracts
abstract class CoinConfigTransform {
  JsonMap transform(JsonMap config);

  bool needsTransform(JsonMap config);
}

/// This class is responsible for doing any necessary fixes to the coin config
/// before it is used by the rest of the library.
/// This should be used only when absolutely necessary and not for transforming
/// the config for easier parsing; that should be encapsulated in the
/// respective classes.
class CoinConfigTransformer {
  const CoinConfigTransformer();

  static final _transforms = [
    const WssWebsocketTransform(),
    const ParentCoinTransform(),
    // Add more transforms as needed
  ];

  /// Applies the necessary transforms to the given coin config.
  static JsonMap applyTransforms(JsonMap config) {
    final neededTransforms = _transforms.where((t) => t.needsTransform(config));

    if (neededTransforms.isEmpty) {
      return config;
    }

    return neededTransforms.fold(
      config,

      // Instantiating a new map for each transform is not ideal, given the
      // large size of the config file. However, it is necessary to avoid
      // mutating the original map and for making the transforms idempotent.
      // Use sparingly and ideally only once.
      (config, transform) => transform.transform(JsonMap.from(config)),
    );
  }
}

extension CoinConfigTransformExtension on JsonMap {
  JsonMap get applyTransforms => CoinConfigTransformer.applyTransforms(this);
}

class CoinFilter {
  const CoinFilter();

  static const _filteredCoins = {
    // TODO: Remove when BCH is changed to UTXO protocol in the config
    'BCH': 'Bitcoin Cash',
  };

  static const _filteredProtocolSubTypes = {
    'SLP': 'Simple Ledger Protocol',
  };

  static const _filteredProtocolTypes = {
    'NFT': 'Non Fungible Token',
  };

  /// Returns true if the given coin should be filtered out.
  bool shouldFilter(JsonMap config) {
    final coin = config.value<String>('coin');
    final protocolSubClass = config.valueOrNull<String>('type');
    final protocolClass = config.valueOrNull<String>('protocol', 'type');

    return _filteredCoins.containsKey(coin) ||
        _filteredProtocolTypes.containsKey(protocolClass) ||
        _filteredProtocolSubTypes.containsKey(protocolSubClass);
  }
}

/// Filters out non-wss electrum/server URLs from the given coin config for
/// the web platform as only wss connections are supported.
class WssWebsocketTransform implements CoinConfigTransform {
  const WssWebsocketTransform();

  @override
  bool needsTransform(JsonMap config) {
    final electrum = config.valueOrNull<JsonList>('electrum');
    return electrum != null && kIsWeb;
  }

  @override
  JsonMap transform(JsonMap config) {
    final electrum = JsonList.from(config.value<JsonList>('electrum'));
    // On native, only non-WSS servers are supported. On web, only WSS servers
    // are supported.
    final filteredElectrums = kIsWeb
        ? _filterOutNonWssElectrums(electrum)
        : _filterOutWssElectrums(electrum);

    return config..['electrum'] = filteredElectrums;
  }

  JsonList _filterOutNonWssElectrums(JsonList electrums) {
    final electrumsCopy = JsonList.from(electrums);

    for (final e in electrumsCopy) {
      if (e['protocol'] == 'WSS') {
        e['ws_url'] = e['url'];
      }
    }

    return electrums.where((JsonMap e) => e['ws_url'] != null).toList();
  }

  JsonList _filterOutWssElectrums(JsonList electrums) =>
      electrums.where((JsonMap e) => e['protocol'] != 'WSS').toList();
}

class ParentCoinTransform implements CoinConfigTransform {
  const ParentCoinTransform();

  @override
  bool needsTransform(JsonMap config) =>
      false ||
      config.valueOrNull<String>('parent_coin') != null &&
          _ParentCoinResolver.needsRemapping(config.value('parent_coin'));

  @override
  JsonMap transform(JsonMap config) {
    final parentCoin = config.valueOrNull<String>('parent_coin');
    if (parentCoin != null && _ParentCoinResolver.needsRemapping(parentCoin)) {
      return config
        ..['parent_coin'] = _ParentCoinResolver.resolveParentCoin(parentCoin);
    }
    return config;
  }
}

class _ParentCoinResolver {
  const _ParentCoinResolver._();

  static const _parentCoinMappings = {
    'SLP': 'BCH',
    // Add any other mappings here as needed
  };

  /// Resolves the actual parent coin ticker from a given parent coin identifier
  /// For example, 'SLP' resolves to 'BCH' since SLP tokens are BCH tokens
  static String resolveParentCoin(String parentCoin) =>
      _parentCoinMappings[parentCoin] ?? parentCoin;

  /// Returns true if this parent coin identifier needs remapping
  static bool needsRemapping(String? parentCoin) =>
      _parentCoinMappings.containsKey(parentCoin);
}