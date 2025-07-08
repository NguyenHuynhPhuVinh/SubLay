import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';

import 'app/routes/app_pages.dart';
import 'app/data/models/video_with_subtitle.dart';
import 'app/data/models/prompt_model.dart';
import 'app/data/services/video_history_service.dart';
import 'app/data/services/prompt_service.dart';
import 'app/core/utils/responsive_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(VideoWithSubtitleAdapter());
  Hive.registerAdapter(PromptModelAdapter());

  // Initialize services
  Get.put(VideoHistoryService(), permanent: true);
  Get.put(PromptService(), permanent: true);

  runApp(const DuTupSRTApp());
}

class DuTupSRTApp extends StatelessWidget {
  const DuTupSRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: _getDesignSize(constraints.maxWidth),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return GetMaterialApp(
              title: 'DuTupSRT',
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              initialRoute: AppPages.INITIAL,
              getPages: AppPages.routes,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }

  Size _getDesignSize(double screenWidth) {
    if (screenWidth >= ResponsiveHelper.desktopBreakpoint) {
      // Desktop: giảm design size để UI lớn hơn
      return const Size(1200, 800); // Giảm từ 1600 xuống 1200 để UI lớn hơn
    } else if (screenWidth >= ResponsiveHelper.tabletBreakpoint) {
      // Tablet: design size trung bình
      return const Size(768, 1024);
    }
    // Mobile: design size nhỏ
    return const Size(375, 812);
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      // Thêm theme cho desktop
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      // Thêm theme cho desktop
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}


