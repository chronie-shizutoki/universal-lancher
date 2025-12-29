import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// 使用默认浏览器打开链接的页面
class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _launchUrlInBrowser();
  }

  Future<void> _launchUrlInBrowser() async {
    try {
      // 确保URL有协议前缀
      final url = widget.url.startsWith(RegExp(r'https?://')) 
        ? widget.url 
        : 'http://${widget.url}';

      final bool launched = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication, // 使用默认浏览器打开
      );

      setState(() {
        _isLoading = false;
        if (!launched) {
          _errorMessage = '无法打开链接';
        }
      });

      // 如果成功打开，延迟后自动返回上一页
      if (launched) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '打开链接时出错: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在打开链接...'),
                    ],
                  )
                : _errorMessage != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _launchUrlInBrowser,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('返回'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text('正在打开默认浏览器...'),
                          SizedBox(height: 8),
                          Text('如果浏览器未自动打开，请点击下方按钮重试'),
                          SizedBox(height: 24),
                          // 这里不显示按钮，因为会自动返回
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
