// https://komodoplatform.com/en/docs/komodo-defi-framework/api/common_structures/#derivation-method

enum DerivationMethod {
  iguana,
  hdWallet;

  factory DerivationMethod.parse(String value) {
    switch (value) {
      case 'Iguana':
        return DerivationMethod.iguana;
      case 'HDWallet':
        return DerivationMethod.hdWallet;

      default:
        throw ArgumentError('Invalid derivation method: $value');
    }
  }
}
