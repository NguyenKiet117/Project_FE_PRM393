import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class PickedFile {
  final String name;
  final Uint8List bytes;
  const PickedFile(this.name, this.bytes);
  int get size => bytes.length;
}

/// Bọc plugin chọn file để dễ test. Chỉ file này import `file_picker`.
abstract class FilePickerService {
  Future<PickedFile?> pickSpreadsheet();
}

/// Dùng API của file_picker 12.x: FilePicker.pickFile() trả về PlatformFile?,
/// nội dung đọc bằng readAsBytes() (bản cũ dùng FilePicker.platform đã bị bỏ).
class DeviceFilePicker implements FilePickerService {
  const DeviceFilePicker();

  @override
  Future<PickedFile?> pickSpreadsheet() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    if (f == null) return null;
    return PickedFile(f.name, await f.readAsBytes());
  }
}
