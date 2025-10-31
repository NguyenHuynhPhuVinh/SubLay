import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/routes/app_pages.dart';
import 'app/data/models/video_with_subtitle.dart';
import 'app/data/models/prompt_model.dart';
import 'app/data/services/video_service.dart';
import 'app/data/services/prompt_service.dart';
import 'app/data/services/app_settings_service.dart';
import 'app/core/services/subtitle_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(VideoWithSubtitleAdapter());
  Hive.registerAdapter(PromptModelAdapter());

  // Initialize services
  Get.put(VideoService(), permanent: true);
  Get.put(PromptService(), permanent: true);
  Get.put(AppSettingsService(), permanent: true);
  Get.put(SubtitleSettingsService(), permanent: true);

  runApp(const DuTupSRTApp());
}

class DuTupSRTApp extends StatelessWidget {
  const DuTupSRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'DuTupSRT',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
