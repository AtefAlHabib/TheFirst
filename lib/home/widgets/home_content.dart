import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../home_page.dart';

class HomeContent extends StatelessWidget {
  final MyHomePageState state;
  final BuildContext context;

  const HomeContent({
    required this.state,
    required this.context,
  });

  double calculateFontSize(double height) {
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
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingValue),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final buttonHeight = availableHeight * 0.1;
                    final textFieldHeight = availableHeight * 0.19;
                    final double buttonFontSize = calculateFontSize(buttonHeight);
                    final double textFieldFontSize = buttonFontSize * 1.1;

                    final Map<String, GlobalKey> letterKeys = {
                      'ا': GlobalKey(),
                      'هـ': GlobalKey(),
                    };

                    return Column(
                      children: [
                        Stack(
                          children: [
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(AppConstants.paddingValue),
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Column(
                                        children: [
                                          SizedBox(
                                            height: buttonHeight,
                                            child: Row(
                                              children: List.generate(2, (index) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                                  child: SizedBox(
                                                    height: buttonHeight,
                                                    child: ElevatedButton(
                                                      onPressed: () {},
                                                      style: ElevatedButton.styleFrom(
                                                        padding: EdgeInsets.zero,
                                                        textStyle: TextStyle(
                                                          fontSize: buttonFontSize,
                                                          fontFamily: AppConstants.appFontFamily,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            child: Text(
                                                              index == 0 ? 'الكلمات' : 'الأرقام',
                                                              textAlign: TextAlign.center,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () {
                                  final brightness = MediaQuery.of(context).platformBrightness;
                                  final currentThemeMode = Theme.of(context).brightness == Brightness.dark
                                      ? ThemeMode.dark
                                      : ThemeMode.light;
                                  ThemeMode newMode = currentThemeMode == ThemeMode.light
                                      ? ThemeMode.dark
                                      : ThemeMode.light;
                                  state.widget.changeThemeMode(newMode);
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF8D77AB),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: textFieldHeight,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: Container(
                                    height: textFieldHeight,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white54
                                              : Colors.black54
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Builder(
                                        key: state.textFieldKey,
                                        builder: (context) {
                                          return Container(
                                            alignment: Alignment.center,
                                            child: TextField(
                                              controller: state.insertController,
                                              focusNode: state.insertFocusNode,
                                              maxLines: null,
                                              textAlign: TextAlign.center,
                                              showCursor: true,
                                              readOnly: true,
                                              style: TextStyle(
                                                fontSize: state.insertFontSize,
                                                fontFamily: AppConstants.appFontFamily,
                                                fontWeight: FontWeight.bold,
                                                height: 1.3,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'أدخل الكلمة',
                                                border: InputBorder.none,
                                                hintStyle: TextStyle(
                                                  fontSize: textFieldFontSize,
                                                  fontFamily: AppConstants.appFontFamily,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.3,
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                                focusedBorder: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                disabledBorder: InputBorder.none,
                                                errorBorder: InputBorder.none,
                                                focusedErrorBorder: InputBorder.none,
                                                fillColor: Colors.transparent,
                                                filled: true,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: Container(
                                    height: textFieldHeight,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white54
                                              : Colors.black54
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Center(
                                        child: TextField(
                                          controller: state.resultController,
                                          textAlign: TextAlign.center,
                                          readOnly: true,
                                          enableInteractiveSelection: false,
                                          showCursor: false,
                                          style: TextStyle(
                                            fontSize: textFieldFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(
                                              fontSize: textFieldFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            fillColor: Colors.transparent,
                                            filled: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: buttonHeight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: SizedBox(
                                    height: buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: state.clearAll,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        textStyle: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontFamily: AppConstants.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('مسح'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: SizedBox(
                                    height: buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: () => state.saveFile(),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        textStyle: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontFamily: AppConstants.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('حفظ'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: SizedBox(
                                    height: buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        textStyle: TextStyle(
                                          fontSize: buttonFontSize,
                                          fontFamily: AppConstants.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('السجل'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppConstants.paddingValue),
                                  child: GestureDetector(
                                    onLongPress: state.startContinuousUndo,
                                    onLongPressEnd: (details) => state.stopContinuousUndo(),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: state.undo,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                'تراجع',
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!state.isEnglishKeyboard) ...[
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        final screenWidth = MediaQuery.of(context).size.width;
                                        state.showAlifVariations('ا', letterKeys['ا']!, screenWidth);
                                      },
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          key: letterKeys['ا'],
                                          onPressed: () => state.addLetter('ا'),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('ا'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('ب'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('ب'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('ج'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('ج'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('د'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('د'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        final screenWidth = MediaQuery.of(context).size.width;
                                        state.showHaVariations('هـ', letterKeys['هـ']!, screenWidth);
                                      },
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          key: letterKeys['هـ'],
                                          onPressed: () => state.addLetter('هـ'),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('هـ'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (var letters in [
                            ['و', 'ز', 'ح', 'ط', 'ي'],
                            ['ك', 'ل', 'م', 'ن', 'س'],
                            ['ع', 'ف', 'ص', 'ق', 'ر'],
                            ['ش', 'ت', 'ث', 'خ', 'ذ'],
                          ])
                            SizedBox(
                              height: buttonHeight,
                              child: Row(
                                children: letters.map((letter) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter(letter),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(letter),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('ض'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('ض'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('ظ'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('ظ'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('غ'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('غ'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onHorizontalDragEnd: (details) {
                                      if (details.primaryVelocity! > 0) {
                                        state.switchToEnglishKeyboard();
                                      } else if (details.primaryVelocity! < 0) {
                                        state.switchToArabicKeyboard();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: state.addSpace,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('عربي'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                for (int i = 0; i < 5; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: () => state.addLetter(AppConstants.englishLetters[i]),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(AppConstants.englishLetters[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                for (int i = 5; i < 10; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: () => state.addLetter(AppConstants.englishLetters[i]),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(AppConstants.englishLetters[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                for (int i = 10; i < 15; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: () => state.addLetter(AppConstants.englishLetters[i]),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(AppConstants.englishLetters[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                for (int i = 15; i < 20; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: () => state.addLetter(AppConstants.englishLetters[i]),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(AppConstants.englishLetters[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                for (int i = 20; i < 25; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: () => state.addLetter(AppConstants.englishLetters[i]),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(AppConstants.englishLetters[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: buttonHeight,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppConstants.paddingValue),
                                    child: SizedBox(
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: () => state.addLetter('Z'),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          textStyle: TextStyle(
                                            fontSize: buttonFontSize,
                                            fontFamily: AppConstants.appFontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('Z'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onHorizontalDragEnd: (details) {
                                      if (details.primaryVelocity! > 0) {
                                        state.switchToEnglishKeyboard();
                                      } else if (details.primaryVelocity! < 0) {
                                        state.switchToArabicKeyboard();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingValue),
                                      child: SizedBox(
                                        height: buttonHeight,
                                        child: ElevatedButton(
                                          onPressed: state.addSpace,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            textStyle: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontFamily: AppConstants.appFontFamily,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('English'),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Expanded(child: Container()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (state.showAdditionalButtons && !state.isEnglishKeyboard)
            GestureDetector(
              onTap: state.hideAdditionalButtons,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          if (state.showAdditionalButtons && !state.isEnglishKeyboard && state.currentBaseLetter == 'ا')
            Positioned(
              top: state.additionalButtonsPosition.dy,
              left: state.additionalButtonsPosition.dx,
              child: Container(
                width: 248,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF26282D)
                      : Color(0xFF9AA6B2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: state.buildAdditionalButton(context, 'آ', 0)),
                          Expanded(child: state.buildAdditionalButton(context, 'إ', 1)),
                          Expanded(child: state.buildAdditionalButton(context, 'أ', 2)),
                          Expanded(child: state.buildAdditionalButton(context, 'ا', 3)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: state.buildAdditionalButton(context, 'ء', 4)),
                          Expanded(child: state.buildAdditionalButton(context, 'ؤ', 5)),
                          Expanded(child: state.buildAdditionalButton(context, 'ئ', 6)),
                          Expanded(child: state.buildAdditionalButton(context, 'ى', 7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.showAdditionalButtons && !state.isEnglishKeyboard && state.currentBaseLetter == 'هـ')
            Positioned(
              top: state.additionalButtonsPosition.dy,
              left: state.additionalButtonsPosition.dx,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF26282D)
                      : Color(0xFF212325),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: state.buildAdditionalButton(context, 'ة', 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}