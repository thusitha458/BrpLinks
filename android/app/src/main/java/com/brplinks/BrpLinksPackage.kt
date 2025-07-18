package com.brplinks

import android.view.View
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ReactShadowNode
import com.facebook.react.uimanager.ViewManager

class BrpLinksPackage: ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(BrpLinksModule(reactContext))
  }

  override fun createViewManagers(p0: ReactApplicationContext): List<ViewManager<View, ReactShadowNode<*>>> {
    return emptyList()
  }
}