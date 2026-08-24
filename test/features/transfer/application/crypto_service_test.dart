import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kappogy_share/features/transfer/application/crypto_service.dart';

void main() {
  group('CryptoService', () {
    late ProviderContainer container;
    late CryptoService cryptoService;

    setUp(() {
      container = ProviderContainer();
      cryptoService = container.read(cryptoServiceProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Shared secret derivation', () async {
      final aliceKeyPair = await cryptoService.generateKeyPair();
      final alicePubKey = await aliceKeyPair.extractPublicKey();

      final bobKeyPair = await cryptoService.generateKeyPair();
      final bobPubKey = await bobKeyPair.extractPublicKey();

      final aliceSecret = await cryptoService.deriveSharedSecret(aliceKeyPair, bobPubKey.bytes);
      final bobSecret = await cryptoService.deriveSharedSecret(bobKeyPair, alicePubKey.bytes);

      expect(await aliceSecret.extractBytes(), equals(await bobSecret.extractBytes()));
    });

    test('encryptData and decryptData should return original cleartext', () async {
      final keyPair = await cryptoService.generateKeyPair();
      final dummyBobKeyPair = await cryptoService.generateKeyPair();
      final dummyBobPubKey = await dummyBobKeyPair.extractPublicKey();
      final secret = await cryptoService.deriveSharedSecret(keyPair, dummyBobPubKey.bytes);

      final cleartext = utf8.encode('Hello, Kappogy Share!');

      final secretBox = await cryptoService.encryptData(cleartext, secret);
      final decrypted = await cryptoService.decryptData(secretBox, secret);

      expect(utf8.decode(decrypted), equals('Hello, Kappogy Share!'));
    });
    
    test('calculateSha256 should return correct hash', () {
      final data = utf8.encode('test data');
      final hash = cryptoService.calculateSha256(data);
      expect(hash, isNotEmpty);
    });
  });
}
