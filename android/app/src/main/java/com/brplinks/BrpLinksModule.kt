package com.brplinks

import android.net.Uri
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerClient.InstallReferrerResponse
import com.android.installreferrer.api.InstallReferrerStateListener
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException

class BrpLinksModule(reactContext: ReactApplicationContext): ReactContextBaseJavaModule(reactContext) {
  private val httpClient = OkHttpClient()
  private lateinit var referrerClient: InstallReferrerClient

  override fun getName() = "BrpLinksModule"

  @ReactMethod
  fun initialize(promise: Promise) {
    callInstallReferrer { value: String ->
      if (value.isNotBlank()) {
        promise.resolve(value)
      } else {
        callTheAPI(promise)
      }
    }
  }

  private fun callInstallReferrer(cb: (value: String) -> Unit) {
    referrerClient = InstallReferrerClient.newBuilder(reactApplicationContext).build()
    referrerClient.startConnection(object: InstallReferrerStateListener {
      override fun onInstallReferrerSetupFinished(responseCode: Int) {
        when(responseCode) {
          InstallReferrerResponse.OK -> {
            // connection established
            val response = referrerClient.installReferrer
            val referrerUrl = response.installReferrer

            val uri = Uri.parse("https://dummy.url/?$referrerUrl")
            val campaignValue = uri.getQueryParameter("utm_campaign")
            if (campaignValue != null) {
              // success
              cb(campaignValue)
            } else {
              // no campaign value
              cb("")
            }

            referrerClient.endConnection()
          }
          InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
            // API not available on the current Play Store app.
            cb("")
          }
          InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
            // Connection couldn't be established.
            cb("")
          }
          else -> {
            cb("")
          }
        }
      }

      override fun onInstallReferrerServiceDisconnected() {
        // nothing to do
      }
    })
  }

  private fun callTheAPI(promise: Promise) {
    val request = Request.Builder()
      .url("https://fbd-links.rootcode.software/api/android/record-retrieval")
      .post(ByteArray(0).toRequestBody(null))
      .build()

    httpClient.newCall(request).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        promise.reject(Error("Connection to the API failed"))
      }

      override fun onResponse(call: Call, response: Response) {
        // TODO: what is this use block? can there be an error? what happens if there's an error?
        response.use {
          if (!response.isSuccessful) {
            promise.reject(Error("Response failed"))
            return
          }

          val responseBody = response.body?.string()
          if (responseBody != null) {
            val json = JSONObject(responseBody)
            val providerCode = json.getString("providerCode")

            promise.resolve(providerCode)
            return
          }
        }
        promise.reject(Error("Invalid response"))
      }
    })
  }
}