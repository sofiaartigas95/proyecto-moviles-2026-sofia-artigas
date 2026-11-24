import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'create_item_page.dart';
import 'item_detail_screen.dart';
import 'item_image.dart';
import 'services/google_auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _soloMisPublicaciones = false;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Usuario';
    final String userEmail = user?.email ?? '';
    final String userId = user?.uid ?? '';

    //consulta según filtro
    Query query = FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true);

    if (_soloMisPublicaciones) {
      query = query.where('userId', isEqualTo: userId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuenta: $userName',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Botón filtro
          IconButton(
            icon: Icon(
              _soloMisPublicaciones
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: AppTheme.amarilloDetalle,
            ),
            tooltip: _soloMisPublicaciones
                ? 'Ver todos los objetos'
                : 'Ver solo mis publicaciones',
            onPressed: () {
              setState(() {
                _soloMisPublicaciones = !_soloMisPublicaciones;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await GoogleAuthService().signOut();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _soloMisPublicaciones
                        ? 'Mis publicaciones'
                        : 'Objetos publicados en el campus ($userEmail)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.azulPrincipal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // filtro activo
                Chip(
                  label: Text(
                    _soloMisPublicaciones
                        ? 'Filtro: Mis Cosas'
                        : 'Filtro: Todos',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  backgroundColor: AppTheme.amarilloSuave,
                  side: const BorderSide(color: AppTheme.amarilloDetalle),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar publicaciones: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _soloMisPublicaciones
                          ? 'No has publicado ningún objeto todavía.'
                          : 'No hay objetos publicados todavía.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String title = data['title'] ?? 'Sin título';
                    final String tipo = data['tipo'] ?? 'Perdido';
                    final String categoria = data['categoria'] ?? 'General';
                    final String estado = data['estado'] ?? 'Vigente';
                    final bool isDevuelto = estado == 'Devuelto';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: isDevuelto ? Colors.grey[200] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDevuelto
                              ? Colors.grey.shade400
                              : AppTheme.amarilloDetalle,
                          width: isDevuelto ? 1 : 1.2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(
                                itemId: docs[index].id,
                                itemData: data,
                              ),
                            ),
                          );
                        },
                        leading: ItemImage(
                          imageData: data['imageData'],
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isDevuelto
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('$tipo • $categoria\nEstado: $estado'),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            estado,
                            style: TextStyle(
                              color: isDevuelto ? Colors.black87 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: isDevuelto
                              ? AppTheme.amarilloDetalle
                              : AppTheme.azulPrincipal,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateItemPage()),
          );
        },
      ),
    );
  }
}
