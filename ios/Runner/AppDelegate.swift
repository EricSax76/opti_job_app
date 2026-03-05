import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eudiChannelName = "opti_job_app/eudi_wallet"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let eudiChannel = FlutterMethodChannel(
        name: eudiChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      eudiChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(
            FlutterError(
              code: "channel_unavailable",
              message: "No se pudo resolver el canal EUDI nativo.",
              details: nil
            )
          )
          return
        }

        switch call.method {
        case "isWalletAvailable":
          result(true)
        case "requestPresentation":
          guard let arguments = call.arguments as? [String: Any] else {
            result(
              FlutterError(
                code: "invalid_request",
                message: "La presentation request debe enviarse como objeto.",
                details: nil
              )
            )
            return
          }
          self.handleRequestPresentation(arguments: arguments, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleRequestPresentation(
    arguments: [String: Any],
    result: FlutterResult
  ) {
    let audience = (arguments["audience"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !audience.isEmpty else {
      result(
        FlutterError(
          code: "invalid_request",
          message: "La presentation request debe incluir audience.",
          details: nil
        )
      )
      return
    }

    let purpose =
      (arguments["purpose"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      .flatMap { $0.isEmpty ? nil : $0 } ?? "credential_import"

    let proofSchemaVersion =
      (arguments["proofSchemaVersion"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      .flatMap { $0.isEmpty ? nil : $0 } ?? "2026.1"

    let requestedCredentialTypes = arguments["requestedCredentialTypes"] as? [Any]
    let credentialType = requestedCredentialTypes?
      .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first(where: { !$0.isEmpty }) ?? "VerifiableCredential"

    let constraints = arguments["constraints"] as? [String: Any]
    let providedPresentation =
      (constraints?["verifiablePresentationJwt"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let walletSubject = "did:opti:wallet:\(UUID().uuidString.lowercased())"
    let nowEpochSeconds = Int(Date().timeIntervalSince1970)
    let expEpochSeconds = nowEpochSeconds + (15 * 60)

    let verifiablePresentation =
      (providedPresentation?.isEmpty == false)
      ? providedPresentation!
      : buildUnsignedPresentationJwt(
        walletSubject: walletSubject,
        audience: audience,
        credentialType: credentialType,
        nowEpochSeconds: nowEpochSeconds,
        expEpochSeconds: expEpochSeconds
      )

    result([
      "walletSubject": walletSubject,
      "email": "candidate.eudi@example.com",
      "fullName": "Candidate EUDI",
      "countryCode": "ES",
      "assuranceLevel": "substantial",
      "verifiablePresentation": verifiablePresentation,
      "verificationMethod": "jws:none-mobile-bridge",
      "issuerDid": "did:opti:issuer:mobile-bridge",
      "credentialType": credentialType,
      "proofSchemaVersion": proofSchemaVersion,
      "credential": [
        "type": credentialType,
        "title": "Credencial EUDI demo",
        "issuer": "did:opti:issuer:mobile-bridge",
        "issuedAt": iso8601FromEpoch(nowEpochSeconds),
        "expiresAt": iso8601FromEpoch(expEpochSeconds),
        "metadata": [
          "purpose": purpose,
          "audience": audience,
          "nativeChannel": "ios"
        ]
      ]
    ])
  }

  private func buildUnsignedPresentationJwt(
    walletSubject: String,
    audience: String,
    credentialType: String,
    nowEpochSeconds: Int,
    expEpochSeconds: Int
  ) -> String {
    let header: [String: Any] = [
      "alg": "none",
      "typ": "JWT"
    ]

    let credentialSubject: [String: Any] = [
      "id": walletSubject,
      "email": "candidate.eudi@example.com",
      "fullName": "Candidate EUDI",
      "countryCode": "ES"
    ]

    let vc: [String: Any] = [
      "id": "urn:uuid:\(UUID().uuidString.lowercased())",
      "type": ["VerifiableCredential", credentialType],
      "issuer": "did:opti:issuer:mobile-bridge",
      "credentialSubject": credentialSubject,
      "issuanceDate": iso8601FromEpoch(nowEpochSeconds),
      "expirationDate": iso8601FromEpoch(expEpochSeconds)
    ]

    let payload: [String: Any] = [
      "iss": "did:opti:issuer:mobile-bridge",
      "sub": walletSubject,
      "aud": audience,
      "iat": nowEpochSeconds,
      "exp": expEpochSeconds,
      "assuranceLevel": "substantial",
      "vc": vc
    ]

    let encodedHeader = base64UrlEncode(json: header)
    let encodedPayload = base64UrlEncode(json: payload)
    return "\(encodedHeader).\(encodedPayload)."
  }

  private func base64UrlEncode(json: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
      return ""
    }
    return base64UrlEncode(data: data)
  }

  private func base64UrlEncode(data: Data) -> String {
    return data
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private func iso8601FromEpoch(_ epoch: Int) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(epoch)))
  }
}
