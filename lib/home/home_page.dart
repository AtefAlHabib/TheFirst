import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:the_first/home/widgets/home_content.dart';
import 'package:universal_html/html.dart' as html;
import '../app/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class MyHomePage extends StatefulWidget {
  final Function(ThemeMode) changeThemeMode;

  MyHomePage({required this.changeThemeMode});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController insertController = TextEditingController();
  final TextEditingController resultController = TextEditingController();
  final FocusNode insertFocusNode = FocusNode();

  double insertFontSize = 30.0;
  double minFontSize = 8.0;
  double maxFontSize = 30.0;

  final GlobalKey textFieldKey = GlobalKey();

  bool showAdditionalButtons = false;
  Offset additionalButtonsPosition = Offset.zero;
  String currentBaseLetter = '';

  late Debouncer debouncer;
  bool isProcessing = false;
  Map<String, double> fontSizeCache = {};

  bool isEnglishKeyboard = false;

  Timer? undoTimer;

  @override
  void initState() {
    super.initState();
    debouncer = Debouncer(
      const Duration(milliseconds: 50),
      initialValue: '',
      checkEquality: false,
    );
    debouncer.values.listen((text) {
      if (mounted) {
        performFontAdjustment(text);
      }
    });

  }




  Future<void> saveFile() async {
    try {
      print('=== بدء عملية الحفظ ===');

      if (kIsWeb) {
        await _saveFileForWeb();
        return;
      }

      // إنشاء المجلد والملف
      final bool success = await _createFolderAndFile();

      if (success) {
        // التحقق من إنشاء الملف
        await _verifyFileCreated();
        _showSuccessMessage();
      } else {
        _showErrorMessage();
      }
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
      _showErrorMessage();
    }
  }





  Future<bool> _checkActualWritePermission() async {
    try {
      // محاولة كتابة ملف تجريبي للتأكد من الصلاحية
      if (Platform.isAndroid) {
        final testDir = Directory('/storage/emulated/0/Download/test_permission');
        if (!await testDir.exists()) {
          await testDir.create(recursive: true);
        }

        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('test', flush: true);
        final canRead = await testFile.readAsString();

        // تنظيف
        await testFile.delete();
        await testDir.delete();

        print('✅ يمكن الكتابة والقراءة في التخزين');
        return true;
      }
      return true;
    } catch (e) {
      print('❌ لا يمكن الكتابة في التخزين: $e');
      return false;
    }
  }





  Future<bool> _checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        print('📱 التحقق من صلاحية التخزين في Android');

        // طريقة 1: التحقق من صلاحية التخزين المباشرة
        final storageStatus = await Permission.storage.status;
        print('📊 حالة صلاحية storage: $storageStatus');

        if (storageStatus.isGranted) {
          return true;
        }

        // طريقة 2: لمزيد من التأكيد، نطلب الصلاحية
        final photosStatus = await Permission.photos.status;
        print('📊 حالة صلاحية photos: $photosStatus');

        if (photosStatus.isGranted) {
          return true;
        }

        // طريقة 3: طلب الصلاحية
        final requestResult = await [
          Permission.storage,
          Permission.photos,
        ].request();

        print('📊 نتيجة طلب الصلاحيات: $requestResult');

        return requestResult[Permission.storage]?.isGranted == true ||
            requestResult[Permission.photos]?.isGranted == true;
      }
      else if (Platform.isIOS) {
        print('📱 التحقق من صلاحية التخزين في iOS');
        final status = await Permission.photos.status;
        print('📊 حالة الصلاحية في iOS: $status');

        if (!status.isGranted) {
          final result = await Permission.photos.request();
          print('📊 نتيجة طلب الصلاحية في iOS: $result');
          return result.isGranted;
        }
        return true;
      }

      // للمنصات الأخرى (ويب، سطح المكتب)
      return true;
    } catch (e) {
      print('❌ خطأ في التحقق من الصلاحية: $e');
      return false;
    }
  }

  void _showPermissionError() {
    final message = Platform.isAndroid
        ? '❌ لا توجد صلاحية لتخزين الملفات\nيرجى منح صلاحية "التخزين" في إعدادات التطبيق'
        : '❌ لا توجد صلاحية لتخزين الملفات';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }


  /// دالة ترجع مسار: Android/media/com.your.package.name
  Future<Directory> getAppMediaDirectory() async {
    // الحصول على مسار الذاكرة الخارجية الرئيسية
    final Directory? externalStorageDir = await getExternalStorageDirectory();

    if (externalStorageDir == null) {
      throw Exception("لا يمكن الوصول إلى التخزين الخارجي");
    }

    // package name يكون جزءاً من المسار الذي يُرجعه getExternalStorageDirectory
    // مثال: /storage/emulated/0/Android/data/com.example.yourapp/files
    final String packageName = externalStorageDir.path.split('/Android/data/').last;

    // بناء المسار الجديد المطلوب
    final String mediaPath = '/storage/emulated/0/Android/media/$packageName';

    final Directory mediaDirectory = Directory(mediaPath);

    // إنشاء المجلد إذا لم يكن موجوداً
    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }

    return mediaDirectory;
  }

  Future<bool> _createFolderAndFile() async {
    try {
      Directory directory;
      String platformInfo = '';

      if (Platform.isAndroid) {
        platformInfo = 'Android';
        // محاولة مسارات متعددة للأندرويد
        directory = await getAppMediaDirectory();
        print('🤖 نظام Android - المسار المختار: ${directory.path}');
      } else if (Platform.isIOS) {
        platformInfo = 'iOS';
        final docsDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docsDir.path}/first');
        print('🍎 نظام iOS - المسار: ${directory.path}');
      } else {
        platformInfo = 'Desktop/Other';
        final docsDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docsDir.path}/first');
        print('💻 نظام $platformInfo - المسار: ${directory.path}');
      }

      // التحقق من وجود المجلد
      final dirExists = await directory.exists();
      print('📁 هل المجلد موجود؟ $dirExists');

      // إنشاء المجلد إذا لم يكن موجوداً
      if (!dirExists) {
        try {
          await directory.create(recursive: true);
          print('✅ تم إنشاء المجلد: ${directory.path}');
        } catch (e) {
          print('❌ فشل إنشاء المجلد: $e');
          // محاولة مسار بديل
          return await _tryAlternativePath();
        }
      } else {
        print('✅ المجلد موجود مسبقاً');
      }

      // إنشاء الملف النصي
      final file = File('${directory.path}/main.txt');
      print('📄 محاولة إنشاء/كتابة الملف: ${file.path}');

      try {
        // التحقق إذا الملف موجود
        final fileExists = await file.exists();
        print('📄 هل الملف موجود؟ $fileExists');

        if (fileExists) {
          // محاولة حذف الملف القديم أولاً
          try {
            await file.delete();
            print('🗑️ تم حذف الملف القديم');
          } catch (e) {
            print('⚠️ لم أستطع حذف الملف القديم: $e');
          }
        }

        // كتابة الملف الجديد
        await file.writeAsString('النجاح', flush: true);
        print('✅ تم كتابة الملف بنجاح');

        // قراءة للتأكد
        final content = await file.readAsString();
        print('📖 محتوى الملف: "$content"');
        print('📏 حجم الملف: ${await file.length()} bytes');

        // عرض المسار الكامل للمستخدم
        print('📍 المسار الكامل: ${file.absolute.path}');

        return true;
      } catch (e) {
        print('❌ فشل إنشاء/كتابة الملف: $e');
        print('📌 تفاصيل الخطأ: ${e.toString()}');

        // محاولة طريقة بديلة للكتابة
        return await _tryAlternativeWriteMethod(directory);
      }
    } catch (e) {
      print('❌ خطأ عام في إنشاء المجلد والملف: $e');
      return false;
    }
  }

  Future<Directory> _getAndroidDownloadDirectory() async {
    // محاولة مسارات متعددة للأندرويد
    final List<String> possiblePaths = [
      '/storage/emulated/0/Download/first',
      '/sdcard/Download/first',
      '/storage/sdcard0/Download/first',
    ];

    for (var path in possiblePaths) {
      final dir = Directory(path);
      try {
        // التحقق إذا يمكن الوصول إلى المسار
        if (await dir.exists() || await _canAccessPath(path)) {
          print('✅ مسار قابل للوصول: $path');
          return dir;
        }
      } catch (e) {
        print('⚠️ لا يمكن الوصول إلى $path: $e');
      }
    }

    // إذا فشلت جميع المسارات، استخدام مسار التطبيق
    try {
      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        return Directory('${appDir.path}/first');
      }
    } catch (e) {
      print('⚠️ فشل الحصول على مسار التخزين الخارجي: $e');
    }

    // استخدام مسار التطبيق الداخلي
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/first');
  }

  Future<bool> _canAccessPath(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // محاولة كتابة ملف تجريبي
      final testFile = File('$path/test_access.txt');
      await testFile.writeAsString('test', flush: true);
      await testFile.delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _tryAlternativePath() async {
    print('🔄 محاولة مسار بديل...');
    try {
      // استخدام مسار التطبيق الداخلي
      final appDir = await getApplicationDocumentsDirectory();
      final alternativeDir = Directory('${appDir.path}/first');

      if (!await alternativeDir.exists()) {
        await alternativeDir.create(recursive: true);
      }

      final file = File('${alternativeDir.path}/main.txt');
      await file.writeAsString('النجاح', flush: true);

      print('✅ نجاح في المسار البديل: ${file.path}');
      return true;
    } catch (e) {
      print('❌ فشل المسار البديل: $e');
      return false;
    }
  }

  Future<bool> _tryAlternativeWriteMethod(Directory directory) async {
    print('🔄 محاولة طريقة كتابة بديلة...');
    try {
      final file = File('${directory.path}/main.txt');

      // طريقة 1: استخدام sink
      final sink = file.openWrite();
      sink.write('النجاح');
      await sink.flush();
      await sink.close();

      print('✅ نجاح بالطريقة البديلة 1');
      return true;
    } catch (e) {
      print('⚠️ فشل الطريقة البديلة 1: $e');

      // طريقة 2: استخدام FileMode.write
      try {
        final file = File('${directory.path}/main.txt');
        final raf = await file.open(mode: FileMode.write);
        await raf.writeString('النجاح');
        await raf.close();

        print('✅ نجاح بالطريقة البديلة 2');
        return true;
      } catch (e2) {
        print('⚠️ فشل الطريقة البديلة 2: $e2');
        return false;
      }
    }
  }




  void _showSuccessMessage() async {
    String filePath = '';

    if (Platform.isAndroid) {
      try {
        final file = File('/storage/emulated/0/Download/first/main.txt');
        if (await file.exists()) {
          filePath = '/storage/emulated/0/Download/first/main.txt';
        } else {
          // محاولة إيجاد المسار الفعلي
          final appDir = await getApplicationDocumentsDirectory();
          final testFile = File('${appDir.path}/first/main.txt');
          if (await testFile.exists()) {
            filePath = '${appDir.path}/first/main.txt';
          }
        }
      } catch (e) {
        print('❌ خطأ في الحصول على المسار: $e');
      }
    }

    final message = filePath.isNotEmpty
        ? '✅ تم الحفظ بنجاح\nالملف: $filePath'
        : '✅ تم الحفظ بنجاح\nالملف: main.txt في مجلد first';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }


  Future<void> _verifyFileCreated() async {
    if (Platform.isAndroid) {
      final pathsToCheck = [
        '/storage/emulated/0/Download/first/main.txt',
        '/sdcard/Download/first/main.txt',
      ];

      for (var path in pathsToCheck) {
        final file = File(path);
        if (await file.exists()) {
          print('✅ الملف موجود فعلاً في: $path');
          final content = await file.readAsString();
          print('✅ محتوى الملف: $content');
          break;
        }
      }
    }
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ فشل في الحفظ'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

// للويب - تحتاج إلى إضافة حزمة file_picker
  Future<void> _saveFileForWeb() async {
    // هذه دالة بدائية، ستحتاج لاستخدام file_picker أو مكتبة مشابهة
    // يمكنك استخدام هذه المكتبة: file_picker
    // إضافة إلى pubspec.yaml: file_picker: ^5.2.5

    print('🌐 نظام الويب - تحتاج إلى تنفيذ اختيار الملف');

    // مثال باستخدام file_picker (يجب تثبيت الحزمة أولاً)
    /*
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      // هنا يمكنك حفظ الملف
      // لكن للويب عادةً تحتاج إلى تنزيل الملف
      _downloadFileForWeb();
    }
  } catch (e) {
    print('❌ خطأ في اختيار الملف للويب: $e');
  }
  */

    // بديل: تنزيل الملف مباشرة للويب
    _downloadFileForWeb();
  }

  void _downloadFileForWeb() {
    // تنزيل الملف مباشرة للويب
    final content = 'النجاح';
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'main.txt')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تنزيل الملف main.txt'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }















  // دالة الحفظ الأساسية

  // دالة طلب الصلاحية منفصلة

  int calculateTotalValue(String text) {
    int total = 0;
    for (var char in text.runes) {
      String charStr = String.fromCharCode(char);
      total += AppConstants.letterValues[charStr] ?? 0;
    }
    return total;
  }

  void adjustFontSize() {
    if (!mounted || isProcessing) return;
    final text = insertController.text;
    debouncer.setValue(text);
  }

  void performFontAdjustment(String text) {
    if (!mounted || isProcessing) return;
    isProcessing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        isProcessing = false;
        return;
      }
      if (text.isEmpty) {
        if (insertFontSize != maxFontSize) {
          setState(() {
            insertFontSize = maxFontSize;
          });
        }
        isProcessing = false;
        return;
      }
      final context = textFieldKey.currentContext;
      if (context == null) {
        isProcessing = false;
        return;
      }
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        isProcessing = false;
        return;
      }
      final textFieldWidth = renderBox.size.width - 10;
      final textFieldHeight = renderBox.size.height - 40;
      double newSize = calculateOptimalFontSizeCached(
        text,
        textFieldWidth,
        textFieldHeight,
        minFontSize,
        maxFontSize,
      );
      if ((newSize - insertFontSize).abs() > 0.5) {
        setState(() {
          insertFontSize = newSize;
        });
      }
      isProcessing = false;
    });
  }

  double calculateOptimalFontSizeCached(
      String text,
      double maxWidth,
      double maxHeight,
      double minSize,
      double maxSize,
      ) {
    String cacheKey = '${text.length}${maxWidth.toInt()}${maxHeight.toInt()}';
    if (fontSizeCache.containsKey(cacheKey)) {
      return fontSizeCache[cacheKey]!;
    }
    double size = findOptimalFontSize(text, maxWidth, maxHeight, minSize, maxSize);
    fontSizeCache[cacheKey] = size;
    if (fontSizeCache.length > 50) {
      fontSizeCache.remove(fontSizeCache.keys.first);
    }
    return size;
  }

  double findOptimalFontSize(
      String text,
      double maxWidth,
      double maxHeight,
      double minSize,
      double maxSize,
      ) {
    double low = minSize;
    double high = maxSize;
    double optimalSize = maxSize;
    while (high - low > 0.5) {
      double mid = (low + high) / 2;
      if (doesTextFit(text, mid, maxWidth, maxHeight)) {
        optimalSize = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    if (!doesTextFit(text, optimalSize, maxWidth, maxHeight)) {
      optimalSize = findFittingSizeByReduction(text, maxWidth, maxHeight, minSize, optimalSize);
    }
    return optimalSize.clamp(minSize, maxSize);
  }

  bool doesTextFit(String text, double fontSize, double maxWidth, double maxHeight) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: AppConstants.appFontFamily,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      maxLines: null,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.height <= maxHeight;
  }

  double findFittingSizeByReduction(
      String text,
      double maxWidth,
      double maxHeight,
      double minSize,
      double startSize,
      ) {
    double currentSize = startSize;
    while (currentSize > minSize && !doesTextFit(text, currentSize, maxWidth, maxHeight)) {
      currentSize -= 1.0;
    }
    return currentSize.clamp(minSize, startSize);
  }

  void addLetter(String letter) {
    if (isProcessing) return;
    HapticFeedback.lightImpact();
    setState(() {
      final text = insertController.text;
      final selection = insertController.selection;
      int insertPos = selection.baseOffset;
      if (insertPos < 0) insertPos = text.length;
      final newText = text.substring(0, insertPos) + letter + text.substring(insertPos);
      insertController.text = newText;
      insertController.selection = TextSelection.fromPosition(
        TextPosition(offset: insertPos + letter.length),
      );
      int currentTotal = calculateTotalValue(newText);
      resultController.text = currentTotal.toString();
      adjustFontSize();
    });
  }

  void addSpace() {
    if (isProcessing) return;
    HapticFeedback.lightImpact();
    setState(() {
      final text = insertController.text;
      final selection = insertController.selection;
      int insertPos = selection.baseOffset;
      if (insertPos < 0) insertPos = text.length;
      final newText = text.substring(0, insertPos) + ' ' + text.substring(insertPos);
      insertController.text = newText;
      insertController.selection = TextSelection.fromPosition(
        TextPosition(offset: insertPos + 1),
      );
      adjustFontSize();
    });
  }

  void clearAll() {
    HapticFeedback.lightImpact();
    insertFocusNode.unfocus();

    setState(() {
      insertController.clear();
      resultController.clear();
      insertController.selection = TextSelection.collapsed(offset: 0);
      insertFontSize = maxFontSize;
      fontSizeCache.clear();
    });
  }

  void undo() {
    if (insertController.text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      final text = insertController.text;
      final selection = insertController.selection;
      int deletePos = selection.baseOffset;
      if (deletePos <= 0) {
        return;
      }
      deletePos--;
      final newText = text.substring(0, deletePos) + text.substring(deletePos + 1);
      insertController.text = newText;
      insertController.selection = TextSelection.collapsed(offset: deletePos);
      int currentTotal = calculateTotalValue(newText);
      resultController.text = currentTotal.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          performFontAdjustment(newText);
        }
      });
    });
  }

  void startContinuousUndo() {
    undoTimer?.cancel();
    undoTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (insertController.text.isEmpty ||
          (insertController.selection.baseOffset <= 0)) {
        timer.cancel();
        return;
      }
      undo();
    });
  }

  void stopContinuousUndo() {
    undoTimer?.cancel();
    undoTimer = null;
  }

  void switchToEnglishKeyboard() {
    HapticFeedback.mediumImpact();
    setState(() {
      isEnglishKeyboard = true;
      showAdditionalButtons = false;
    });
  }

  void switchToArabicKeyboard() {
    HapticFeedback.mediumImpact();
    setState(() {
      isEnglishKeyboard = false;
      showAdditionalButtons = false;
    });
  }

  void showAlifVariations(String baseLetter, GlobalKey buttonKey, double screenWidth) {
    if (isEnglishKeyboard) return;
    final RenderBox renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    int buttonsPerRow = 4;
    double buttonWidth = 56;
    double padding = 8;
    double totalWidth = (buttonsPerRow * buttonWidth) + (2 * padding);
    double leftPosition = position.dx + (buttonSize.width / 2) - (totalWidth / 2);
    if (leftPosition < 10) {
      leftPosition = 10;
    }
    if (leftPosition + totalWidth > screenWidth) {
      leftPosition = screenWidth - totalWidth - 10;
    }
    double topPosition = position.dy - 130;
    setState(() {
      showAdditionalButtons = true;
      additionalButtonsPosition = Offset(leftPosition, topPosition);
      currentBaseLetter = baseLetter;
    });
  }

  void showHaVariations(String baseLetter, GlobalKey buttonKey, double screenWidth) {
    if (isEnglishKeyboard) return;
    final RenderBox renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    double buttonWidth = 56;
    double padding = 8;
    double totalWidth = buttonWidth + (2 * padding);
    double leftPosition = position.dx + (buttonSize.width / 2) - (totalWidth / 2);
    if (leftPosition < 10) {
      leftPosition = 10;
    }
    if (leftPosition + totalWidth > screenWidth) {
      leftPosition = screenWidth - totalWidth - 10;
    }
    double topPosition = position.dy - 80;
    setState(() {
      showAdditionalButtons = true;
      additionalButtonsPosition = Offset(leftPosition, topPosition);
      currentBaseLetter = baseLetter;
    });
  }

  void hideAdditionalButtons() {
    setState(() {
      showAdditionalButtons = false;
    });
  }

  void addLetterFromVariation(String letter) {
    addLetter(letter);
    hideAdditionalButtons();
  }

  Widget buildAdditionalButton(BuildContext context, String letter, int index) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => addLetterFromVariation(letter),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Color(0xFF5C5470)
                  : Color(0xFFD9EAFD),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFFFAF0E6)
                    : Color(0xFF26282D),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.appFontFamily,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFFFAF0E6)
                      : Color(0xFF3E4246),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debouncer.cancel();
    undoTimer?.cancel();
    insertController.dispose();
    resultController.dispose();
    insertFocusNode.dispose();
    super.dispose();
  }

  double calculateFontSize(BuildContext context, double height) {
    final screenSize = MediaQuery.of(context).size;
    final shortestSide = screenSize.shortestSide;
    double baseSize = shortestSide * 0.09;
    if (shortestSide < 600) {
      return baseSize.clamp(16, 22);
    } else if (shortestSide < 900) {
      return baseSize.clamp(18, 26);
    } else {
      return baseSize.clamp(20, 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeContent(
      state: this,
      context: context,
    );
  }
}