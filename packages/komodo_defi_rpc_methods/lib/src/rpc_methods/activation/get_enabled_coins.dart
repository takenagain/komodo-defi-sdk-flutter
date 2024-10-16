// lib/src/rpc_methods/get_enabled_coins.dart

// import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart';
import 'package:komodo_defi_rpc_methods/src/internal_exports.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class GetEnabledCoinsRequest
    extends BaseRequest<GetEnabledCoinsResponse, GeneralErrorResponse> {
  GetEnabledCoinsRequest({super.rpcPass})
      : super(method: 'get_enabled_coins', mmrpc: null);

  @override
  GetEnabledCoinsResponse parseResponse(String responseBody) {
    return GetEnabledCoinsResponse.fromJson(jsonFromString(responseBody));
  }
}

class GetEnabledCoinsResponse extends BaseResponse {
  GetEnabledCoinsResponse({
    required super.mmrpc,
    required this.result,
  });

  factory GetEnabledCoinsResponse.fromJson(Map<String, dynamic> json) {
    return GetEnabledCoinsResponse(
      mmrpc: json.valueOrNull<String>('mmrpc'),
      result:
          json.value<JsonList>('result').map(EnabledCoinInfo.fromJson).toList(),
    );
  }

  final List<EnabledCoinInfo> result;

  @override
  Map<String, dynamic> toJson() => {
        'result': result.map((e) => e.toJson()).toList(),
      };
}

// TODO? Move to common structures?
class EnabledCoinInfo {
  EnabledCoinInfo({
    required this.address,
    required this.ticker,
  });

  factory EnabledCoinInfo.fromJson(Map<String, dynamic> json) {
    return EnabledCoinInfo(
      address: json.value<String>('address'),
      ticker: json.value<String>('ticker'),
    );
  }

  final String address;
  final String ticker;

  Map<String, dynamic> toJson() => {
        'address': address,
        'ticker': ticker,
      };
}