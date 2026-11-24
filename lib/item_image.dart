import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemImage extends StatelessWidget {
  const ItemImage({
    super.key,
    required this.imageData,
    required this.width,
    required this.height,
    this.legacyUrl,
    this.fit = BoxFit.cover,
  });

  final Object? imageData;
  final Object? legacyUrl;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final storedImage = imageData;
    if (storedImage is Blob) {
      return Image.memory(
        storedImage.bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    final oldImageUrl = legacyUrl;
    if (oldImageUrl is String && oldImageUrl.isNotEmpty) {
      return Image.network(
        oldImageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
