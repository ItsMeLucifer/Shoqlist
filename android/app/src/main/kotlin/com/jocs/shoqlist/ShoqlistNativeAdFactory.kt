package com.jocs.shoqlist

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ShoqlistNativeAdFactory(private val context: Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.shoqlist_native_ad, null) as NativeAdView

        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        val body = adView.findViewById<TextView>(R.id.ad_body)
        val bodyText = nativeAd.body
        if (bodyText.isNullOrEmpty()) {
            body.visibility = View.GONE
        } else {
            body.visibility = View.VISIBLE
            body.text = bodyText
        }
        adView.bodyView = body

        val cta = adView.findViewById<Button>(R.id.ad_call_to_action)
        val ctaText = nativeAd.callToAction
        if (ctaText.isNullOrEmpty()) {
            cta.visibility = View.INVISIBLE
        } else {
            cta.visibility = View.VISIBLE
            cta.text = ctaText
        }
        adView.callToActionView = cta

        val icon = adView.findViewById<ImageView>(R.id.ad_icon)
        val iconDrawable = nativeAd.icon?.drawable
        if (iconDrawable != null) {
            icon.setImageDrawable(iconDrawable)
            icon.visibility = View.VISIBLE
        } else {
            icon.visibility = View.GONE
        }
        adView.iconView = icon

        adView.setNativeAd(nativeAd)
        return adView
    }
}
