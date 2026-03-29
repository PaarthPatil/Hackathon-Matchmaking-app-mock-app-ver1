import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    debugPrint('🛡️ ${provider.name ?? provider.runtimeType} changed: $previousValue → $newValue');
  }

  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    debugPrint('🛡️ Provider added: ${provider.name ?? provider.runtimeType} = $value');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    debugPrint('🛡️ Provider disposed: ${provider.name ?? provider.runtimeType}');
  }
}
