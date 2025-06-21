package com.brplinks

import android.app.Application
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerClient.InstallReferrerResponse
import com.android.installreferrer.api.InstallReferrerStateListener
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.load
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.react.flipper.ReactNativeFlipper
import com.facebook.soloader.SoLoader
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import org.json.JSONObject


class MainApplication : Application(), ReactApplication {

  private val client = OkHttpClient()
  private lateinit var referrerClient: InstallReferrerClient

  override val reactNativeHost: ReactNativeHost =
      object : DefaultReactNativeHost(this) {
        override fun getPackages(): List<ReactPackage> {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // packages.add(new MyReactNativePackage());
          return PackageList(this).packages
        }

        override fun getJSMainModuleName(): String = "index"

        override fun getUseDeveloperSupport(): Boolean = BuildConfig.DEBUG

        override val isNewArchEnabled: Boolean = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
        override val isHermesEnabled: Boolean = BuildConfig.IS_HERMES_ENABLED
      }

  override val reactHost: ReactHost
    get() = getDefaultReactHost(this.applicationContext, reactNativeHost)

  override fun onCreate() {
    super.onCreate()

    callInstallReferrer()
    callTheAPI()

    initializeReactNative()
  }

  private fun initializeReactNative() {
    SoLoader.init(this, false)
    if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
      // If you opted-in for the New Architecture, we load the native entry point for this app.
      load()
    }
    ReactNativeFlipper.initializeFlipper(this, reactNativeHost.reactInstanceManager)
  }

  private fun callInstallReferrer() {
    referrerClient = InstallReferrerClient.newBuilder(this).build()
    referrerClient.startConnection(object: InstallReferrerStateListener {
      override fun onInstallReferrerSetupFinished(responseCode: Int) {
        when(responseCode) {
          InstallReferrerResponse.OK -> {
            // connection established
            val response = referrerClient.installReferrer
            val referrerUrl = response.installReferrer

            val uri = Uri.parse("https://dummy.url/?$referrerUrl")
            val referrerValue = uri.getQueryParameter("referrer")
            if (referrerValue != null) {
              Handler(Looper.getMainLooper()).post {
                Toast.makeText(
                  this@MainApplication,
                  "[REFERRER] S: $referrerValue",
                  Toast.LENGTH_SHORT
                ).show()
              }
            } else {
              Handler(Looper.getMainLooper()).post {
                Toast.makeText(
                  this@MainApplication,
                  "[REFERRER] F: ${referrerUrl.takeLast(20)}",
                  Toast.LENGTH_SHORT
                ).show()
              }
            }
            // TODO: "Not yet implemented"
          }
          InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
            // API not available on the current Play Store app.
            Handler(Looper.getMainLooper()).post {
              Toast.makeText(this@MainApplication, "[REFERRER] FEATURE_NOT_SUPPORTED", Toast.LENGTH_SHORT).show()
            }
          }
          InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
            // Connection couldn't be established.
            Handler(Looper.getMainLooper()).post {
              Toast.makeText(this@MainApplication, "[REFERRER] SERVICE_UNAVAILABLE", Toast.LENGTH_SHORT).show()
            }
          }
        }
      }

      override fun onInstallReferrerServiceDisconnected() {
        // TODO: "Not yet implemented"
      }
    })
  }

  private fun callTheAPI() {
    val request = Request.Builder()
      .url("https://fbd-links.rootcode.software/api/visits/latest")
      .build()

    client.newCall(request).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        // do nothing
      }

      override fun onResponse(call: Call, response: Response) {
        response.use {
          if (!response.isSuccessful) {
            Handler(Looper.getMainLooper()).post {
              Toast.makeText(this@MainApplication, "[IP] Failed: ${response.code}", Toast.LENGTH_SHORT).show()
            }
            return
          }

          val responseBody = response.body?.string()
          if (responseBody != null) {
            val json = JSONObject(responseBody)
            val latestVisit = json.getJSONObject("latestVisit")
            val code = latestVisit.getString("code")

            Handler(Looper.getMainLooper()).post {
              Toast.makeText(
                this@MainApplication,
                "[IP] Success: $code",
                Toast.LENGTH_SHORT
              ).show()
            }
            return
          }
        }
      }
    })
  }
}
