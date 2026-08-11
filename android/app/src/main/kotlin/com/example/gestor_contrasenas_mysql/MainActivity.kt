package com.example.gestor_contrasenas_mysql

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterFragmentActivity() {
	companion object {
		private const val CHANNEL = "gestor_contrasenas/biometric_keystore"
		private const val KEY_ALIAS = "gestor_contrasenas_biometric_key"
		private const val ANDROID_KEYSTORE = "AndroidKeyStore"
		private const val AUTH_VALIDITY_SECONDS = 30
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"envolverClaveMaestra" -> {
						val clave = call.argument<String>("clave")
						if (clave == null) {
							result.error("ARGUMENTO_INVALIDO", "Falta la clave maestra", null)
						} else {
							envolverClaveMaestra(clave, result)
						}
					}
					"desenvolverClaveMaestra" -> {
						val blob = call.argument<String>("blob")
						if (blob == null) {
							result.error("ARGUMENTO_INVALIDO", "Falta el blob biométrico", null)
						} else {
							desenvolverClaveMaestra(blob, result)
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun obtenerClaveKeystore(): java.security.Key {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			throw IllegalStateException("Android no soporta AES-GCM en Keystore")
		}

		val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
		if (!keyStore.containsAlias(KEY_ALIAS)) {
			val generator = KeyGenerator.getInstance(
				KeyProperties.KEY_ALGORITHM_AES,
				ANDROID_KEYSTORE,
			)
			val builder = KeyGenParameterSpec.Builder(
				KEY_ALIAS,
				KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
			)
				.setBlockModes(KeyProperties.BLOCK_MODE_GCM)
				.setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
				.setUserAuthenticationRequired(true)
				.setInvalidatedByBiometricEnrollment(true)

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
				builder.setUserAuthenticationParameters(
					AUTH_VALIDITY_SECONDS,
					KeyProperties.AUTH_BIOMETRIC_STRONG,
				)
			} else {
				@Suppress("DEPRECATION")
				builder.setUserAuthenticationValidityDurationSeconds(
					AUTH_VALIDITY_SECONDS,
				)
			}

			generator.init(builder.build())
			generator.generateKey()
		}

		return keyStore.getKey(KEY_ALIAS, null)
			?: throw IllegalStateException("No se pudo obtener la clave biométrica")
	}

	private fun envolverClaveMaestra(clave: String, result: MethodChannel.Result) {
		try {
			val cipher = Cipher.getInstance("AES/GCM/NoPadding")
			cipher.init(Cipher.ENCRYPT_MODE, obtenerClaveKeystore())
			autenticar(cipher, result) { autenticado ->
				val blob = Base64.encodeToString(
					cipher.iv + autenticado.doFinal(clave.toByteArray(StandardCharsets.UTF_8)),
					Base64.NO_WRAP,
				)
				result.success(blob)
			}
		} catch (error: Exception) {
			result.error("BIOMETRIA_NO_DISPONIBLE", "No se pudo preparar la clave biométrica", null)
		}
	}

	private fun desenvolverClaveMaestra(blob: String, result: MethodChannel.Result) {
		try {
			val datos = Base64.decode(blob, Base64.NO_WRAP)
			if (datos.size <= 12) throw IllegalArgumentException("Blob biométrico inválido")
			val iv = datos.copyOfRange(0, 12)
			val cifrado = datos.copyOfRange(12, datos.size)
			val cipher = Cipher.getInstance("AES/GCM/NoPadding")
			cipher.init(
				Cipher.DECRYPT_MODE,
				obtenerClaveKeystore(),
				GCMParameterSpec(128, iv),
			)
			autenticar(cipher, result) { autenticado ->
				val clave = autenticado.doFinal(cifrado).toString(StandardCharsets.UTF_8)
				result.success(clave)
			}
		} catch (error: Exception) {
			result.error("BIOMETRIA_NO_DISPONIBLE", "No se pudo recuperar la clave biométrica", null)
		}
	}

	private fun autenticar(
		cipher: Cipher,
		result: MethodChannel.Result,
		alAutenticar: (Cipher) -> Unit,
	) {
		val executor = ContextCompat.getMainExecutor(this)
		val prompt = BiometricPrompt(
			this,
			executor,
			object : BiometricPrompt.AuthenticationCallback() {
				override fun onAuthenticationSucceeded(
					authenticationResult: BiometricPrompt.AuthenticationResult,
				) {
					val cryptoCipher = authenticationResult.cryptoObject?.cipher
					if (cryptoCipher == null) {
						result.error("BIOMETRIA_INVALIDA", "No se obtuvo una operación biométrica válida", null)
					} else {
						try {
							alAutenticar(cryptoCipher)
						} catch (error: Exception) {
							result.error("BIOMETRIA_NO_DISPONIBLE", "No se pudo usar la clave biométrica", null)
						}
					}
				}

				override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
					result.error("BIOMETRIA_CANCELADA", "La autenticación biométrica no fue completada", null)
				}

				override fun onAuthenticationFailed() {
					// BiometricPrompt mantiene el diálogo activo para permitir otro intento.
				}
			},
		)
		val promptInfo = BiometricPrompt.PromptInfo.Builder()
			.setTitle("Confirma tu identidad")
			.setSubtitle("Se requiere biometría para acceder a tus contraseñas")
			.setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
			.build()
		prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
	}
}
