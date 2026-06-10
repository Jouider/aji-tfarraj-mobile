package com.ajitfarraj.aji_tfarraj

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so the
// biometric prompt can attach to a FragmentActivity. It's a drop-in base for the
// Flutter embedding and does not change intent / deep-link handling.
class MainActivity : FlutterFragmentActivity()
