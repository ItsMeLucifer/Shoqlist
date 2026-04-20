import Foundation
import UIKit
import GoogleMobileAds
import google_mobile_ads

/// Programmatic factory for the "shoqlistNativeAd" native ad. No XIB — the
/// view is composed in code so the visual style stays in sync with the
/// Flutter-side theme (brand pink CTA on a light gray rounded surface).
class ShoqlistNativeAdFactory: NSObject, FLTNativeAdFactory {

    private static let brandPink = UIColor(red: 242/255.0, green: 102/255.0, blue: 116/255.0, alpha: 1.0)

    override init() {
        super.init()
        NSLog("[ShoqlistNativeAdFactory] init — factory instance created")
    }

    func createNativeAd(_ nativeAd: NativeAd, customOptions: [AnyHashable: Any]?) -> NativeAdView? {
        NSLog("[ShoqlistNativeAdFactory] createNativeAd called, headline=\(nativeAd.headline ?? "<nil>")")
        let adView = NativeAdView()
        adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        adView.backgroundColor = .clear
        adView.layer.cornerRadius = 8
        adView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        adView.clipsToBounds = true

        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = (nativeAd.icon == nil)
        adView.addSubview(iconView)
        adView.iconView = iconView

        // "Ad" attribution badge
        let attribution = UILabel()
        attribution.translatesAutoresizingMaskIntoConstraints = false
        attribution.text = "Ad"
        attribution.font = .systemFont(ofSize: 10, weight: .bold)
        attribution.textColor = .white
        attribution.textAlignment = .center
        attribution.backgroundColor = Self.brandPink
        attribution.layer.cornerRadius = 4
        attribution.clipsToBounds = true
        adView.addSubview(attribution)

        // Headline
        let headline = UILabel()
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.font = .systemFont(ofSize: 15, weight: .bold)
        headline.textColor = Self.brandPink
        headline.numberOfLines = 1
        headline.lineBreakMode = .byTruncatingTail
        headline.text = nativeAd.headline
        adView.addSubview(headline)
        adView.headlineView = headline

        // Body
        let body = UILabel()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.font = .systemFont(ofSize: 12)
        body.textColor = .black
        body.numberOfLines = 2
        body.lineBreakMode = .byTruncatingTail
        body.text = nativeAd.body
        body.isHidden = (nativeAd.body?.isEmpty ?? true)
        adView.addSubview(body)
        adView.bodyView = body

        // Call to action
        let cta = UIButton(type: .system)
        cta.translatesAutoresizingMaskIntoConstraints = false
        cta.setTitle(nativeAd.callToAction, for: .normal)
        cta.setTitleColor(.white, for: .normal)
        cta.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        cta.backgroundColor = Self.brandPink
        cta.layer.cornerRadius = 18
        cta.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        cta.isUserInteractionEnabled = false
        cta.isHidden = (nativeAd.callToAction?.isEmpty ?? true)
        adView.addSubview(cta)
        adView.callToActionView = cta

        NSLayoutConstraint.activate([
            // Icon
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),

            // Attribution
            attribution.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            attribution.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
            attribution.widthAnchor.constraint(equalToConstant: 22),
            attribution.heightAnchor.constraint(equalToConstant: 14),

            // CTA
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
            cta.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            cta.heightAnchor.constraint(equalToConstant: 36),

            // Headline
            headline.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headline.trailingAnchor.constraint(equalTo: cta.leadingAnchor, constant: -8),
            headline.topAnchor.constraint(equalTo: attribution.bottomAnchor, constant: 4),

            // Body
            body.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            body.trailingAnchor.constraint(equalTo: cta.leadingAnchor, constant: -8),
            body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 2),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}
