import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crash_reporting_service.dart';

/// Observer Riverpod qui log automatiquement les erreurs de providers
/// vers Firebase Crashlytics avec le nom du provider en contexte.
class CrashlyticsProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();

    CrashReportingService.recordError(
      error,
      stackTrace,
      reason: 'Provider error: $name',
      extra: {
        'provider_name': name,
        'provider_type': provider.runtimeType.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('[ProviderObserver] $name a échoué: $error');
    }
  }
}
