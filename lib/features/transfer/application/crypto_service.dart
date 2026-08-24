import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:crypto/crypto.dart' as crypto;

part 'crypto_service.g.dart';

@riverpod
class CryptoService extends _$CryptoService {
  @override
  void build() {
  }

  Future<SimpleKeyPair> generateKeyPair() async {
    final algorithm = X25519();
    return await algorithm.newKeyPair();
  }

  Future<SecretKey> deriveSharedSecret(
    SimpleKeyPair localKeyPair,
    List<int> remotePublicKeyBytes,
  ) async {
    final algorithm = X25519();
    final remotePublicKey = SimplePublicKey(
      remotePublicKeyBytes,
      type: KeyPairType.x25519,
    );

    return await algorithm.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: remotePublicKey,
    );
  }

  Future<SecretBox> encryptData(
    List<int> cleartext,
    SecretKey secretKey,
  ) async {
    final chacha = Chacha20.poly1305Aead();
    final nonce = chacha.newNonce();
    return await chacha.encrypt(
      cleartext,
      secretKey: secretKey,
      nonce: nonce,
    );
  }

  Future<List<int>> decryptData(
    SecretBox secretBox,
    SecretKey secretKey,
  ) async {
    final chacha = Chacha20.poly1305Aead();
    return await chacha.decrypt(
      secretBox,
      secretKey: secretKey,
    );
  }

  String calculateSha256(List<int> data) {
    final hash = crypto.sha256.convert(data);
    return hash.toString();
  }
}
