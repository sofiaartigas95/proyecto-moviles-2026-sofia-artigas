import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'item_image.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    required this.itemData,
  });

  Future<void> _eliminarObjeto(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas borrar esta publicación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.rojoAcento),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> _marcarDevuelto(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'estado': 'Devuelto',
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objeto marcado como devuelto')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authorId = itemData['userId'] ?? '';
    final isAuthor = currentUser != null && currentUser.uid == authorId;
    final title = itemData['title'] ?? 'Sin título';
    final description = itemData['description'] ?? 'Sin descripción';
    final tipo = itemData['tipo'] ?? 'Perdido';
    final categoria = itemData['categoria'] ?? 'General';
    final location = itemData['location'] ?? 'No especificado';
    final fechaHora = itemData['fechaHora'] ?? '';
    final estado = itemData['estado'] ?? 'Vigente';
    final authorName =
        itemData['authorName'] ?? itemData['userEmail'] ?? 'Desconocido';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ItemImage(
              imageData: itemData['imageData'],
              width: double.infinity,
              height: 280,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          tipo,
                          style: TextStyle(
                            color: tipo == 'Perdido'
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: tipo == 'Perdido'
                            ? AppTheme.rojoAcento
                            : AppTheme.amarilloDetalle,
                      ),
                      Chip(
                        label: Text(
                          'Estado: $estado',
                          style: TextStyle(
                            color: estado == 'Devuelto'
                                ? Colors.black87
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: estado == 'Devuelto'
                            ? AppTheme.amarilloSuave
                            : AppTheme.azulPrincipal,
                        side: estado == 'Devuelto'
                            ? const BorderSide(color: AppTheme.amarilloDetalle)
                            : BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría: $categoria',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.azulPrincipal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Descripción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppTheme.azulPrincipal,
                      ),
                      const SizedBox(width: 6),
                      Text('Lugar: $location'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppTheme.azulPrincipal,
                      ),
                      const SizedBox(width: 6),
                      Text('Fecha y Hora: $fechaHora'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: AppTheme.azulPrincipal,
                      ),
                      const SizedBox(width: 6),
                      Text('Publicado por: $authorName'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (isAuthor) ...[
                    const Divider(),
                    const Text(
                      'Gestión de tu publicación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (estado != 'Devuelto')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.azulPrincipal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _marcarDevuelto(context),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Marcar como Devuelto'),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.rojoAcento,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _eliminarObjeto(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Borrar Publicación'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
