# 📋 Single-SPA Platform Development Instructions

## 🎯 Proyecto: Plataforma de Servicios Empresariales con Single-SPA

### 🏗️ Visión General
Estamos construyendo una plataforma empresarial modular basada en single-spa que permite la integración de múltiples aplicaciones y servicios de forma independiente. La arquitectura está diseñada para soportar desarrollo con agentes de IA, manteniendo ciclos de desarrollo completamente independientes para cada componente.

### 🔍 Context Discovery
**IMPORTANTE**: Antes de implementar cualquier funcionalidad con single-spa, SIEMPRE:
1. Busca en context7 las mejores prácticas actuales
2. Revisa la documentación oficial de single-spa
3. Consulta ejemplos de implementaciones empresariales exitosas
4. Valida que la aproximación sea compatible con desarrollo mediante agentes

---

## 🏛️ Arquitectura de la Plataforma

### 🖥️ Frontend - Shell Principal

#### Estructura Base
```
shell/
├── src/
│   ├── auth/           # Sistema de autenticación OAuth2/Keycloak
│   ├── navigation/     # Menú lateral y navegación
│   ├── header/         # Menú de identificación superior
│   ├── registry/       # Registro dinámico de aplicaciones
│   └── menu-api/       # API de configuración de menús
```

#### Componentes Clave
1. **Header de Identificación**
   - Integración con OAuth2/Keycloak
   - Gestión de sesión y permisos
   - Menú de usuario y configuración

2. **Sistema de Menús Dinámico**
   - Registro client-side desde cada micro-frontend
   - Hook de single-spa para registro en mount
   - Filtrado automático por roles del usuario
   - Estructura jerárquica con submenús
   - Actualización reactiva del menú
   ```javascript
   // Ejemplo de registro desde micro-frontend
   export function mount(props) {
     const { menuService, authService } = props;
     
     menuService.registerMenuItems('vue3-app', [{
       id: 'reports',
       label: 'Reportes',
       icon: 'chart-bar',
       route: '/vue/reports',
       requiredRoles: ['user', 'admin'],
       children: [{
         id: 'sales',
         label: 'Ventas',
         route: '/vue/reports/sales',
         requiredRoles: ['sales', 'admin']
       }]
     }]);
     
     // Mount app...
   }
   
   export function unmount(props) {
     const { menuService } = props;
     menuService.unregisterMenuItems('vue3-app');
     // Unmount app...
   }
   ```

3. **Sistema de Registro**
   - Registro dinámico de micro-frontends
   - Configuración de rutas y permisos
   - Health checks de aplicaciones
   - Sincronización con sistema de menús

### 🔧 Aplicaciones Micro-Frontend

#### VanillaJS Application
```
apps/vanilla-app/
├── src/
│   ├── main.js         # Bootstrap de single-spa
│   ├── components/     # Componentes vanilla
│   └── services/       # Conexión con backend
```

#### Vue3 Application
```
apps/vue3-app/
├── src/
│   ├── main.js         # Bootstrap de single-spa
│   ├── components/     # Componentes Vue
│   ├── stores/         # Estado con Pinia
│   └── services/       # API services
```

#### React Application
```
apps/react-app/
├── src/
│   ├── index.js        # Bootstrap de single-spa
│   ├── components/     # Componentes React
│   ├── hooks/          # Custom hooks
│   └── services/       # Servicios API
```

### 🔌 Backend Architecture

#### Temporal.io Integration
- **API-First Design**: Todos los workflows expuestos como APIs REST
- **Multitenant**: Aislamiento por namespace en Temporal
- **Event-Driven**: Comunicación asíncrona entre servicios

#### Servicios Backend
```
backend/
├── gateway/            # API Gateway
├── auth-service/       # Autenticación y autorización
├── temporal-worker/    # Workers de Temporal
├── services/
│   ├── vanilla-api/    # Backend para VanillaJS
│   ├── vue3-api/       # Backend para Vue3
│   └── react-api/      # Backend para React
```

---

## 🚀 Prácticas de Desarrollo

### 🌿 Git Workflow
1. **Feature Branches Obligatorios**
   ```bash
   # Para nuevas funcionalidades
   git checkout -b feature/spa-<component>-<feature>
   
   # Para experimentos
   git checkout -b experiment/spa-<experiment>
   
   # Para fixes
   git checkout -b fix/spa-<issue>
   ```

2. **Commits Semánticos**
   ```
   feat(shell): add dynamic app registration
   fix(auth): resolve OAuth2 token refresh
   docs(platform): update single-spa integration guide
   ```

### 🧪 Testing Strategy

#### Unit Testing
- Cada micro-frontend con su suite de tests
- Coverage mínimo: 80%
- Tests aislados sin dependencias externas

#### Integration Testing
- Tests de comunicación entre micro-frontends
- Validación de eventos single-spa
- Tests de registro/desregistro de aplicaciones

#### E2E Testing
- Playwright para testing exploratorio
- Cypress para automatización
- Scenarios multitenant obligatorios

### 🐳 Development Environment

#### Docker Compose Structure
```yaml
services:
  # Frontend
  shell:
    build: ./shell
    ports: ["9000:9000"]
  
  vanilla-app:
    build: ./apps/vanilla-app
    ports: ["9001:9001"]
  
  vue3-app:
    build: ./apps/vue3-app
    ports: ["9002:9002"]
  
  react-app:
    build: ./apps/react-app
    ports: ["9003:9003"]
  
  # Backend
  gateway:
    build: ./backend/gateway
    ports: ["8080:8080"]
  
  temporal:
    image: temporalio/auto-setup
    ports: ["7233:7233"]
  
  keycloak:
    image: quay.io/keycloak/keycloak
    ports: ["8081:8080"]
```

---

## 🔐 Security & Authentication

### OAuth2/Keycloak Integration
1. **Realms Configuration**
   - Realm por tenant
   - Roles jerárquicos
   - Permisos granulares por aplicación

2. **Token Management**
   - Refresh automático en shell
   - Propagación a micro-frontends
   - Interceptores HTTP configurados

### Single-SPA Security
- Aislamiento de contexto entre aplicaciones
- Comunicación segura vía custom events
- Validación de permisos antes de mount

---

## 📊 Monitoring & Observability

### Application Health
- Health checks por micro-frontend
- Métricas de performance
- Error boundaries y reporting

### Temporal Monitoring
- Workflow metrics
- Worker health
- Queue monitoring

---

## 🛠️ CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: Single-SPA Platform CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-shell:
    # Tests del shell principal
  
  test-apps:
    # Tests de cada micro-frontend
  
  test-backend:
    # Tests de servicios backend
  
  build-and-deploy:
    # Build y deploy condicional
```

### Deployment Strategy
1. **Development**: Auto-deploy de feature branches
2. **Staging**: Deploy manual con aprobación
3. **Production**: Blue-green deployment

---

## 📝 Documentation Requirements

### Por Aplicación
- README.md específico
- API documentation
- Integration guide con shell
- Test plan detallado

### Platform Level
- Architecture Decision Records (ADRs)
- Integration patterns
- Security guidelines
- Performance benchmarks

---

## 🎭 Agent Development Guidelines

### Communication Between Agents
- Usar DIARY.md para handoffs
- Documentar decisiones en ADRs
- Mantener CLAUDE.md actualizado por componente

### Agent Responsibilities
- Cada agente es dueño de su dominio
- Colaboración vía PRs y reviews
- Testing cross-agent obligatorio

### Quality Gates
1. **Code**: Linting y formatting automático
2. **Tests**: Todos los tests pasando
3. **Documentation**: Actualizada con cambios
4. **Security**: Scan de vulnerabilidades

---

## ⚠️ Critical Reminders

### Single-SPA Specific
- 🔄 **System.js** para carga dinámica
- 📦 **Webpack Module Federation** cuando aplique
- 🎯 **Import maps** para gestión de dependencias
- 🔌 **Lifecycle methods** correctamente implementados

### Platform Requirements
- 🌐 **Multitenant** desde el diseño
- 🤖 **Agent-friendly** code y documentación
- 🧪 **Test-first** development
- 📊 **Observable** y monitoreable

### Development Flow
1. 🔍 Research con context7
2. 📋 Plan en DIARY.md
3. 🌿 Feature branch
4. 💻 Implement con TDD
5. 🧪 Test exhaustivo
6. 📝 Document changes
7. 🚀 CI/CD validation

---

## 🚨 PROHIBITIONS

### Never Do
- ❌ Hardcode tenant information
- ❌ Share state directly between micro-frontends
- ❌ Bypass authentication/authorization
- ❌ Deploy without passing CI/CD
- ❌ Modify other agent's code without PR

### Always Do
- ✅ Use single-spa parcels for shared components
- ✅ Implement proper error boundaries
- ✅ Version all APIs
- ✅ Test multitenant scenarios
- ✅ Document integration points

---

*Este documento es la guía principal para el desarrollo de la plataforma single-spa. Cada componente puede tener su propio CLAUDE.md extendiendo estas directrices.*