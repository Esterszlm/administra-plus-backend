import 'package:flutter/material.dart';

/// Permissões efetivas carregadas da API. Apenas controla a apresentação;
/// o FastAPI continua responsável por autorizar cada operação.
class AccessScope extends InheritedWidget {
  final bool isAdmin;
  final Set<String> permissions;

  const AccessScope({
    super.key,
    required this.isAdmin,
    required this.permissions,
    required super.child,
  });

  bool can(String name) => isAdmin || permissions.contains(name);

  static AccessScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccessScope>();

  @override
  bool updateShouldNotify(AccessScope oldWidget) =>
      isAdmin != oldWidget.isAdmin ||
      oldWidget.permissions.length != permissions.length ||
      !oldWidget.permissions.containsAll(permissions);
}
