// lib/services/data_cache_service.dart
import 'package:flutter/foundation.dart';

class DataCacheService {
  // Singleton instance
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();
  
  // Cache storage
  final Map<String, dynamic> _cache = {};
  
  // Basic operations
  void set(String key, dynamic data) {
    _cache[key] = data;
    if (kDebugMode) {
      print('Cache: Set $key with data');
    }
  }
  
  T? get<T>(String key) {
    if (_cache.containsKey(key)) {
      if (kDebugMode) {
        print('Cache: Retrieved $key from cache');
      }
      return _cache[key] as T?;
    }
    if (kDebugMode) {
      print('Cache: Key $key not found');
    }
    return null;
  }
  
  bool has(String key) => _cache.containsKey(key);
  
  void remove(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      print('Cache: Removed $key from cache');
    }
  }
  
  void clear() {
    _cache.clear();
    if (kDebugMode) {
      print('Cache: Cache cleared');
    }
  }
  
  // Helper for time-based cache invalidation
  void setWithExpiry(String key, dynamic data, Duration expiry) {
    set(key, data);
    Future.delayed(expiry, () => remove(key));
    if (kDebugMode) {
      print('Cache: Set $key with ${expiry.inMinutes} minute expiry');
    }
  }
}