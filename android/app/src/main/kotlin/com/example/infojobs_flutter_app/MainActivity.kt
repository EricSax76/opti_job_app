package com.example.infojobs_flutter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.Base64
import java.util.UUID

class MainActivity : FlutterActivity() {
  private val channelName = "opti_job_app/eudi_wallet"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "isWalletAvailable" -> result.success(true)
          "requestPresentation" -> handleRequestPresentation(call, result)
          else -> result.notImplemented()
        }
      }
  }

  private fun handleRequestPresentation(call: MethodCall, result: MethodChannel.Result) {
    val arguments = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
    val audience = arguments["audience"]?.toString()?.trim().orEmpty()
    if (audience.isEmpty()) {
      result.error(
        "invalid_request",
        "La presentation request debe incluir audience.",
        null,
      )
      return
    }

    val purpose = arguments["purpose"]?.toString()?.trim().orEmpty().ifEmpty {
      "credential_import"
    }
    val proofSchemaVersion =
      arguments["proofSchemaVersion"]?.toString()?.trim().orEmpty().ifEmpty {
        "2026.1"
      }

    val requestedTypes =
      (arguments["requestedCredentialTypes"] as? List<*>)
        ?.mapNotNull { item -> item?.toString()?.trim()?.takeIf { it.isNotEmpty() } }
        .orEmpty()
    val credentialType = requestedTypes.firstOrNull() ?: "VerifiableCredential"

    val constraints = arguments["constraints"] as? Map<*, *>
    val providedPresentation = constraints
      ?.get("verifiablePresentationJwt")
      ?.toString()
      ?.trim()
      .orEmpty()

    val walletSubject = "did:opti:wallet:${UUID.randomUUID()}"
    val nowEpochSeconds = Instant.now().epochSecond
    val expEpochSeconds = nowEpochSeconds + 15 * 60

    val verifiablePresentation =
      if (providedPresentation.isNotEmpty()) {
        providedPresentation
      } else {
        buildUnsignedPresentationJwt(
          walletSubject = walletSubject,
          audience = audience,
          credentialType = credentialType,
          nowEpochSeconds = nowEpochSeconds,
          expEpochSeconds = expEpochSeconds,
        )
      }

    result.success(
      mapOf(
        "walletSubject" to walletSubject,
        "email" to "candidate.eudi@example.com",
        "fullName" to "Candidate EUDI",
        "countryCode" to "ES",
        "assuranceLevel" to "substantial",
        "verifiablePresentation" to verifiablePresentation,
        "verificationMethod" to "jws:none-mobile-bridge",
        "issuerDid" to "did:opti:issuer:mobile-bridge",
        "credentialType" to credentialType,
        "proofSchemaVersion" to proofSchemaVersion,
        "credential" to mapOf(
          "type" to credentialType,
          "title" to "Credencial EUDI demo",
          "issuer" to "did:opti:issuer:mobile-bridge",
          "issuedAt" to Instant.ofEpochSecond(nowEpochSeconds).toString(),
          "expiresAt" to Instant.ofEpochSecond(expEpochSeconds).toString(),
          "metadata" to mapOf(
            "purpose" to purpose,
            "audience" to audience,
            "nativeChannel" to "android",
          ),
        ),
      ),
    )
  }

  private fun buildUnsignedPresentationJwt(
    walletSubject: String,
    audience: String,
    credentialType: String,
    nowEpochSeconds: Long,
    expEpochSeconds: Long,
  ): String {
    val header = JSONObject()
      .put("alg", "none")
      .put("typ", "JWT")

    val credentialSubject = JSONObject()
      .put("id", walletSubject)
      .put("email", "candidate.eudi@example.com")
      .put("fullName", "Candidate EUDI")
      .put("countryCode", "ES")

    val vc = JSONObject()
      .put("id", "urn:uuid:${UUID.randomUUID()}")
      .put("type", JSONArray(listOf("VerifiableCredential", credentialType)))
      .put("issuer", "did:opti:issuer:mobile-bridge")
      .put("credentialSubject", credentialSubject)
      .put("issuanceDate", Instant.ofEpochSecond(nowEpochSeconds).toString())
      .put("expirationDate", Instant.ofEpochSecond(expEpochSeconds).toString())

    val payload = JSONObject()
      .put("iss", "did:opti:issuer:mobile-bridge")
      .put("sub", walletSubject)
      .put("aud", audience)
      .put("iat", nowEpochSeconds)
      .put("exp", expEpochSeconds)
      .put("assuranceLevel", "substantial")
      .put("vc", vc)

    val encodedHeader = base64UrlEncode(header.toString().toByteArray(StandardCharsets.UTF_8))
    val encodedPayload = base64UrlEncode(payload.toString().toByteArray(StandardCharsets.UTF_8))
    return "$encodedHeader.$encodedPayload."
  }

  private fun base64UrlEncode(input: ByteArray): String {
    return Base64.getUrlEncoder().withoutPadding().encodeToString(input)
  }
}
