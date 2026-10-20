import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/quiz_set.dart';
import '../providers/library_provider.dart';
import '../services/api_client.dart';
import '../services/file_picker_service.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

const _maxBytes = 15 * 1024 * 1024; // backend giới hạn 15MB

String formatSize(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KB'
    : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

/// Import Excel/CSV -> server (Apache POI) tự phân tích và tạo bộ đề.
class ImportScreen extends StatefulWidget {
  final FilePickerService picker;
  const ImportScreen({super.key, this.picker = const DeviceFilePicker()});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  PickedFile? _file;
  bool _busy = false;
  String? _error;
  QuizSet? _created;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final f = await widget.picker.pickSpreadsheet();
      if (f == null || !mounted) return;
      setState(() {
        _error = f.size > _maxBytes ? 'File quá lớn (tối đa 15 MB).' : null;
        _file = f.size > _maxBytes ? null : f;
        _created = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không mở được trình chọn file.');
    }
  }

  Future<void> _import() async {
    final f = _file;
    if (f == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await context
          .read<LibraryProvider>()
          .importQuiz(f, title: _title.text, category: _category.text);
      if (!mounted) return;
      setState(() {
        _created = created;
        _file = null;
        _title.clear();
        _category.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Import thất bại, thử lại sau.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = _file;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Import từ Excel', style: AppTheme.head(size: 22, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Biến file câu hỏi thành bài thi trắc nghiệm trong vài giây.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_created != null) ...[
          AppCard(
            key: const Key('import_success'),
            color: cs.tertiary.withValues(alpha: 0.12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.check_circle, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(child: Text('Đã tạo bộ đề', style: AppTheme.head(size: 16))),
              ]),
              const SizedBox(height: 6),
              Text('"${_created!.title}" • ${_created!.length} câu hỏi'),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('import_view'),
                onPressed: () => MainShellState.of(context)?.goTo(0),
                child: const Text('Xem ở Trang chủ'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Icon(Icons.upload_file, size: 48, color: cs.primary),
            const SizedBox(height: 8),
            Text('Chọn file .xlsx, .xls hoặc .csv',
                textAlign: TextAlign.center, style: AppTheme.head(size: 16)),
            const SizedBox(height: 4),
            Text('Tối đa 15 MB', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('pick_file'),
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open),
              label: const Text('Chọn file'),
            ),
          ]),
        ),
        if (f != null) ...[
          const SizedBox(height: 12),
          AppCard(
            key: const Key('picked_file'),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.description_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppTheme.head(size: 15, w: FontWeight.w600)),
                  Text('${formatSize(f.size)} • Sẵn sàng phân tích',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              IconButton(
                key: const Key('clear_file'),
                icon: const Icon(Icons.close),
                onPressed: _busy ? null : () => setState(() => _file = null),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('import_title'),
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Tiêu đề (không bắt buộc)', prefixIcon: Icon(Icons.title)),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('import_category'),
            controller: _category,
            decoration: const InputDecoration(
                labelText: 'Môn học (không bắt buộc)', prefixIcon: Icon(Icons.category_outlined)),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          AppCard(
            key: const Key('import_error'),
            color: cs.error.withValues(alpha: 0.10),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: TextStyle(color: cs.error))),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('btn_import'),
          onPressed: (f == null || _busy) ? null : _import,
          icon: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: Text(_busy ? 'Đang phân tích...' : 'Phân tích & tạo bộ đề'),
        ),
        const SizedBox(height: 20),
        Text('Định dạng file được hỗ trợ', style: AppTheme.head(size: 16)),
        const SizedBox(height: 8),
        const _FormatTile(
          title: '2 cột: Câu hỏi | Đáp án đúng',
          body: 'Hệ thống tự tạo 3 đáp án nhiễu từ các đáp án khác trong file. '
              'Có thể thêm cột số thứ tự ở đầu.',
        ),
        const SizedBox(height: 8),
        const _FormatTile(
          title: 'Đủ lựa chọn: Câu hỏi | A | B | C | D | Đáp án | Giải thích',
          body: 'Cột "Đáp án" là chữ cái A–D (hoặc nội dung đáp án). '
              'Cột "Giải thích" không bắt buộc.',
        ),
        const SizedBox(height: 8),
        Text('Dòng đầu là tiêu đề cột thì sẽ được bỏ qua.',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  final String title, body;
  const _FormatTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.head(size: 14, color: cs.primary)),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.35)),
      ]),
    );
  }
}
