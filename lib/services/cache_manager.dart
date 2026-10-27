import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic cache manager for storing and retrieving data locally
class CacheManager {
  static const String _cacheKeyPrefix = 'zakat_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  /// Save data to cache with optional expiration
  static Future<bool> setCache(
    String key,
    dynamic value, {
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final expiryKey = '${cacheKey}_expiry';

      // Serialize value
      final jsonString = jsonEncode(_serializeValue(value));

      // Set cache and expiry time
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(
        expiryKey,
        DateTime.now().add(cacheDuration).millisecondsSinceEpoch,
      );

      debugPrint('💾 [Cache] Saved: $key (expires in ${cacheDuration.inHours}h)');
      return true;
    } catch (e) {
      debugPrint('❌ [Cache] Error saving $key: $e');
      return false;
    }
  }

  /// Retrieve data from cache (returns null if expired)
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final expiryKey = '${cacheKey}_expiry';

      // Check expiration
      final expiryTime = prefs.getInt(expiryKey);
      if (expiryTime != null &&
          DateTime.now().millisecondsSinceEpoch > expiryTime) {
        debugPrint('⏰ [Cache] Expired: $key');
        await prefs.remove(cacheKey);
        await prefs.remove(expiryKey);
        return null;
      }

      // Retrieve and deserialize
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) return null;

      final value = _deserializeValue(jsonDecode(jsonString));
      debugPrint('✅ [Cache] Retrieved: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [Cache] Error retrieving $key: $e');
      return null;
    }
  }

  /// Get typed cache value
  static Future<T?> getCacheTyped<T>(String key) async {
    final value = await getCache(key);
    if (value is T) return value;
    return null;
  }

  /// Check if cache exists and is valid
  static Future<bool> hasCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final expiryKey = '${cacheKey}_expiry';

      if (!prefs.containsKey(cacheKey)) return false;

      final expiryTime = prefs.getInt(expiryKey);
      if (expiryTime != null &&
          DateTime.now().millisecondsSinceEpoch > expiryTime) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove specific cache
  static Future<bool> removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final expiryKey = '${cacheKey}_expiry';

      await prefs.remove(cacheKey);
      await prefs.remove(expiryKey);

      debugPrint('🗑️  [Cache] Removed: $key');
      return true;
    } catch (e) {
      debugPrint('❌ [Cache] Error removing $key: $e');
      return false;
    }
  }

  /// Clear all cache
  static Future<bool> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }

      debugPrint('🗑️  [Cache] Cleared all cache');
      return true;
    } catch (e) {
      debugPrint('❌ [Cache] Error clearing cache: $e');
      return false;
    }
  }

  /// Get cache size (approximate, in bytes)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final value = prefs.get(key);
          totalSize += value.toString().length;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Helper: Serialize value to JSON-compatible format
  static dynamic _serializeValue(dynamic value) {
    if (value is DateTime) {
      return {'__type': 'DateTime', 'value': value.toIso8601String()};
    } else if (value is List) {
      return {'__type': 'List', 'value': value.map(_serializeValue).toList()};
    } else if (value is Map) {
      return {
        '__type': 'Map',
        'value': value.map((k, v) => MapEntry(k.toString(), _serializeValue(v)))
      };
    }
    return value;
  }

  /// Helper: Deserialize value from JSON format
  static dynamic _deserializeValue(dynamic value) {
    if (value is Map && value.containsKey('__type')) {
      final type = value['__type'];
      final data = value['value'];

      if (type == 'DateTime') {
        return DateTime.parse(data as String);
      } else if (type == 'List') {
        return (data as List).map(_deserializeValue).toList();
      } else if (type == 'Map') {
        final map = data as Map;
        return map.map((k, v) =>
            MapEntry(k, _deserializeValue(v)));
      }
    }
    return value;
  }
}

/// Specific cache manager for dashboard metrics
class DashboardCacheManager {
  static const String _totalDonationsKey = 'dashboard_total_donations';
  static const String _activeBeneficiariesKey = 'dashboard_active_beneficiaries';
  static const String _pendingApprovalsKey = 'dashboard_pending_approvals';
  static const String _fundDistributionKey = 'dashboard_fund_distribution';

  /// Cache total donations
  static Future<bool> cacheTotalDonations(double amount) =>
      CacheManager.setCache(_totalDonationsKey, amount);

  /// Get cached total donations
  static Future<double?> getCachedTotalDonations() async {
    final value = await CacheManager.getCacheTyped<double>(_totalDonationsKey);
    return value;
  }

  /// Cache active beneficiaries count
  static Future<bool> cacheActiveBeneficiaries(int count) =>
      CacheManager.setCache(_activeBeneficiariesKey, count);

  /// Get cached active beneficiaries
  static Future<int?> getCachedActiveBeneficiaries() async {
    final value = await CacheManager.getCacheTyped<int>(_activeBeneficiariesKey);
    return value;
  }

  /// Cache pending approvals
  static Future<bool> cachePendingApprovals(int count) =>
      CacheManager.setCache(_pendingApprovalsKey, count);

  /// Get cached pending approvals
  static Future<int?> getCachedPendingApprovals() async {
    final value = await CacheManager.getCacheTyped<int>(_pendingApprovalsKey);
    return value;
  }

  /// Cache fund distribution
  static Future<bool> cacheFundDistribution(Map<String, double> distribution) =>
      CacheManager.setCache(_fundDistributionKey, distribution);

  /// Get cached fund distribution
  static Future<Map<String, double>?> getCachedFundDistribution() async {
    final value = await CacheManager.getCache(_fundDistributionKey);
    if (value is Map) {
      return Map<String, double>.from(
          value.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
    }
    return null;
  }

  /// Clear dashboard cache
  static Future<bool> clearDashboardCache() async {
    await CacheManager.removeCache(_totalDonationsKey);
    await CacheManager.removeCache(_activeBeneficiariesKey);
    await CacheManager.removeCache(_pendingApprovalsKey);
    await CacheManager.removeCache(_fundDistributionKey);
    return true;
  }
}

/// Specific cache manager for donor analytics
class DonorCacheManager {
  static const String _topDonorsPrefix = 'donor_top_donors_';
  static const String _donorAnalyticsPrefix = 'donor_analytics_';

  /// Cache top donors list
  static Future<bool> cacheTopDonors(
    String donorId,
    Map<String, dynamic> analytics,
  ) =>
      CacheManager.setCache('$_topDonorsPrefix$donorId', analytics);

  /// Get cached donor analytics
  static Future<Map<String, dynamic>?> getCachedDonorAnalytics(
      String donorId) async {
    final value =
        await CacheManager.getCache('$_donorAnalyticsPrefix$donorId');
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Clear donor cache
  static Future<bool> clearDonorCache(String donorId) =>
      CacheManager.removeCache('$_topDonorsPrefix$donorId');

  /// Clear all donor cache
  static Future<bool> clearAllDonorCache() =>
      CacheManager.clearAllCache(); // In real app, use pattern matching
}

/// Specific cache manager for beneficiary data
class BeneficiaryCacheManager {
  static const String _beneficiaryPrefix = 'beneficiary_impact_';
  static const String _beneficiariesListKey = 'beneficiaries_list';

  /// Cache beneficiary impact
  static Future<bool> cacheBeneficiaryImpact(
    String beneficiaryId,
    Map<String, dynamic> impact,
  ) =>
      CacheManager.setCache('$_beneficiaryPrefix$beneficiaryId', impact);

  /// Get cached beneficiary impact
  static Future<Map<String, dynamic>?> getCachedBeneficiaryImpact(
      String beneficiaryId) async {
    final value =
        await CacheManager.getCache('$_beneficiaryPrefix$beneficiaryId');
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Cache all beneficiaries list
  static Future<bool> cacheBeneficiariesList(
    List<Map<String, dynamic>> beneficiaries,
  ) =>
      CacheManager.setCache(_beneficiariesListKey, beneficiaries);

  /// Get cached beneficiaries list
  static Future<List<Map<String, dynamic>>?> getCachedBeneficiariesList() async {
    final value = await CacheManager.getCache(_beneficiariesListKey);
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return null;
  }

  /// Clear beneficiary cache
  static Future<bool> clearBeneficiaryCache(String beneficiaryId) =>
      CacheManager.removeCache('$_beneficiaryPrefix$beneficiaryId');

  /// Clear all beneficiary cache
  static Future<bool> clearAllBeneficiaryCache() async {
    await CacheManager.removeCache(_beneficiariesListKey);
    return true;
  }
}
