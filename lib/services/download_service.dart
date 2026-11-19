import 'package:background_downloader/background_downloader.dart';

class DownloadService {
  DownloadService._();

  static final DownloadService instance = DownloadService._();

  final FileDownloader _downloader = FileDownloader();
  final List<Transfer> _transfers = [];

  bool _initialized = false;

  List<Transfer> get transfers => List.unmodifiable(_transfers);

  Future<void> initialize() async {
    if (_initialized) return;

    await _downloader.start(autoCleanDatabase: true);

    _downloader.configureNotification(
      running: const TaskNotification(
        'BAHMED IDM',
        'جارٍ تنزيل {filename}',
      ),
      complete: const TaskNotification(
        'اكتمل التنزيل',
        '{filename}',
      ),
      progressBar: true,
      tapOpensFile: true,
    );

    final restored =
        await _downloader.transfers.rehydrateFromDatabase();

    _transfers
      ..clear()
      ..addAll(restored);

    _initialized = true;
  }

  bool isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<Transfer> addDownload(String url) async {
    await initialize();

    final cleanUrl = url.trim();

    if (!isValidUrl(cleanUrl)) {
      throw const FormatException('الرابط غير صالح');
    }

    final uri = Uri.parse(cleanUrl);

    final task = DownloadTask(
      url: cleanUrl,
      filename: uri.pathSegments.isNotEmpty &&
              uri.pathSegments.last.isNotEmpty
          ? uri.pathSegments.last
          : 'download_file',
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'downloads',
      transferHints: {
        TransferHint.userInitiated,
        TransferHint.largeFile,
      },
    );

    final transfer = await _downloader.transfers.start(task);

    _transfers.insert(0, transfer);

    return transfer;
  }

  Future<void> pauseDownload(Transfer transfer) async {
    await transfer.pause();
  }

  Future<void> resumeDownload(Transfer transfer) async {
    await transfer.resume();
  }

  Future<void> cancelDownload(Transfer transfer) async {
    await transfer.cancel();
    _transfers.remove(transfer);
  }

  Future<void> restoreDownloads() async {
    await initialize();

    final restored =
        await _downloader.transfers.rehydrateFromDatabase();

    _transfers
      ..clear()
      ..addAll(restored);
  }
}
