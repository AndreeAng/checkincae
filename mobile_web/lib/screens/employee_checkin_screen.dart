import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../providers/auth_provider.dart';
import '../utils/photo_cache.dart';
import 'employee_history_screen.dart';

class EmployeeCheckinScreen extends StatefulWidget {
  const EmployeeCheckinScreen({super.key});

  @override
  State<EmployeeCheckinScreen> createState() => _EmployeeCheckinScreenState();
}

class _EmployeeCheckinScreenState extends State<EmployeeCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();

  double? _latitude;
  double? _longitude;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _loading = false;
  String? _error;
  String _nextTypeLabel = 'Ingreso';
  Checkin? _lastCheckin;

  @override
  void initState() {
    super.initState();
    _loadLastCheckin();
    _restoreCachedPhoto();
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _loadLastCheckin() async {
    try {
      final api = context.read<AuthProvider>().api();
      final items = await api.getMyCheckins();
      if (items.isNotEmpty) {
        setState(() {
          _lastCheckin = items.first;
          _nextTypeLabel = items.first.type == 'IN' ? 'Salida' : 'Ingreso';
        });
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _restoreCachedPhoto() async {
    if (!kIsWeb) {
      return;
    }
    final cached = await loadTempPhoto();
    if (cached == null || cached.isEmpty) {
      return;
    }
    try {
      final bytes = base64Decode(cached);
      setState(() {
        _photoBytes = bytes;
        _photo = XFile.fromData(
          bytes,
          name: 'captura.jpg',
          mimeType: 'image/jpeg',
        );
      });
    } catch (_) {
      // Ignore corrupt cache
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        try {
          await saveTempPhoto(base64Encode(bytes));
        } catch (_) {
          // Ignora errores de almacenamiento en web.
        }
        setState(() {
          _photo = picked;
          _photoBytes = bytes;
        });
      } else {
        setState(() => _photo = picked);
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _error = null);
    if (kIsWeb) {
      final isLocalhost = Uri.base.host == 'localhost' ||
          Uri.base.host == '127.0.0.1' ||
          Uri.base.host == '0.0.0.0';
      final isSecure = Uri.base.scheme == 'https' || isLocalhost;
      if (!isSecure) {
        setState(() {
          _error =
              'En navegador se requiere HTTPS para pedir ubicación. Usa un túnel HTTPS o la app móvil.';
        });
        return;
      }
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() => _error = 'Activa la ubicación del dispositivo.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _error = 'Permiso de ubicación denegado.');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Debes obtener la ubicación.');
      return;
    }
    if (_photo == null) {
      setState(() => _error = 'La foto es obligatoria.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<AuthProvider>().api();
      final checkin = await api.createCheckin(
        latitude: _latitude!,
        longitude: _longitude!,
        activity: _activityController.text.trim(),
        photo: _photo!,
      );
      _showSuccess(checkin);
      _activityController.clear();
      setState(() {
        _photo = null;
        _photoBytes = null;
        _loading = false;
      });
      await clearTempPhoto();
      _loadLastCheckin();
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'No se pudo registrar. Intenta nuevamente.';
      });
    }
  }

  void _showSuccess(Checkin checkin) {
    final tipo = checkin.type == 'IN' ? 'Ingreso' : 'Salida';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registro guardado: $tipo')),
    );
  }

  Widget _photoPreview() {
    if (_photo == null) {
      return const Text('No hay foto seleccionada.');
    }

    if (kIsWeb) {
      if (_photoBytes == null) {
        return const Text('Procesando foto...');
      }
      return Image.memory(_photoBytes!, height: 180, fit: BoxFit.cover);
    }

    return Image.file(File(_photo!.path), height: 180, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final workSiteName = auth.user?.workSite?.name ?? 'Sin asignación';
    final formatter = DateFormat("EEEE d 'de' MMMM 'de' yyyy, h:mm a", 'es');
    final lastCheckinDate =
        _lastCheckin == null ? null : formatter.format(_lastCheckin!.occurredAt);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Historial',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EmployeeHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                        ),
                        IconButton(
                          tooltip: 'Cerrar sesión',
                          onPressed: () => auth.logout(),
                          icon: const Icon(Icons.logout),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Check-In CAE',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFFDE68A),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.user?.fullName ?? 'Empleado',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    workSiteName,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  lastCheckinDate ?? 'Sin registros previos',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workSiteName,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF16A34A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFFECFDF3),
                        ),
                        icon: const Icon(Icons.login, color: Color(0xFF16A34A)),
                        label: Text(
                          'REGISTRAR ${_nextTypeLabel.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.photo_camera,
                                  color: Color(0xFFF97316),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Foto de Evidencia',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: Center(child: _photoPreview()),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickPhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Tomar foto'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Descripción de Actividad',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _activityController,
                              decoration: const InputDecoration(
                                hintText:
                                    'Describe las actividades que realizarás hoy...',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Describe la actividad.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubicación',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _latitude == null || _longitude == null
                                        ? 'Sin ubicación'
                                        : '$_latitude, $_longitude',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _getLocation,
                                  child: const Text('Obtener'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'La fecha y hora se registran automáticamente con la zona horaria de Bolivia.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
