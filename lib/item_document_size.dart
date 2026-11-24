import 'dart:convert';

const firestoreMaxDocumentSizeBytes = 1024 * 1024;
const _documentOverheadReserveBytes = 16 * 1024;

int estimateItemDocumentSize({
  required Map<String, dynamic> fields,
  required int imageSizeBytes,
}) {
  final fieldsSize = utf8.encode(jsonEncode(fields)).length;
  return fieldsSize + imageSizeBytes + _documentOverheadReserveBytes;
}
