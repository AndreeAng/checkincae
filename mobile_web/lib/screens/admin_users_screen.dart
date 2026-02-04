import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/worksite.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import '../widgets/app_top_bar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = false;
  String? _error;
  List<User> _users = [];
  List<WorkSite> _workSites = [];

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
      _workSites = await api.getWorkSites();
      _users = await api.getUsers();
    } catch (_) {
      _error = 'No se pudo cargar empleados.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _openUserDialog({User? user}) async {
    final fullName = TextEditingController(text: user?.fullName ?? '');
    final username = TextEditingController(text: user?.username ?? '');
    final password = TextEditingController();
    String role = user?.role ?? 'EMPLOYEE';
    int? workSiteId = user?.workSite?.id;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Nuevo empleado' : 'Editar empleado'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullName,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: username,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: user == null ? 'Contraseña' : 'Nueva contraseña',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (user == null && (value == null || value.length < 6)) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'EMPLOYEE', child: Text('Empleado')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => role = value ?? role);
                    },
                    decoration: const InputDecoration(labelText: 'Rol'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: workSiteId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignación')),
                      ..._workSites.map(
                        (site) => DropdownMenuItem(
                          value: site.id,
                          child: Text(site.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => workSiteId = value);
                    },
                    decoration: const InputDecoration(labelText: 'Lugar de trabajo'),
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
      ),
    );

    if (result != true) {
      return;
    }

    final api = context.read<AuthProvider>().api();
    if (user == null) {
      await api.createUser(
        fullName: fullName.text.trim(),
        username: username.text.trim(),
        password: password.text,
        role: role,
        workSiteId: workSiteId,
      );
    } else {
      await api.updateUser(
        id: user.id,
        fullName: fullName.text.trim(),
        username: username.text.trim(),
        password: password.text.isEmpty ? null : password.text,
        role: role,
        workSiteId: workSiteId,
      );
    }
    await _refresh();
  }

  Future<void> _deleteUser(User user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text('¿Eliminar a ${user.fullName}?'),
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
    await api.deleteUser(user.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppTopBar(
        title: 'Empleados',
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _openUserDialog(),
            icon: const Icon(Icons.person_add),
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
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Text(_error!));
          }
          if (_users.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                child: ListTile(
                  title: Text(user.fullName),
                  subtitle: Text(
                    '${user.username} • ${user.role} • ${user.workSite?.name ?? 'Sin asignación'}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _openUserDialog(user: user),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _deleteUser(user),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: _users.length,
          );
        },
      ),
    );
  }
}
