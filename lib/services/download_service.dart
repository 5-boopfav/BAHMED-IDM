import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item.dart';

class DownloadStorage {
  DownloadStorage._();

  static final DownloadStorage instance = DownloadStorage._();

  static const String _storageKey = 'bahmed_download_history';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // حفظ سجل التنزيلات
  Future<void> saveDownloads(List<DownloadItem> downloads) async {
    final data = downloads.map((item) => item.toJson()).toList();

    await _preferences.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  // استرجاع سجل التنزيلات
  Future<List<DownloadItem>> loadDownloads() async {
    final savedData = await _preferences.getString(_storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) => DownloadItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      return [];
    }
  }

  // إضافة تنزيل إلى السجل
  Future<void> addDownload(DownloadItem item) async {
    final downloads = await loadDownloads();

    downloads.insert(0, item);

    await saveDownloads(downloads);
  }

  // حذف تنزيل من السجل
  Future<void> deleteDownload(String id) async {
    final downloads = await loadDownloads();

    downloads.removeWhere((item) => item.id == id);

    await saveDownloads(downloads);
  }

  // مسح السجل بالكامل
  Future<void> clearHistory() async {
    await _preferences.remove(_storageKey);
  }
}
