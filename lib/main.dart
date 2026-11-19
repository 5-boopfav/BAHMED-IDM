import 'package:flutter/material.dart';

import 'services/download_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DownloadService.instance.initialize();

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: HomePage(
        onThemeChanged: (value) {
          setState(() => themeMode = value);
        },
        themeMode: themeMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

  final TextEditingController urlController = TextEditingController();

  final DownloadService service = DownloadService.instance;

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> addDownload() async {
    urlController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة تنزيل جديد'),
          content: TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'ضع رابط الملف هنا',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();

                if (!service.isValidUrl(url)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرابط غير صالح'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                try {
                  await service.addDownload(url);

                  if (mounted) {
                    setState(() {});
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تعذر بدء التنزيل: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('تنزيل'),
            ),
          ],
        );
      },
    );
  }

  Widget dashboardPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'مرحباً بك في',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 5),
        const Text(
          'BAHMED IDM',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(
                  Icons.downloading,
                  size: 65,
                  color: AppTheme.neon,
                ),
                const SizedBox(height: 12),
                const Text(
                  'مدير التنزيلات',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${service.transfers.length} عملية تنزيل',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addDownload,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة رابط تنزيل'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'التنزيلات الأخيرة',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...service.transfers.take(3).map(
              (transfer) => TransferCard(
                transfer: transfer,
                service: service,
                onChanged: () => setState(() {}),
              ),
            ),
      ],
    );
  }

  Widget downloadsPage() {
    final transfers = service.transfers;

    if (transfers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_for_offline, size: 65),
            SizedBox(height: 12),
            Text('لا توجد تنزيلات حالياً'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        return TransferCard(
          transfer: transfers[index],
          service: service,
          onChanged: () => setState(() {}),
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
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('الوضع الداكن'),
            subtitle: const Text('تغيير مظهر التطبيق'),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (value) {
              widget.onThemeChanged(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول التطبيق'),
            subtitle: Text('BAHMED IDM - مدير التنزيلات'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboardPage(),
      downloadsPage(),
      settingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BAHMED IDM',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: addDownload,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedPage,
        children: pages,
      ),
      floatingActionButton: selectedPage == 1
          ? FloatingActionButton(
              onPressed: addDownload,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() => selectedPage = index);
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class TransferCard extends StatelessWidget {
  final dynamic transfer;
  final DownloadService service;
  final VoidCallback onChanged;

  const TransferCard({
    super.key,
    required this.transfer,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: transfer.progressNotifier,
              builder: (context, progress, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.task.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress < 0
                          ? null
                          : progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress < 0
                          ? 'جارٍ التحضير'
                          : '${(progress * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: transfer.statusNotifier,
              builder: (context, status, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.toString().split('.').last,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إيقاف',
                      onPressed: () async {
                        await service.pauseDownload(transfer);
                        onChanged();
                      },
                      icon: const Icon(Icons.pause_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'استئناف',
                      onPressed: () async {
                        await service.resumeDownload(transfer);
                        onChanged();
                      },
                      icon: const Icon(Icons.play_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'إلغاء',
                      onPressed: () async {
                        await service.cancelDownload(transfer);
                        onChanged();
                      },
                      icon: const Icon(Icons.delete_outline),
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
}r: Colors.white, size: 38),
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
