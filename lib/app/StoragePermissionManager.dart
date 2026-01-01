import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// كلاس شامل لإدارة صلاحيات التخزين لجميع المنصات
/// يدعم: Android, iOS, Web, Windows, macOS, Linux
class StoragePermissionManager {
  // Singleton pattern
  static final StoragePermissionManager _instance = StoragePermissionManager._internal();
  factory StoragePermissionManager() => _instance;
  StoragePermissionManager._internal();

  // Keys for SharedPreferences
  static const String _permissionRequestedKey = 'storage_permission_requested';
  static const String _permissionGrantedKey = 'storage_permission_granted';
  static const String _permissionPermanentlyDeniedKey = 'storage_permission_permanently_denied';

  // SharedPreferences instance
  SharedPreferences? _prefs;

  /// تهيئة SharedPreferences
  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// ===== الواجهة الرئيسية =====

  /// التحقق من صلاحية التخزين بناءً على المنصة
  Future<bool> checkStoragePermission() async {
    await _initPrefs();

    if (kIsWeb) {
      // الويب: لا يحتاج صلاحيات صريحة للتخزين الخفيف
      return await _checkWebStorageCapability();
    } else {
      // Android/iOS/Windows/macOS/Linux
      return await _checkMobileStoragePermission();
    }
  }

  /// طلب صلاحية التخزين مع عرض رسالة مناسبة للمنصة
  Future<bool> requestStoragePermission(BuildContext context) async {
    print('🚀 requestStoragePermission تم استدعاؤه');

    Fluttertoast.showToast(
      msg: "طلب الصلاحية - 1 ✅",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.blue,
    );

    await _initPrefs();

    // إذا كانت الصلاحية ممنوحة بالفعل، لا نطلبها مجدداً
    final bool alreadyGranted = await _isPermissionAlreadyGranted();
    if (alreadyGranted) {
      return true;
    }

    // التحقق إذا سبق طلب الصلاحية ورفضها
    final bool previouslyRequested = _prefs!.getBool(_permissionRequestedKey) ?? false;

    if (previouslyRequested) {
      // إذا سبق رفضها، نعرض رسالة إقناع فقط
      return await _showPersuasionDialog(context);
    }

    // أول طلب للصلاحية فقط
    return await _showInitialPermissionDialog(context);
  }

  /// ===== الويب =====
  Future<bool> _checkWebStorageCapability() async {
    try {
      // للويب، نتحقق فقط من إمكانية التخزين الخفيف
      // معظم المتصفحات تدعم localStorage بدون صلاحيات
      return true;
    } catch (e) {
      print('خطأ في التحقق من إمكانيات الويب: $e');
      return false;
    }
  }

  /// ===== الجوال (Android/iOS) =====
  Future<bool> _checkMobileStoragePermission() async {
    try {
      if (kIsWeb) return true;

      if (Platform.isAndroid) {
        return await _checkAndroidPermission();
      } else if (Platform.isIOS) {
        return await _checkIOSPermission();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // للأنظمة المكتبية، الصلاحيات عادةً ممنوحة
        return true;
      }

      return true;
    } catch (e) {
      print('خطأ في التحقق من صلاحية الجوال: $e');
      return false;
    }
  }

  Future<bool> _checkAndroidPermission() async {
    try {
      // لـ Android نطلب صلاحية التخزين
      final status = await ph.Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      print('خطأ في التحقق من صلاحية Android: $e');
      return false;
    }
  }

  Future<bool> _checkIOSPermission() async {
    try {
      // iOS: نطلب صلاحية الوصول إلى الصور/التخزين
      final status = await ph.Permission.photos.status;
      if (status.isGranted) return true;

      // بديل: التحقق من إمكانية الوصول إلى المستندات
      return await _checkIOSDocumentsAccess();
    } catch (e) {
      print('خطأ في التحقق من صلاحية iOS: $e');
      return false; // Fallback
    }
  }

  Future<bool> _checkIOSDocumentsAccess() async {
    // iOS يسمح بالتخزين في مجلد المستندات بدون صلاحيات صريحة
    // (في حدود مساحة التطبيق)
    return true;
  }

  /// ===== الحوارات والرسائل =====

  Future<bool> _showInitialPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildPermissionDialog(
          context,
          title: 'صلاحية تخزين الملفات',
          message: 'يحتاج التطبيق إلى صلاحية تخزين الملفات لحفظ بياناتك وتحميلها بشكل آمن.',
          isInitialRequest: true,
        );
      },
    );

    if (result == true) {
      print('✅ المستخدم وافق على منح الصلاحية');
      final granted = await _grantPermission();

      if (granted) {
        await _markPermissionAsGranted();

        Fluttertoast.showToast(
          msg: "تم منح صلاحية التخزين بنجاح ✓",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Fluttertoast.showToast(
          msg: "لم يتمكن من الحصول على الصلاحية",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.white70,
        );
        return false;
      }
    } else {
      print('❌ المستخدم رفض منح الصلاحية');
      await _markPermissionAsRequested();

      Fluttertoast.showToast(
        msg: "لم يتم الحصول على صلاحية تخزين الملفات",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
      return false;
    }
  }


  Future<bool> _showPersuasionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF352F44) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white54,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 60,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'صلاحية التخزين مطلوبة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    color: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF141617),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لقد رفضت صلاحية التخزين سابقاً. '
                      'بدونها، لن تتمكن من حفظ الملفات والبيانات. '
                      'هل تريد منح الصلاحية الآن؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    color: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF141617),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الرفض (لا، شكراً) - على شكل زر في اليسار
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                            Fluttertoast.showToast(
                              msg: "لم يتم منح صلاحية التخزين",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: Colors.red,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF353B3E),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'لا، شكراً',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Calibri',
                            ),
                          ),
                        ),
                      ),
                    ),

                    // زر القبول (نعم، منح الصلاحية) - على شكل زر في اليمين
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
                            foregroundColor: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF353B3E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                          ),
                          child: Text(
                            'نعم، منح الصلاحية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Calibri',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      final granted = await _grantPermission();
      if (granted) {
        await _markPermissionAsGranted();

        Fluttertoast.showToast(
          msg: "تم منح صلاحية التخزين بنجاح ✓",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
        );

        return true;
      }
    }

    return false;
  }







  Widget _buildPermissionDialog(
      BuildContext context, {
        required String title,
        required String message,
        required bool isInitialRequest,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF352F44) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage,
              size: 60,
              color: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Calibri',
                fontSize: 18,
                color: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF141617),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontFamily: 'Calibri',
                fontSize: 16,
                color: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF141617),
              ),
            ),
            if (kIsWeb) const SizedBox(height: 8),
            if (kIsWeb) Text(
              'سيتم تخزين البيانات محلياً في ذاكرة المتصفح بأمان تام.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB8B2C9) : const Color(0xFF5D6C7A),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر الرفض (لا، شكراً) - على شكل زر
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF353B3E),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'لا، شكراً',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Calibri',
                        ),
                      ),
                    ),
                  ),
                ),

                // زر القبول (موافق) - على شكل زر
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF5C5470) : const Color(0xFFD9EAFD),
                        foregroundColor: isDark ? const Color(0xFFFAF0E6) : const Color(0xFF353B3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      child: Text(
                        'موافق',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Calibri',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  /// ===== إدارة حالة الصلاحية =====
  Future<bool> _isPermissionAlreadyGranted() async {
    final bool savedAsGranted = _prefs!.getBool(_permissionGrantedKey) ?? false;
    if (savedAsGranted) return true;

    return await checkStoragePermission();
  }

  /// منح الصلاحية فعلياً
  Future<bool> _grantPermission() async {
    if (kIsWeb) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        print('📱 نظام Android - طلب صلاحيات التخزين');

        if (await _isAndroid13OrAbove()) {
          print('📱 Android 13+ - طلب صلاحيات الوسائط');
          return await _requestAndroid13Permissions();
        } else {
          print('📱 Android أقل من 13 - طلب صلاحيات التخزين التقليدية');
          return await _requestLegacyAndroidPermissions();
        }
      } else if (Platform.isIOS) {
        print('📱 نظام iOS - طلب صلاحيات الوصول للملفات');
        return await _requestIOSPermissions();
      } else {
        return true;
      }
    } catch (e) {
      print('❌ خطأ في منح الصلاحية: $e');
      return false;
    }
  }

  /// التحقق إذا كان الجهاز Android 13 أو أعلى
  Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      return false;
    }
  }

  /// طلب صلاحيات Android للإصدارات القديمة (قبل Android 13)
  Future<bool> _requestLegacyAndroidPermissions() async {
    try {
      final status = await ph.Permission.storage.request();
      print('📊 حالة صلاحية التخزين: ${status.toString()}');

      if (status.isGranted) {
        try {
          final manageStatus = await ph.Permission.manageExternalStorage.request();
          if (manageStatus.isGranted) {
            print('✅ حصل على صلاحية إدارة التخزين الكاملة');
          }
        } catch (e) {
          print('⚠️ لا يدعم MANAGE_EXTERNAL_STORAGE: $e');
        }
        return true;
      } else if (status.isPermanentlyDenied) {
        print('🔕 المستخدم رفض الصلاحية بشكل دائم');
        await _markPermissionAsPermanentlyDenied();
        return false;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في طلب صلاحيات Android القديمة: $e');
      return false;
    }
  }

  /// طلب صلاحيات Android 13+ (الإصدارات الحديثة)
  Future<bool> _requestAndroid13Permissions() async {
    try {
      final List<ph.Permission> permissionsToRequest = [
        ph.Permission.photos,
        ph.Permission.audio,
        ph.Permission.videos,
      ];

      bool anyGranted = false;

      for (var permission in permissionsToRequest) {
        final status = await permission.request();
        print('📊 حالة ${permission.toString()}: ${status.toString()}');

        if (status.isGranted) {
          anyGranted = true;
        }
      }

      if (!anyGranted) {
        print('🔄 محاولة طلب MANAGE_EXTERNAL_STORAGE للصلاحية الكاملة');
        final manageStatus = await ph.Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) {
          print('✅ حصل على صلاحية إدارة التخزين الكاملة');
          return true;
        }
      }

      return anyGranted;
    } catch (e) {
      print('❌ خطأ في طلب صلاحيات Android 13+: $e');
      return await _requestLegacyAndroidPermissions();
    }
  }

  /// طلب صلاحيات iOS
  Future<bool> _requestIOSPermissions() async {
    try {
      final List<ph.Permission> permissionsToRequest = [
        ph.Permission.photos,
        ph.Permission.mediaLibrary,
      ];

      bool anyGranted = false;

      for (var permission in permissionsToRequest) {
        final status = await permission.request();
        print('📊 حالة ${permission.toString()}: ${status.toString()}');

        if (status.isGranted) {
          anyGranted = true;
          break;
        }
      }

      return anyGranted;
    } catch (e) {
      print('❌ خطأ في طلب صلاحيات iOS: $e');
      return false;
    }
  }

  /// فتح إعدادات التطبيق
  void _openAppSettings() {
    if (!kIsWeb) {
      AppSettings.openAppSettings();
    }
  }

  /// ===== حفظ الحالة =====
  Future<void> _markPermissionAsRequested() async {
    await _prefs!.setBool(_permissionRequestedKey, true);
  }

  Future<void> _markPermissionAsGranted() async {
    await _prefs!.setBool(_permissionGrantedKey, true);
    await _prefs!.setBool(_permissionPermanentlyDeniedKey, false);
  }

  Future<void> _markPermissionAsPermanentlyDenied() async {
    await _prefs!.setBool(_permissionPermanentlyDeniedKey, true);
  }

  /// ===== واجهة الاستخدام البسيطة =====

  /// تهيئة الصلاحيات عند بدء التطبيق
  Future<void> initializePermissions(BuildContext context) async {
    print('🚀 === بدء تهيئة صلاحيات التخزين ===');

    await _initPrefs();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) {
      print('❌ === السياق غير جاهز ===');
      return;
    }

    print('✅ === السياق جاهز ===');

    final bool hasPermission = await checkStoragePermission();
    print('📊 === حالة الصلاحية الحقيقية: $hasPermission ===');

    final bool savedAsGranted = _prefs!.getBool(_permissionGrantedKey) ?? false;
    print('💾 === حالة الصلاحية المحفوظة: $savedAsGranted ===');

    if (hasPermission || savedAsGranted) {
      print('✅ === الصلاحية ممنوحة بالفعل ===');
      if (!savedAsGranted) {
        await _markPermissionAsGranted();
      }
      return;
    }

    print('📢 === الصلاحية غير ممنوحة، نطلبها الآن ===');

    final bool previouslyRequested = _prefs!.getBool(_permissionRequestedKey) ?? false;
    print('📝 === السجلات: requested=$previouslyRequested ===');

    if (previouslyRequested) {
      print('🔄 === سبق الطلب - عرض رسالة إقناع ===');
      await _showPersuasionDialog(context);
    } else {
      print('🆕 === أول طلب - عرض الرسالة الأساسية ===');
      await _showInitialPermissionDialog(context);
    }
  }

  /// التحقق من الصلاحية عند بدء التطبيق أو عند العودة إليه
  Future<bool> checkAndRequestPermissionIfNeeded(BuildContext context) async {
    await _initPrefs();

    final bool savedAsGranted = _prefs!.getBool(_permissionGrantedKey) ?? false;

    if (savedAsGranted) {
      print('✅ الصلاحية محفوظة كممنوحة مسبقاً');

      final bool actuallyGranted = await checkStoragePermission();
      if (actuallyGranted) {
        return true;
      } else {
        await _prefs!.remove(_permissionGrantedKey);
      }
    }

    return await requestStoragePermission(context);
  }

  /// التحقق وعرض الحوار مباشرة
  Future<void> checkAndShowPermissionDialog(BuildContext context) async {
    await _initPrefs();

    final bool savedAsGranted = _prefs!.getBool(_permissionGrantedKey) ?? false;

    if (savedAsGranted) {
      final bool actuallyGranted = await checkStoragePermission();
      if (actuallyGranted) {
        print('✅ الصلاحية ممنوحة فعلياً');
        return;
      } else {
        print('⚠️ الصلاحية محفوظة لكنها غير موجودة فعلياً');
        await _prefs!.remove(_permissionGrantedKey);
        await _prefs!.remove(_permissionRequestedKey);
        await _prefs!.remove(_permissionPermanentlyDeniedKey);
      }
    }

    final bool hasPermission = await checkStoragePermission();

    if (!hasPermission) {
      print('📢 الصلاحية غير ممنوحة، نطلبها الآن');

      final bool previouslyRequested = _prefs!.getBool(_permissionRequestedKey) ?? false;

      if (previouslyRequested) {
        print('🔄 سبق طلب الصلاحية، نعرض رسالة الإقناع');
        await _showPersuasionDialog(context);
      } else {
        print('🆕 أول طلب للصلاحية');
        await _showInitialPermissionDialog(context);
      }
    }
  }

  /// الحصول على حالة الصلاحية الحالية
  Future<PermissionStatus> getPermissionStatus() async {
    await _initPrefs();

    final bool savedAsGranted = _prefs!.getBool(_permissionGrantedKey) ?? false;
    if (savedAsGranted) return PermissionStatus.granted;

    final bool permanentlyDenied = _prefs!.getBool(_permissionPermanentlyDeniedKey) ?? false;
    if (permanentlyDenied) return PermissionStatus.permanentlyDenied;

    final bool requested = _prefs!.getBool(_permissionRequestedKey) ?? false;
    if (requested) return PermissionStatus.denied;

    return PermissionStatus.notDetermined;
  }

  /// إعادة تعيين حالة الصلاحية (للتطوير)
  Future<void> resetPermission() async {
    await _initPrefs();
    await _prefs!.remove(_permissionRequestedKey);
    await _prefs!.remove(_permissionGrantedKey);
    await _prefs!.remove(_permissionPermanentlyDeniedKey);
  }
}

/// حالة الصلاحية
enum PermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}