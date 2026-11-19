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
      'فشل التنزيل',
      '{filename}',
    ),
    progressBar: true,
    tapOpensFile: true,
  );

  await FileDownloader().transfers.rehydrateFromDatabase();

  runApp(const BahmedIDM());
}

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }
}

final appSettings = AppSettings();

class BahmedIDM extends StatelessWidget {
  const BahmedIDM({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BAHMED IDM',
          themeMode: appSettings.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const HomePage(),
        );
      },
    );
  }

  ThemeData buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D9FF),
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          dark ? const Color(0xFF080D18) : const Color(0xFFF2F5FA),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF121B2B) : Colors.white,
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
  int pageIndex = 0;

  final urlController = TextEditingController();
  final nameController = TextEditingController();

  bool isAdding = false;
  String? errorMessage;

  Transfers get transfers => FileDownloader().transfers;

  @override
  void dispose() {
    urlController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> addDownload() async {
    final rawUrl = urlController.text.trim();
    final uri = Uri.tryParse(rawUrl);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      setState(() {
        errorMessage = 'أدخل رابط HTTP أو HTTPS صحيحاً';
      });
      return;
    }

    setState(() {
      isAdding = true;
      errorMessage = null;
    });

    try {
      var filename = nameController.text.trim();

      if (filename.isEmpty) {
        filename = uri.pathSegments.isNotEmpty
            ? Uri.decodeComponent(uri.pathSegments.last)
            : 'download_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (filename.isEmpty) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
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
        allowPause: true,
        retries: 2,
        transferHints: {
          TransferHint.userInitiated,
          TransferHint.largeFile,
        },
      );

      await transfers.start(task);

      urlController.clear();
      nameController.clear();

      if (mounted) {
        Navigator.pop(context);
        setState(() => pageIndex = 1);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'تعذر بدء التنزيل: $e';
      });
    } finally {
      if (mounted) {
        setState(() => isAdding = false);
      }
    }
  }

  void showAddDialog() {
    errorMessage = null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, refresh) {
            return AlertDialog(
              title: const Text('تنزيل جديد'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'رابط الملف',
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://example.com/file.zip',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الملف',
                        prefixIcon: Icon(Icons.drive_file_rename_outline),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: isAdding
                      ? null
                      : () async {
                          refresh(() {});
                          await addDownload();
                          refresh(() {});
                        },
                  icon: const Icon(Icons.download),
                  label: const Text('ابدأ'),
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
      dashboardPage(),
      downloadsPage(),
      filesPage(),
      settingsPage(),
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
                'ADVANCED DOWNLOAD MANAGER',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: showAddDialog,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'إضافة تنزيل',
            ),
          ],
        ),
        body: pages[pageIndex],
        floatingActionButton: pageIndex == 1
            ? FloatingActionButton.extended(
                onPressed: showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('تنزيل جديد'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: pageIndex,
          onDestinationSelected: (value) {
            setState(() => pageIndex = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'التنزيلات',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'الملفات',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardPage() {
    return ValueListenableBuilder<List<Transfer>>(
      valueListenable: transfers.notifier,
      builder: (context, items, _) {
        final active = items.where((item) {
          return item.status == TaskStatus.running ||
              item.status == TaskStatus.enqueued ||
              item.status == TaskStatus.paused;
        }).length;

        final completed = items
            .where((item) => item.status == TaskStatus.complete)
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF063A60),
                    Color(0xFF007EAA),
                    Color(0xFF00C9E8),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 38),
                  SizedBox(height: 12),
                  Text(
                    'BAHMED IDM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'تحكم كامل في تنزيلاتك',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: statisticCard(
                    'التنزيلات',
                    '${items.length}',
                    Icons.download,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: statisticCard(
                    'النشطة',
                    '$active',
                    Icons.sync,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: statisticCard(
                    'المكتملة',
                    '$completed',
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'أحدث التنزيلات',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('لا توجد تنزيلات حتى الآن'),
                ),
              )
            else
              ...items.take(3).map(
                    (item) => TransferCard(transfer: item),
                  ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة تنزيل جديد'),
            ),
          ],
        );
      },
    );
  }

  Widget statisticCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget downloadsPage() {
    return ValueListenableBuilder<List<Transfer>>(
      valueListenable: transfers.notifier,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  size: 75,
                  color: Color(0xFF00BCD4),
                ),
                SizedBox(height: 12),
                Text('قائمة التنزيلات فارغة'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return TransferCard(transfer: items[index]);
          },
        );
      },
    );
  }

  Widget filesPage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 70, color: Color(0xFF00BCD4)),
            SizedBox(height: 15),
            Text(
              'مجلد الملفات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'تُحفظ الملفات داخل مجلد التطبيق الخاص حالياً. '
              'سيُضاف متصفح الملفات ونقل الملفات إلى مجلد التنزيلات العام '
              'بعد تجهيز صلاحيات Android.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('الوضع الليلي'),
            subtitle: const Text('التبديل بين المظهر الداكن والفاتح'),
            value: appSettings.themeMode == ThemeMode.dark,
            onChanged: (_) => appSettings.toggleTheme(),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.language),
            title: Text('لغة التطبيق'),
            subtitle: Text('العربية'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('BAHMED IDM'),
            subtitle: Text('مدير التنزيلات'),
          ),
        ),
      ],
    );
  }
}

class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.transfer,
  });

  final Transfer transfer;

  String statusText(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => 'في قائمة الانتظار',
      TaskStatus.running => 'جارٍ التنزيل',
      TaskStatus.complete => 'اكتمل التنزيل',
      TaskStatus.failed => 'فشل التنزيل',
      TaskStatus.canceled => 'تم الإلغاء',
      TaskStatus.paused => 'متوقف مؤقتاً',
      TaskStatus.waitingToRetry => 'إعادة المحاولة',
      TaskStatus.notFound => 'المهمة غير موجودة',
      _ => status.name,
    };
  }

  String formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'غير معروف';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    }

    if (minutes > 0) {
      return '${minutes}د ${seconds}ث';
    }

    return '${seconds}ث';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pause') await transfer.pause();
                    if (value == 'resume') await transfer.resume();
                    if (value == 'cancel') await transfer.cancel();
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
                      child: Text('إلغاء'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TaskStatus>(
              valueListenable: transfer.statusNotifier,
              builder: (context, status, _) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    statusText(status),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        progress == null
                            ? 'يتم تحديد التقدم'
                            : '${(progress * 100).toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: transfer.networkSpeedNotifier,
              builder: (context, speed, _) {
                return Row(
                  children: [
                    const Icon(Icons.speed, size: 17),
                    const SizedBox(width: 5),
                    Text(
                      speed < 0
                          ? 'السرعة: —'
                          : 'السرعة: ${speed.toStringAsFixed(2)} MB/s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    const Icon(Icons.timer_outlined, size: 17),
                    const SizedBox(width: 5),
                    ValueListenableBuilder<Duration>(
                      valueListenable: transfer.timeRemainingNotifier,
                      builder: (context, duration, _) {
                        return Text(
                          formatDuration(duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TaskStatus>(
              valueListenable: transfer.statusNotifier,
              builder: (context, status, _) {
                return Row(
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
                    if (status != TaskStatus.complete &&
                        status != TaskStatus.canceled &&
                        status != TaskStatus.notFound)
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
}
