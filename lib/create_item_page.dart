import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'item_document_size.dart';

class CreateItemPage extends StatefulWidget {
  const CreateItemPage({super.key});

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  static const Map<String, String> _categoriasPredeterminadas = {
    'electronica': 'Electrónica',
    'documentos': 'Documentos',
    'ropa_accesorios': 'Ropa y accesorios',
    'llaves': 'Llaves',
    'utiles': 'Útiles',
    'otros': 'Otros',
  };

  static const int _minMinutosDia = 7 * 60 + 30;
  static const int _maxMinutosDia = 21 * 60;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  List<String> _categorias = [];
  String _tipo = 'Perdido';
  String? _categoriaSeleccionada;
  String? _errorCategorias;
  Uint8List? _imageBytes;
  bool _cargandoCategorias = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateTimeController.text = _formatearFechaHora(now);
    unawaited(_cargarCategorias());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  String _formatearFechaHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseFechaHora(String texto) {
    final partes = texto.trim().split(' ');
    if (partes.length != 2) return null;

    final fechaPartes = partes[0].split('/');
    final horaPartes = partes[1].split(':');
    if (fechaPartes.length != 3 || horaPartes.length != 2) return null;

    final dia = int.tryParse(fechaPartes[0]);
    final mes = int.tryParse(fechaPartes[1]);
    final anio = int.tryParse(fechaPartes[2]);
    final hora = int.tryParse(horaPartes[0]);
    final minuto = int.tryParse(horaPartes[1]);

    if (dia == null ||
        mes == null ||
        anio == null ||
        hora == null ||
        minuto == null) {
      return null;
    }

    final dt = DateTime(anio, mes, dia, hora, minuto);
    if (dt.year != anio ||
        dt.month != mes ||
        dt.day != dia ||
        dt.hour != hora ||
        dt.minute != minuto) {
      return null;
    }
    return dt;
  }

  String? _validarFechaHora(DateTime fechaHora) {
    final ahora = DateTime.now();
    if (fechaHora.isAfter(ahora)) {
      return 'La fecha y hora no pueden ser futuras.';
    }

    final minutosDelDia = fechaHora.hour * 60 + fechaHora.minute;
    if (minutosDelDia < _minMinutosDia || minutosDelDia > _maxMinutosDia) {
      return 'El horario permitido es de 07:30 a 21:00.';
    }

    return null;
  }

  String? _validarCampoFechaHora(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    final dt = _parseFechaHora(valor);
    if (dt == null) {
      return 'Formato de fecha y hora no válido';
    }
    return _validarFechaHora(dt);
  }

  Future<void> _cargarCategorias() async {
    try {
      final collection = FirebaseFirestore.instance.collection('categories');
      var snapshot = await collection.get();
      final categoriasExistentes = {
        for (final doc in snapshot.docs) doc.id: doc.data()['name'],
      };
      final batch = FirebaseFirestore.instance.batch();
      var hayCategoriasPorCrear = false;

      for (final entry in _categoriasPredeterminadas.entries) {
        if (categoriasExistentes[entry.key] != entry.value) {
          batch.set(collection.doc(entry.key), {'name': entry.value});
          hayCategoriasPorCrear = true;
        }
      }

      if (hayCategoriasPorCrear) {
        await batch.commit();
        snapshot = await collection.get();
      }

      final categorias = <String>[];
      for (final doc in snapshot.docs) {
        final name = doc.data()['name'];
        if (name is String && _categoriasPredeterminadas[doc.id] == name) {
          categorias.add(name);
        }
      }
      categorias.sort();

      if (categorias.length != _categoriasPredeterminadas.length) {
        throw StateError('No se pudieron cargar todas las categorías.');
      }
      if (!mounted) return;
      setState(() => _categorias = categorias);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _errorCategorias = error.message ?? error.code);
      }
    } on StateError catch (error) {
      if (mounted) setState(() => _errorCategorias = error.message);
    } finally {
      if (mounted) setState(() => _cargandoCategorias = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final ahora = DateTime.now();
    final fechaActual = _parseFechaHora(_dateTimeController.text);
    final fechaInicial = fechaActual != null && !fechaActual.isAfter(ahora)
        ? fechaActual
        : ahora;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2025),
      lastDate: ahora,
    );
    if (pickedDate == null || !mounted) return;

    final horaInicial = TimeOfDay(
      hour: fechaInicial.hour,
      minute: fechaInicial.minute,
    );
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );
    if (pickedTime == null || !mounted) return;

    final candidata = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final error = _validarFechaHora(candidata);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _dateTimeController.text = _formatearFechaHora(candidata);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría.')),
      );
      return;
    }
    final imageBytes = _imageBytes;
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fotografía del objeto es obligatoria.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'unknown';
      final userEmail = user?.email ?? 'Anónimo';
      final authorName =
          (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : userEmail;

      final itemData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'tipo': _tipo,
        'categoria': _categoriaSeleccionada,
        'fechaHora': _dateTimeController.text.trim(),
        'estado': 'Vigente',
        'userId': userId,
        'userEmail': userEmail,
        'authorName': authorName,
      };

      final estimatedDocumentSize = estimateItemDocumentSize(
        fields: itemData,
        imageSizeBytes: imageBytes.length,
      );
      if (estimatedDocumentSize > firestoreMaxDocumentSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La foto es demasiado grande para guardar la publicación. '
                'Elige otra imagen de menor tamaño.',
              ),
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('items').add({
        ...itemData,
        'imageData': Blob(imageBytes),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objeto publicado con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Objeto')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de publicación',
                      ),
                      items: <String>['Perdido', 'Encontrado']
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _tipo = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título del objeto',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _categoriaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _categorias
                          .map(
                            (categoria) => DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            ),
                          )
                          .toList(),
                      onChanged: _cargandoCategorias || _errorCategorias != null
                          ? null
                          : (String? categoria) {
                              setState(
                                () => _categoriaSeleccionada = categoria,
                              );
                            },
                      validator: (value) =>
                          value == null ? 'Seleccione una categoría' : null,
                    ),
                    if (_cargandoCategorias) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        color: AppTheme.amarilloDetalle,
                      ),
                    ],
                    if (_errorCategorias != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar categorías: $_errorCategorias',
                        style: const TextStyle(color: AppTheme.rojoAcento),
                      ),
                    ],
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción detallada',
                      ),
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lugar del campus (ej. Laboratorio U100)',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dateTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha y Hora (07:30 a 21:00)',
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: AppTheme.azulPrincipal,
                        ),
                      ),
                      onTap: _selectDateTime,
                      validator: _validarCampoFechaHora,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Fotografía del objeto (Obligatoria) *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.azulPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppTheme.amarilloSuave,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.amarilloDetalle,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: AppTheme.rojoAcento,
                            ),
                          ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera),
                          label: const Text('Cámara'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.amarilloDetalle,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.azulPrincipal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'Guardar y Publicar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
