import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeBrowserController extends GetxController {
  late WebViewController webViewController;
  final isLoading = true.obs;
  final currentUrl = 'https://www.youtube.com'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            isLoading.value = true;
            currentUrl.value = url;
          },
          onPageFinished: (String url) {
            isLoading.value = false;
          },
          onWebResourceError: (WebResourceError error) {
            Get.snackbar(
              'Lỗi',
              'Không thể tải trang: ${error.description}',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.youtube.com'));
  }

  void goBack() async {
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
    }
  }

  void goForward() async {
    if (await webViewController.canGoForward()) {
      webViewController.goForward();
    }
  }

  void reload() {
    webViewController.reload();
  }

  void goHome() {
    webViewController.loadRequest(Uri.parse('https://www.youtube.com'));
  }
}
