import 'package:flutter/material.dart';
import 'package:fumeo/pages/update/github_service.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  UpdateDialogState createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _selectedDownloadUrl;
  String _currentDescription = '';
  bool _isCustomServer = false;

  @override
  void initState() {
    super.initState();
    String version = widget.updateInfo['version'] as String;
    String customUrl = 'https://cloud.xbxin.com/app/fumeo/v$version.apk';

    final List<Map<String, String>> downloadUrls = [
      ...widget.updateInfo['downloadUrls'] as List<Map<String, String>>,
      {
        'name': 'custom_arm64-v8a.apk',
        'url': customUrl,
        'isCustom': 'true',
      }
    ];

    if (downloadUrls.isNotEmpty) {
      _selectedDownloadUrl = downloadUrls.first['url'];
      _currentDescription = _getArchitectureDescription(
          downloadUrls.first['name'] ?? '',
          downloadUrls.first['isCustom'] == 'true');
      _isCustomServer = downloadUrls.first['isCustom'] == 'true';
    }
  }

  String _formatDisplayName(String fileName, bool isCustom) {
    if (isCustom) {
      return 'Android ARM64版本（自建）';
    }

    if (fileName.toLowerCase().endsWith('.apk')) {
      if (fileName.contains('arm64-v8a')) {
        return 'Android ARM64版本（GitHub）';
      } else if (fileName.contains('armeabi-v7a')) {
        return 'Android ARM32版本（GitHub）';
      } else if (fileName.contains('x86_64')) {
        return 'Android X86_64版本（GitHub）';
      } else if (fileName.contains('x86')) {
        return 'Android X86版本（GitHub）';
      } else if (fileName.contains('universal')) {
        return 'Android通用版本（GitHub）';
      } else {
        return 'Android版本（GitHub）';
      }
    } else if (fileName.toLowerCase().endsWith('.ipa')) {
      return 'iOS版本';
    }
    return fileName;
  }

  String _getArchitectureDescription(String fileName, bool isCustom) {
    if (isCustom) {
      return '自建线路，适用于搭载ARM64处理器的设备（版本可能不会及时更新）';
    }

    if (fileName.toLowerCase().endsWith('.apk')) {
      if (fileName.contains('arm64-v8a')) {
        return '适用于搭载ARM64处理器的设备（推荐）';
      } else if (fileName.contains('armeabi-v7a')) {
        return '适用于搭载ARM32处理器的设备（兼容老设备）';
      } else if (fileName.contains('x86_64')) {
        return '适用于搭载X86_64处理器的设备';
      } else if (fileName.contains('x86')) {
        return '适用于搭载X86处理器的设备';
      } else if (fileName.contains('universal')) {
        return '通用版本，支持所有架构（体积较大）';
      }
    }
    return '';
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.apk')) {
      return Icons.android;
    } else if (fileName.toLowerCase().endsWith('.ipa')) {
      return Icons.apple;
    }
    return Icons.file_present;
  }

  @override
  Widget build(BuildContext context) {
    String version = widget.updateInfo['version'] as String;
    String customUrl = 'https://cloud.xbxin.com/app/fumeo/v$version.apk';

    final List<Map<String, String>> downloadUrls = [
      ...widget.updateInfo['downloadUrls'] as List<Map<String, String>>,
      {
        'name': 'custom_arm64-v8a.apk',
        'url': customUrl,
        'isCustom': 'true',
      }
    ];

    return AlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最新版本: ${widget.updateInfo['version']}'),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: widget.updateInfo['description'],
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14),
                  h1: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  h2: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  h3: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (downloadUrls.isNotEmpty) ...[
            const Text(
              '选择下载版本',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withAlpha(75),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: _selectedDownloadUrl,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(8),
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    menuMaxHeight: 400,
                    items: downloadUrls.map((item) {
                      String fileName = item['name'] ?? '';
                      bool isCustom = item['isCustom'] == 'true';
                      String displayName =
                          _formatDisplayName(fileName, isCustom);

                      return DropdownMenuItem<String>(
                        value: item['url'],
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(fileName),
                                size: 20,
                                color: isCustom
                                    ? Colors.red
                                    : Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color:
                                        isCustom ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _downloading
                        ? null
                        : (String? newValue) {
                            final selectedItem = downloadUrls.firstWhere(
                              (item) => item['url'] == newValue,
                              orElse: () =>
                                  {'name': '', 'url': '', 'isCustom': 'false'},
                            );
                            setState(() {
                              _selectedDownloadUrl = newValue;
                              _isCustomServer =
                                  selectedItem['isCustom'] == 'true';
                              _currentDescription = _getArchitectureDescription(
                                  selectedItem['name'] ?? '',
                                  selectedItem['isCustom'] == 'true');
                            });
                          },
                  ),
                ),
              ),
            ),
            if (_currentDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _currentDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: _isCustomServer ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.withAlpha(26),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '下载进度: ${(_progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _downloading || _selectedDownloadUrl == null
              ? null
              : _startDownload,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text('更新'),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    if (_selectedDownloadUrl == null) {
      _showMessage('请选择下载地址');
      return;
    }

    if (Platform.isAndroid) {
      var status = await Permission.requestInstallPackages.status;
      if (status.isDenied) {
        status = await Permission.requestInstallPackages.request();
        if (status.isDenied) {
          _showMessage('需要安装应用权限才能更新，请在设置中开启');
          return;
        }
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
        return;
      }
    }

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath =
          '${dir.path}/update${Platform.isAndroid ? '.apk' : '.ipa'}';

      bool success = await GithubService.downloadUpdate(
        _selectedDownloadUrl!,
        savePath,
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (success) {
        if (Platform.isAndroid) {
          final result = await OpenFile.open(savePath);
          if (result.type != ResultType.done) {
            _showMessage('安装失败: ${result.message}');
          }
        } else if (Platform.isIOS) {
          _showMessage('iOS版本请通过App Store更新');
        }
      } else {
        _showMessage('下载更新失败');
      }
    } catch (e) {
      _showMessage('更新失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
