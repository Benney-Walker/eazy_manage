import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';

/// Outcome of a PDF download-and-save.
enum PdfSaveResult { saved, cancelled }

/// Fetches report PDFs (raw bytes) and saves them to disk through the native
/// "Save As" dialog — mirroring the JavaFX FileChooser flow. Used by the
/// academic reports that have a `generate-*` endpoint.
class ReportPdfService {
  final ApiClient _api;

  ReportPdfService(this._api);

  /// GET [path] as bytes, then prompt the user for a save location. Returns
  /// whether the file was saved or the dialog was cancelled. Throws
  /// [ApiException] if the download itself fails.
  Future<PdfSaveResult> downloadAndSave({
    required String path,
    required String suggestedName,
  }) async {
    final bytes = await _api.getBytes(path);
    if (bytes.isEmpty) {
      throw const ApiException(
        'The server returned an empty document.',
        ApiFailureKind.server,
      );
    }

    final location = await FilePicker.platform.saveFile(
      dialogTitle: 'Save report',
      fileName: suggestedName.endsWith('.pdf')
          ? suggestedName
          : '$suggestedName.pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: Uint8List.fromList(bytes),
    );

    return location == null ? PdfSaveResult.cancelled : PdfSaveResult.saved;
  }
}

final reportPdfServiceProvider = Provider<ReportPdfService>((ref) {
  return ReportPdfService(ref.watch(apiClientProvider));
});
