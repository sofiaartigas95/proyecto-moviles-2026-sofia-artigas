import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_sofia_artigas/item_document_size.dart';

void main() {
  test('keeps resized photo and publication fields below Firestore limit', () {
    final size = estimateItemDocumentSize(
      fields: {'title': 'Llaves', 'description': 'Llaves azules'},
      imageSizeBytes: 300 * 1024,
    );

    expect(size, lessThan(firestoreMaxDocumentSizeBytes));
  });

  test(
    'rejects a photo when the estimated document exceeds Firestore limit',
    () {
      final size = estimateItemDocumentSize(
        fields: {'title': 'Llaves', 'description': 'Llaves azules'},
        imageSizeBytes: firestoreMaxDocumentSizeBytes,
      );

      expect(size, greaterThan(firestoreMaxDocumentSizeBytes));
    },
  );
}
