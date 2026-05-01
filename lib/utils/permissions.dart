import '../models/auth_models.dart';

MenuGrants? getModuleGrants(List<MenuItem> menuItems, String moduleCode) {
  if (moduleCode.isEmpty) return null;
  try {
    final item = menuItems.firstWhere(
      (x) => (x.code ?? '') == moduleCode,
    );
    return item.grants;
  } catch (_) {
    return null;
  }
}

bool hasModuleGrant(
    List<MenuItem> menuItems, String moduleCode, String action) {
  final g = getModuleGrants(menuItems, moduleCode);
  if (g == null) return false;
  switch (action) {
    case 'create':
      return g.canCreate;
    case 'read':
      return g.canRead;
    case 'update':
      return g.canUpdate;
    case 'delete':
      return g.canDelete;
    default:
      return false;
  }
}
