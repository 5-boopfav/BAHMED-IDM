import 'package:material_ui/material_ui.dart';

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
                Text('${service.transfers.length} عملية تنزيل'),
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
                      onPressed: () async {
                        await service.pauseDownload(transfer);
                        onChanged();
                      },
                      icon: const Icon(Icons.pause_circle_outline),
                    ),
                    IconButton(
                      onPressed: () async {
                        await service.resumeDownload(transfer);
                        onChanged();
                      },
                      icon: const Icon(Icons.play_circle_outline),
                    ),
                    IconButton(
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
}
