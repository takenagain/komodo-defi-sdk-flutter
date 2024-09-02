// A class that provides a library of RPC methods used by the Komodo DeFi
// Framework API. This class is used to group RPC methods together and provide
// a namespace for all the methods.
// ignore_for_file: unused_field, unused_element

import 'package:komodo_defi_rpc_methods/src/internal_exports.dart';
import 'package:komodo_defi_rpc_methods/src/rpc_methods/rpc_methods.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class RpcMethodsLibrary {
  RpcMethodsLibrary([this._client]);

  final ApiClient? _client;

  WalletMethods get wallet => WalletMethods(_client);

  // Add other namespaces here, e.g.:
  // TradeNamespace get trade => TradeNamespace(_client);
  // UtilityNamespace get utility => UtilityNamespace(_client);
}

class WalletMethods extends BaseRpcMethodNamespace {
  WalletMethods(super.client);

  Future<GetWalletNamesResponse> getWalletNames([String? rpcPass]) =>
      execute(GetWalletNamesRequest(rpcPass));
}
