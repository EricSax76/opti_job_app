import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';

abstract class EudiWalletNativeChannel {
  Future<bool> isWalletAvailable();

  Future<EudiWalletPresentationResponse> requestPresentation({
    required EudiPresentationRequest request,
  });
}

class MethodChannelEudiWalletNativeChannel implements EudiWalletNativeChannel {
  MethodChannelEudiWalletNativeChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'opti_job_app/eudi_wallet';
  final MethodChannel _channel;

  @override
  Future<bool> isWalletAvailable() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<dynamic>('isWalletAvailable');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<EudiWalletPresentationResponse> requestPresentation({
    required EudiPresentationRequest request,
  }) async {
    if (kIsWeb) {
      throw const EudiWalletNativeException(
        code: 'unsupported-platform',
        message: 'EUDI Wallet nativa no está disponible en Web.',
      );
    }

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'requestPresentation',
        request.toJson(),
      );
      if (result is Map) {
        final data = Map<String, dynamic>.from(result);
        final response = EudiWalletPresentationResponse.fromJson(data);

        if (response.walletSubject.trim().isEmpty ||
            response.verifiablePresentation.trim().isEmpty) {
          throw const EudiWalletNativeException(
            code: 'invalid-wallet-response',
            message:
                'La wallet EUDI devolvió una respuesta incompleta para la presentación.',
          );
        }

        return response;
      }

      throw const EudiWalletNativeException(
        code: 'invalid-wallet-response',
        message: 'La wallet EUDI no devolvió un objeto válido de presentación.',
      );
    } on PlatformException catch (error) {
      if (error.code == 'wallet_cancelled') {
        throw const EudiWalletNativeException(
          code: 'wallet-cancelled',
          message: 'La operación con la wallet EUDI fue cancelada.',
        );
      }
      throw EudiWalletNativeException(
        code: error.code,
        message:
            error.message ??
            'No se pudo completar el intercambio con la wallet EUDI.',
      );
    }
  }
}

class EudiWalletNativeException implements Exception {
  const EudiWalletNativeException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'EudiWalletNativeException($code): $message';
}
