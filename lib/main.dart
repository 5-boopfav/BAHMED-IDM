import 'dart:async';
import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FileDownloader().start();

  FileDownloader().configureNotification(
    running: const TaskNotification(
      'BAHMED IDM',
      'جاري تنزيل {filename}',
    ),
    complete: const TaskNotification(
      'اكتمل التنزيل',
      '{filename}',
    ),
    progressBar: true,
  );

  runApp(const BahmedIDM());
}

class BahmedIDM extends StatefulWidget {
  const BahmedIDM({super.key});

  @override
  State<BahmedIDM> createState() => _BahmedIDMState();
}

class _BahmedIDMState extends State<BahmedIDM> {
  ThemeMode themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BAHMED IDM',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9A7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5B0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: DownloadHome(
          isDark: themeMode == ThemeMode.dark,
          onThemeChanged: () {
            setState(() {
              themeMode = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            });
          },
        ),
      ),
    );
  }
}

class DownloadHome extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const DownloadHome({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<DownloadHome> createState() => _DownloadHomeState();
}

class _DownloadHomeState extends State<DownloadHome> {
  final List<DownloadItem> downloads = [];
  final StreamController<void> refreshController =
      StreamController<void>.broadcast();

  int page = 0;

  @override
  void dispose() {
    refreshController.close();
    super.dispose();
  }

  Future<void> addDownload() async {
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تنزيل'),
        content: TextField(
          controller: urlController,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com/file.zip',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, urlController.text.trim());
            },
            child: const Text('تنزيل'),
          ),
        ],
      ),
    );

    urlController.dispose();

    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      showMessage('الرابط غير صالح. استخدم رابط HTTP أو HTTPS.');
      return;
    }

    final filename = uri.pathSegments.isNotEmpty &&
            uri.pathSegments.last.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.last)
        : 'download_${DateTime.now().millisecondsSinceEpoch}';

    final task = DownloadTask(
      url: url,
      filename: filename,
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'downloads',
      allowPause: true,
      retries: 3,
      transferHints: {
        TransferHint.userInitiated,
        TransferHint.largeFile,
      },
    );

    final item = DownloadItem(task: task);

    setState(() {
      downloads.insert(0, item);
    });

    try {
      final success = await FileDownloader().enqueue(task);

      if (!success) {
        showMessage('تعذر إضافة مهمة التنزيل.');
      } else {
        showMessage('تمت إضافة التنزيل.');
      }
    } catch (e) {
      showMessage('تعذر بدء التنزيل: $e');
    }
  }

  Future<void> pauseDownload(DownloadItem item) async {
    final success = await FileDownloader().pause(item.task);

    if (!success) {
      showMessage('تعذر إيقاف التنزيل مؤقتاً.');
    }
  }

  Future<void> resumeDownload(DownloadItem item) async {
    final success = await FileDownloader().resume(item.task);

    if (!success) {
      showMessage('تعذر استئناف التنزيل.');
    }
  }

  Future<void> cancelDownload(DownloadItem item) async {
    await FileDownloader().cancelTaskWithId(item.task.taskId);

    setState(() {
      downloads.remove(item);
    });

    showMessage('تم إلغاء المهمة.');
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF00E5B0)),
            SizedBox(width: 8),
            Text(
              'BAHMED IDM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onThemeChanged,
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: page,
        children: [
          dashboard(),
          downloadList(),
          settingsPage(),
        ],
      ),
      floatingActionButton: page == 0 || page == 1
          ? FloatingActionButton.extended(
              onPressed: addDownload,
              icon: const Icon(Icons.add),
              label: const Text('تنزيل جديد'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) {
          setState(() => page = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.download),
            label: 'التنزيلات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF087F70),
                Color(0xFF063D52),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.rocket_launch,
                size: 38,
                color: Colors.white,
              ),
              SizedBox(height: 15),
              Text(
                'مرحباً بك في BAHMED IDM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'مدير التنزيلات الخاص بك',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: statCard(
                'إجمالي المهام',
                downloads.length.toString(),
                Icons.download,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statCard(
                'المكتملة',
                downloads
                    .where((e) => e.status == TaskStatus.complete)
                    .length
                    .toString(),
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: statCard(
                'قيد التنزيل',
                downloads
                    .where((e) => e.status == TaskStatus.running)
                    .length
                    .toString(),
                Icons.downloading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statCard(
                'المتوقفة',
                downloads
                    .where((e) => e.status == TaskStatus.paused)
                    .length
                    .toString(),
                Icons.pause_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: addDownload,
          icon: const Icon(Icons.add_link),
          label: const Text('إضافة رابط جديد'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(17),
          ),
        ),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
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
