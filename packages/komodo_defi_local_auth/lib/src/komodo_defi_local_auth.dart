import 'dart:async';
import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:komodo_defi_local_auth/src/auth/auth_service.dart';
import 'package:komodo_defi_local_auth/src/auth/storage/secure_storage.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// The [KomodoDefiAuth] class provides a simplified local authentication
/// service for managing user sign-in, registration, and mnemonic handling
/// within the Komodo DeFi Framework.
///
/// By default, the class operates in HD mode, which may be unexpected for
/// developers familiar with the KDF API's default behavior. The default
/// [AuthOptions] enables HD wallet mode, but this can be changed using
/// the [AuthOptions] parameter in the sign-in and registration methods.
///
/// NB: Pubkey address
abstract interface class KomodoDefiAuth {
  /// Ensures that the local authentication system has been initialized.
  ///
  /// This method must be called before interacting with authentication features.
  /// If the system is already initialized, this method does nothing.
  Future<void> ensureInitialized();

  /// Signs in a user with the specified [walletName] and [password].
  ///
  /// By default, the system will launch in HD mode (enabled in the [AuthOptions]),
  /// which may differ from the non-HD mode used in other areas of the KDF API.
  /// Developers can override the [derivationMethod] in [AuthOptions] to change
  /// this behavior.
  ///
  /// Throws [AuthException] if an error occurs during sign-in.
  Future<KdfUser> signIn({
    required String walletName,
    required String password,
    AuthOptions options = const AuthOptions(
      derivationMethod: DerivationMethod.hdWallet,
    ),
  });

  /// Registers a new user with the specified [walletName] and [password].
  ///
  /// By default, the system will launch in HD mode (enabled in the [AuthOptions]),
  /// which may differ from the non-HD mode used in other areas of the KDF API.
  /// Developers can override the [derivationMethod] in [AuthOptions] to change
  /// this behavior. An optional [mnemonic] can be provided during registration.
  ///
  /// Throws [AuthException] if registration is disabled or if an error occurs
  /// during registration.
  Future<KdfUser> register({
    required String walletName,
    required String password,
    AuthOptions options = const AuthOptions(
      derivationMethod: DerivationMethod.hdWallet,
    ),
    Mnemonic? mnemonic,
  });

  /// A stream that emits authentication state changes for the current user.
  ///
  /// Returns a [Stream] of [KdfUser?] representing the currently signed-in
  /// user. The stream will emit `null` if the user is signed out.
  Stream<KdfUser?> get authStateChanges;

  /// Retrieves the current signed-in user, if available.
  ///
  /// Returns a [KdfUser] if a user is signed in, otherwise returns `null`.
  Future<KdfUser?> get currentUser;

  /// Retrieves a list of all users registered on the device.
  ///
  /// Returns a [List] of [KdfUser] objects representing all registered users.
  Future<List<KdfUser>> getUsers();

  /// Signs out the current user.
  ///
  /// Throws [AuthException] if an error occurs during the sign-out process.
  Future<void> signOut();

  /// Checks whether a user is currently signed in.
  ///
  /// Returns `true` if a user is signed in, otherwise `false`.
  Future<bool> isSignedIn();

  /// Retrieves the encrypted mnemonic of the currently signed-in user.
  ///
  /// Throws [AuthException] if an error occurs during retrieval or if no user
  /// is signed in.
  Future<Mnemonic> getMnemonicEncrypted();

  /// Retrieves the plain text mnemonic of the currently signed-in user.
  ///
  /// A [walletPassword] must be provided to decrypt the mnemonic.
  /// Throws [AuthException] if an error occurs during retrieval or if no user
  /// is signed in.
  Future<Mnemonic> getMnemonicPlainText(String walletPassword);

  /// Disposes of any resources held by the authentication service.
  ///
  /// This method should be called when the authentication service is no longer
  /// needed to clean up resources.
  void dispose();
}

class KomodoDefiLocalAuth implements KomodoDefiAuth {
  KomodoDefiLocalAuth({
    required KomodoDefiFramework kdf,
    required IKdfHostConfig hostConfig,
    bool allowRegistrations = true,
  })  : _allowRegistrations = allowRegistrations,
        _authService = KdfAuthService(kdf, hostConfig);

  final SecureLocalStorage _secureStorage = SecureLocalStorage();

  final bool _allowRegistrations;
  late final IAuthService _authService;
  bool _initialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _authService.getActiveUser();
    _initialized = true;
  }

  // Save AuthOptions when registering or signing in
  @override
  Future<KdfUser> signIn({
    required String walletName,
    required String password,
    AuthOptions options = const AuthOptions(
      derivationMethod: DerivationMethod.hdWallet,
    ),
  }) async {
    await ensureInitialized();
    await _assertAuthState(false);

    final updatedUser =
        (await _findUser(walletName)).copyWith(authOptions: options);

    // Save AuthOptions to secure storage by wallet name
    await _secureStorage.saveUser(updatedUser);

    return _authService.signIn(
      walletName: walletName,
      password: password,
      options: options,
    );
  }

  Future<KdfUser> _findUser(String walletName) async {
    final matchedUsers = (await _authService.getUsers()).where(
      (user) => user.walletId.name == walletName,
    );

    if (matchedUsers.isEmpty) {
      throw AuthException(
        'No user found with the specified wallet name.',
        type: AuthExceptionType.walletNotFound,
      );
    }

    if (matchedUsers.length > 1) {
      throw AuthException(
        'Multiple users found with the specified wallet name.',
        type: AuthExceptionType.internalError,
      );
    }

    return matchedUsers.first;
  }

  static Future<AuthOptions?> storedAuthOptions(String walletName) async {
    return SecureLocalStorage()
        .getUser(walletName)
        .then((user) => user?.authOptions);
  }

  Future<AuthOptions?> currentUsersAuthOptions() async {
    final user = await _authService.getActiveUser();
    return user == null ? null : storedAuthOptions(user.walletId.name);
  }

  @override
  Future<KdfUser> register({
    required String walletName,
    required String password,
    AuthOptions options = const AuthOptions(
      derivationMethod: DerivationMethod.hdWallet,
    ),
    Mnemonic? mnemonic,
  }) async {
    await ensureInitialized();
    await _assertAuthState(false);

    if (!_allowRegistrations) {
      throw AuthException(
        'Registration is not allowed.',
        type: AuthExceptionType.registrationNotAllowed,
      );
    }

    final user = await _authService.register(
      walletName: walletName,
      password: password,
      options: options,
      mnemonic: mnemonic,
    );

    await _secureStorage.saveUser(user);

    return user;
  }

  // // Retrieve AuthOptions by wallet name when needed
  // Future<AuthOptions?> getAuthOptions(String walletName) async {
  //   return _secureStorage.getAuthOptions(walletName);
  // }

  @override
  Stream<KdfUser?> get authStateChanges async* {
    await ensureInitialized();
    yield* _authService.authStateChanges;
  }

  @override
  Future<KdfUser?> get currentUser async {
    await ensureInitialized();
    return _authService.getActiveUser();
  }

  @override
  Future<List<KdfUser>> getUsers() async {
    await ensureInitialized();

    return _authService.getUsers();
  }

  @override
  Future<void> signOut() async {
    await ensureInitialized();
    await _assertAuthState(true);

    try {
      await _authService.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred while signing out: $e',
        type: AuthExceptionType.generalAuthError,
      );
    }
  }

  @override
  Future<bool> isSignedIn() async {
    await ensureInitialized();
    return _authService.isSignedIn();
  }

  @override
  Future<Mnemonic> getMnemonicEncrypted() async {
    await ensureInitialized();
    await _assertAuthState(true);

    try {
      return await _authService.getMnemonic(
        encrypted: true,
        walletPassword: null,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred while retrieving the mnemonic: $e',
        type: AuthExceptionType.generalAuthError,
      );
    }
  }

  @override
  Future<Mnemonic> getMnemonicPlainText(String walletPassword) async {
    await ensureInitialized();
    await _assertAuthState(true);

    try {
      return _authService.getMnemonic(
        encrypted: false,
        walletPassword: walletPassword,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred while retrieving the mnemonic: $e',
        type: AuthExceptionType.generalAuthError,
      );
    }
  }

  Future<void> _assertAuthState(bool expected) async {
    await ensureInitialized();
    final signedIn = await isSignedIn();
    if (signedIn != expected) {
      throw AuthException(
        'User is ${signedIn ? 'signed in' : 'not signed in'}.',
        type: signedIn
            ? AuthExceptionType.alreadySignedIn
            : AuthExceptionType.unauthorized,
      );
    }
  }

  @override
  void dispose() {
    _authService.dispose();
  }
}