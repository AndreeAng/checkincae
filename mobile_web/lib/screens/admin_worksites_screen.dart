import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/worksite.dart';
import '../providers/auth_provider.dart';

class AdminWorkSitesScreen extends StatefulWidget {
  const AdminWorkSitesScreen({super.key});

  @override
  State<AdminWorkSitesScreen> createState() => _AdminWorkSitesScreenState();
}

class _AdminWorkSitesScreenState extends State<AdminWorkSitesScreen> {
  bool _loading = false;
  String? _error;
  List<WorkSite> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api();
      _items = await api.getWorkSites();
    } catch (_) {
      _error = 'No se pudo cargar lugares.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _openDialog({WorkSite? site}) async {
    final name = TextEditingController(text: site?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site == null ? 'Nuevo lugar' : 'Editar lugar'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) {
      return;
    }

    final api = context.read<AuthProvider>().api();
    if (site == null) {
      await api.createWorkSite(
        name: name.text.trim(),
      );
    } else {
      await api.updateWorkSite(
        id: site.id,
        name: name.text.trim(),
      );
    }
    await _refresh();
  }

  Future<void> _deleteWorkSite(WorkSite site) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar ${site.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    final api = context.read<AuthProvider>().api();
    await api.deleteWorkSite(site.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lugares de trabajo'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _openDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Text(_error!));
          }
          if (_items.isEmpty) {
            return const Center(child: Text('No hay lugares registrados.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final site = _items[index];
              return Card(
                child: ListTile(
                  title: Text(site.name),
                  subtitle: const Text('Lugar de trabajo'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _openDialog(site: site),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _deleteWorkSite(site),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: _items.length,
          );
        },
      ),
    );
  }
}
