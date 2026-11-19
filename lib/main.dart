import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FileDownloader().start(autoCleanDatabase: true);

  FileDownloader().configureNotification(
    running: const TaskNotification(
      'BAHMED IDM',
      'جاري تنزيل {filename}',
    ),
    complete: const TaskNotification(
      'اكتمل التنزيل',
      '{filename}',
    ),
    error: const TaskNotification(
      'تعذر التنزيل',
      '{filename}',
    ),
    progressBar: true,
    tapOpensFile: true,
  );

  runApp(const BahmedIDM());
}

class BahmedIDM extends StatelessWidget {
  const BahmedIDM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BAHMED IDM',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5FF),
      brightness: brightness,
      surface: dark ? const Color(0xFF111827) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF090E18) : const Color(0xFFF3F6FA),
      appBarTheme: AppBarTheme(
        backgroundColor:
            dark ? const Color(0xFF090E18) : Colors.white,
        foregroundColor:
            dark ? Colors.white : Colors.black87,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;

  final TextEditingController urlController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  bool adding = false;
  String? message;

  Transfers get transfers => FileDownloader().transfers;

  @override
  void dispose() {
    urlController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> addDownload() async {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      setState(() => message = 'أدخل رابط التنزيل أولاً');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        !(uri.scheme == 'https' || uri.scheme == 'http')) {
      setState(() {
        message =
            'الرابط غير صالح. استخدم رابط HTTP أو HTTPS مباشر.';
      });
      return;
    }

    setState(() {
      adding = true;
      message = null;
    });

    try {
      var filename = nameController.text.trim();

      if (filename.isEmpty) {
        filename = Uri.decodeComponent(
          uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : 'download_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (filename.isEmpty || filename == '/') {
        filename =
            'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      filename = filename.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final task = DownloadTask(
        url: uri.toString(),
        filename: filename,
        baseDirectory: BaseDirectory.applicationDocuments,
        directory: 'BAHMED_IDM',
        updates: Updates.statusAndProgress,
        allowPause: true,
        retries: 2,
      );

      await transfers.start(task);

      urlController.clear();
      nameController.clear();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        message = 'تعذر بدء التنزيل: $e';
      });
    } finally {
      if (mounted) {
        setState(() => adding = false);
      }
    }
  }

  void showAddDialog() {
    message = null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, refreshDialog) {
            return AlertDialog(
              title: const Text('إضافة تنزيل'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'رابط الملف',
                        hintText: 'https://example.com/file.zip',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الملف (اختياري)',
                        prefixIcon:
                            Icon(Icons.drive_file_rename_outline),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: adding
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: adding
                      ? null
                      : () async {
                          refreshDialog(() {});
                          await addDownload();
                          refreshDialog(() {});
                        },
                  icon: adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: const Text('ابدأ التنزيل'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _downloadsPage(),
      _aboutPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BAHMED IDM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'مدير التنزيلات',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'إضافة تنزيل',
              onPressed: showAddDialog,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        body: pages[selectedTab],
        floatingActionButton: selectedTab == 0
            ? FloatingActionButton.extended(
                onPressed: showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('تنزيل جديد'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (value) {
            setState(() => selectedTab = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.download_for_offline_outlined),
              selectedIcon: Icon(Icons.download_for_offline),
              label: 'التنزيلات',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              label: 'حول التطبيق',
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadsPage() {
    return ValueListenableBuilder<List<Transfer>>(
      valueListenable: transfers.notifier,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_download_outlined,
                    size: 76,
                    color: Color(0xFF00BCD4),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'لا توجد تنزيلات بعد',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف رابط ملف مباشر لبدء أول تنزيل.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return TransferCard(
              key: ValueKey(items[index].taskId),
              transfer: items[index],
            );
          },
        );
      },
    );
  }

  Widget _aboutPage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 64,
              color: Color(0xFF00BCD4),
            ),
            SizedBox(height: 12),
            Text(
              'BAHMED IDM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'مدير تنزيلات للروابط المباشرة عبر HTTP وHTTPS.\n'
              'قد لا تعمل روابط صفحات التواصل الاجتماعي كرابط ملف مباشر.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.transfer,
  });

  final Transfer transfer;

  String statusName(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => 'في قائمة الانتظار',
      TaskStatus.running => 'جارٍ التنزيل',
      TaskStatus.complete => 'مكتمل',
      TaskStatus.failed => 'فشل التنزيل',
      TaskStatus.canceled => 'أُلغي',
      TaskStatus.paused => 'متوقف مؤقتاً',
      TaskStatus.waitingToRetry => 'بانتظار إعادة المحاولة',
      TaskStatus.notFound => 'المهمة غير موجودة',
      _ => status.name,
    };
  }

  String speedText(double speed) {
    return speed < 0
        ? '—'
        : '${speed.toStringAsFixed(2)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Color(0xFF00BCD4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    transfer.task.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pause') {
                      await transfer.pause();
                    }

                    if (value == 'resume') {
                      await transfer.resume();
                    }

                    if (value == 'cancel') {
                      await transfer.cancel();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'pause',
                      child: Text('إيقاف مؤقت'),
                    ),
                    PopupMenuItem(
                      value: 'resume',
                      child: Text('استئناف'),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text('إلغاء التنزيل'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TaskStatus>(
              valueListenable: transfer.statusNotifier,
              builder: (context, status, _) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusName(status),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      speedText(transfer.networkSpeed),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<double?>(
              valueListenable: transfer.progressNotifier,
              builder: (context, progress, _) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        progress == null
                            ? 'جارٍ تحديد الحجم...'
                            : '${(progress * 100).toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<TaskStatus>(
              valueListenable: transfer.statusNotifier,
              builder: (context, status, _) {
                return Wrap(
                  spacing: 8,
                  children: [
                    if (status == TaskStatus.running ||
                        status == TaskStatus.enqueued)
                      TextButton.icon(
                        onPressed: () => transfer.pause(),
                        icon: const Icon(Icons.pause),
                        label: const Text('إيقاف'),
                      ),
                    if (status == TaskStatus.paused ||
                        status == TaskStatus.failed)
                      TextButton.icon(
                        onPressed: () => transfer.resume(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('استئناف'),
                      ),
                    if (!status.isFinalState ||
                        status == TaskStatus.failed)
                      TextButton.icon(
                        onPressed: () => transfer.cancel(),
                        icon: const Icon(Icons.close),
                        label: const Text('إلغاء'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF00C9A7)),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget downloadList() {
    if (downloads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_for_offline,
              size: 75,
              color: Color(0xFF00C9A7),
            ),
            SizedBox(height: 15),
            Text(
              'لا توجد تنزيلات حالياً',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final item = downloads[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Color(0xFF00C9A7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.task.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => cancelDownload(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: item.progress >= 0 ? item.progress : null,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(item.progress * 100).clamp(0, 100).toStringAsFixed(1)}%',
                    ),
                    Text(item.status.name),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => pauseDownload(item),
                      icon: const Icon(Icons.pause),
                    ),
                    IconButton(
                      onPressed: () => resumeDownload(item),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Card(
          child: SwitchListTile(
            title: const Text('الوضع الليلي'),
            subtitle: const Text('تغيير مظهر التطبيق'),
            secondary: const Icon(Icons.palette),
            value: widget.isDark,
            onChanged: (_) => widget.onThemeChanged(),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول التطبيق'),
            subtitle: Text('BAHMED IDM'),
          ),
        ),
      ],
    );
  }
}

class DownloadItem {
  final DownloadTask task;

  double progress = 0;
  TaskStatus status = TaskStatus.enqueued;

  DownloadItem({required this.task});
}
