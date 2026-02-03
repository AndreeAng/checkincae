import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../utils/photo_url.dart';
import '../utils/web_download.dart';
import '../utils/bo_time.dart';

class AdminCheckinsScreen extends StatefulWidget {
  const AdminCheckinsScreen({super.key});

  @override
  State<AdminCheckinsScreen> createState() => _AdminCheckinsScreenState();
}

class _AdminCheckinsScreenState extends State<AdminCheckinsScreen> {
  late Future<List<Checkin>> _future;
  List<User> _users = [];

  int? _employeeId;
  String _type = '';
  String _from = '';
  String _to = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Checkin>> _load() async {
    final api = context.read<AuthProvider>().api();
    _users = await api.getUsers();
    return api.getAdminCheckins(
      employeeId: _employeeId,
      type: _type,
      from: _from,
      to: _to,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final value = DateFormat('yyyy-MM-dd').format(picked);
      if (isFrom) {
        _from = value;
      } else {
        _to = value;
      }
    });
  }

  Future<void> _export() async {
    try {
      final api = context.read<AuthProvider>().api();
      final response = await api.exportCheckins(
        employeeId: _employeeId,
        type: _type,
        from: _from,
        to: _to,
      );
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'reportesregistrocae_$stamp.xlsx';
      final ok = downloadBytes(
        filename,
        response.bodyBytes,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportación disponible solo en web.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo exportar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final accent = const Color(0xFFF59E0B);
    final dark = const Color(0xFF0F172A);

    Future<void> openPhoto(String url) async {
      if (url.isEmpty) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de ingreso y salida'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _export,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    value: _employeeId,
                    decoration: const InputDecoration(labelText: 'Empleado'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._users.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _employeeId = value);
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _type.isEmpty ? null : _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todos')),
                      DropdownMenuItem(value: 'IN', child: Text('Ingreso')),
                      DropdownMenuItem(value: 'OUT', child: Text('Salida')),
                    ],
                    onChanged: (value) {
                      setState(() => _type = value ?? '');
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Desde',
                      hintText: _from.isEmpty ? 'YYYY-MM-DD' : _from,
                    ),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Hasta',
                      hintText: _to.isEmpty ? 'YYYY-MM-DD' : _to,
                    ),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Filtrar'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Checkin>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('No se pudo cargar registros.'));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No hay registros.'));
                }
                final baseUrl = context.read<AuthProvider>().baseUrl;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final tipo = item.type == 'IN' ? 'Ingreso' : 'Salida';
                    final occurred = toBoliviaTime(item.occurredAt);
                    final photoUrl = resolvePhotoUrl(item.photoUrl, baseUrl);
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 520;
                            final photo = photoUrl.isEmpty
                                ? Container(
                                    height: 64,
                                    width: 96,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.photo,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: () => openPhoto(photoUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        photoUrl,
                                        height: 64,
                                        width: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );

                            final info = Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tipo == 'Ingreso'
                                        ? const Color(0xFFECFDF3)
                                        : const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: tipo == 'Ingreso'
                                          ? const Color(0xFF16A34A)
                                          : accent,
                                    ),
                                  ),
                                  child: Text(
                                    tipo.toUpperCase(),
                                    style: TextStyle(
                                      color: tipo == 'Ingreso'
                                          ? const Color(0xFF16A34A)
                                          : accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatter.format(occurred),
                                  style: TextStyle(
                                    color: dark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Empleado: ${item.user?.fullName ?? ''}',
                                  style: TextStyle(color: dark, fontSize: 12),
                                ),
                                Text(
                                  'Lugar: ${item.workSite?.name ?? ''}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Actividad: ${item.activity}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Ubicación: ${item.latitude}, ${item.longitude}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  info,
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: photo,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                photo,
                                const SizedBox(width: 10),
                                Expanded(child: info),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
