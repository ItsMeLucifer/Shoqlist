import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shoqlist/utilities/ad_helper.dart';

/// Renders a single Native Advanced banner styled via platform factories
/// registered under [AdHelper.nativeAdFactoryId].
///
/// - Loads once in [initState].
/// - Keeps a fixed-height placeholder while loading so the layout doesn't jump.
/// - Renders nothing if the ad fails to load.
/// - `inFeedStyle: true` → rounded on all corners + horizontal margin, suitable
///   as the last item in a scrollable ListView. Default → top corners rounded
///   only, full width, for use docked above a BottomNavigationBar.
class NativeAdBanner extends StatefulWidget {
  const NativeAdBanner({
    super.key,
    this.height = 85,
    this.inFeedStyle = false,
  });

  final double height;
  final bool inFeedStyle;

  @override
  State<NativeAdBanner> createState() => _NativeAdBannerState();
}

class _NativeAdBannerState extends State<NativeAdBanner>
    with AutomaticKeepAliveClientMixin<NativeAdBanner> {
  NativeAd? _nativeAd;
  _AdState _state = _AdState.loading;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: AdHelper.nativeAdFactoryId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _state = _AdState.loaded);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            debugPrint('NativeAd failed to load: $error');
          }
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _state = _AdState.failed;
          });
        },
      ),
    );
    _nativeAd = ad..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required przez AutomaticKeepAliveClientMixin
    if (_state == _AdState.failed) {
      return const SizedBox.shrink();
    }
    final borderRadius = widget.inFeedStyle
        ? BorderRadius.circular(10)
        : const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          );
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: borderRadius,
      ),
      child: _state == _AdState.loaded && _nativeAd != null
          ? AdWidget(ad: _nativeAd!)
          : const SizedBox.shrink(),
    );
  }
}

enum _AdState { loading, loaded, failed }
