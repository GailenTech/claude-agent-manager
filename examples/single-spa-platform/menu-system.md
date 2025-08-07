# Sistema de Menús Dinámicos

## Concepto

El sistema de menús permite que cada micro-frontend registre sus propias opciones de navegación, las cuales son filtradas automáticamente según los roles del usuario autenticado.

## Arquitectura

### MenuService (Shell)
```typescript
interface MenuItem {
  id: string;
  label: string;
  icon?: string;
  route: string;
  requiredRoles: string[];
  children?: MenuItem[];
}

class MenuService {
  private menuItems: Map<string, MenuItem[]>;
  private observers: Set<(menu: MenuItem[]) => void>;
  
  registerMenuItems(appName: string, items: MenuItem[]): void
  unregisterMenuItems(appName: string): void
  getMenuForUser(userRoles: string[]): MenuItem[]
}
```

## Integración

### Desde Micro-Frontend
```javascript
// En el lifecycle hook mount
export function mount(props) {
  const { menuService } = props;
  
  menuService.registerMenuItems('my-app', [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: 'dashboard',
      route: '/my-app/dashboard',
      requiredRoles: ['user']
    },
    {
      id: 'admin',
      label: 'Administración',
      icon: 'settings',
      route: '/my-app/admin',
      requiredRoles: ['admin'],
      children: [
        {
          id: 'users',
          label: 'Usuarios',
          route: '/my-app/admin/users',
          requiredRoles: ['admin']
        }
      ]
    }
  ]);
}

// En unmount
export function unmount(props) {
  const { menuService } = props;
  menuService.unregisterMenuItems('my-app');
}
```

## Filtrado por Roles

El shell automáticamente:
1. Obtiene los roles del usuario desde el token JWT
2. Filtra items que requieren roles no presentes
3. Elimina padres vacíos (sin hijos visibles)
4. Actualiza el menú reactivamente

## Reactividad

- El menú se actualiza cuando:
  - Una aplicación se monta/desmonta
  - Los roles del usuario cambian
  - Se actualiza el token de autenticación

## Best Practices

1. **IDs únicos**: Usar prefijo de app en IDs
2. **Roles mínimos**: Solo requerir roles necesarios
3. **Iconos consistentes**: Usar set de iconos común
4. **Rutas absolutas**: Siempre usar rutas completas
5. **Cleanup**: Siempre desregistrar en unmount