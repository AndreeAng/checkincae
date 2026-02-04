import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../providers/auth_provider.dart';
import '../utils/photo_url.dart';
import 'profile_screen.dart';
import '../utils/bo_time.dart';
import '../widgets/app_top_bar.dart';

class EmployeeHistoryScreen extends StatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  late Future<List<Checkin>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Checkin>> _load() async {
    final api = context.read<AuthProvider>().api();
    return api.getMyCheckins();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

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
      appBar: buildAppTopBar(
        title: 'Mi historial',
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Mi cuenta',
          ),
        ],
      ),
      body: FutureBuilder<List<Checkin>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar el historial.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aún no tienes registros.'));
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$tipo - ${formatter.format(occurred)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Lugar: ${item.workSite?.name ?? 'Sin asignación'}'),
                      Text('Actividad: ${item.activity}'),
                      Text('Ubicación: ${item.latitude}, ${item.longitude}'),
                      const SizedBox(height: 8),
                      if (photoUrl.isNotEmpty)
                        InkWell(
                          onTap: () => openPhoto(photoUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photoUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
