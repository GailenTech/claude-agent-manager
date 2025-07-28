# Single-SPA Platform Development Agents

## Descripción del Proyecto

Este repositorio es el resultado de un prompt experimental para generar agentes de desarrollo especializados que puedan integrarse en ciclos de desarrollo de software. El objetivo es crear una estructura completa de agentes con roles específicos para desarrollar y mantener una plataforma empresarial basada en single-spa.

## Origen

Este proyecto fue generado a partir de un prompt inicial que solicitaba:
- Crear una versión especializada de CLAUDE.md para desarrollo con single-spa
- Utilizar context7 para descubrir mejores prácticas
- Diseñar una estructura de plataforma de servicios empresariales
- Definir múltiples perfiles de agentes especializados para diferentes aspectos del desarrollo

## Estructura de la Plataforma

La plataforma objetivo es un sistema empresarial basado en single-spa que incluye:

### Frontend
- **Shell principal**: Interfaz genérico de acceso a herramientas
- **Menú de identificación**: Sistema de autenticación OAuth2/Keycloak
- **Catálogo de herramientas**: Menú lateral con aplicaciones registradas
- **Aplicaciones de ejemplo**:
  - Aplicación VanillaJS
  - Aplicación Vue3
  - Aplicación React

### Backend
- Servicios independientes por aplicación
- Sistema basado en Temporal.io con aproximación API-first
- Arquitectura multitenant

### Infraestructura
- Desarrollo local con docker-compose
- CI/CD con GitHub Actions
- Trazabilidad continua con Git

## Agentes de Desarrollo

Este repositorio contiene las definiciones y configuraciones para los siguientes agentes especializados:

### Agentes de Plataforma
- **Platform Product Owner**: Gestión del producto single-spa
- **Single-SPA Developer**: Desarrollo de la plataforma
- **Platform Tester**: Testing de la plataforma single-spa

### Agentes de Servicios
- **Service Product Owner**: Definición de servicios y planes de prueba
- **Frontend VanillaJS Developer**
- **Frontend Vue3 Developer**
- **React Developer**

### Agentes de Backend
- **Spring Expert Developer**
- **Python Backend Developer**
- **NodeJS Backend Developer**
- **Temporal.io API Developer**

### Agentes de Infraestructura
- **Tech Architect**: Arquitectura cloud (GCP, AWS) con enfoque lean
- **Platform Developer**: Mantenimiento del sistema de desarrollo
- **E2E Tester**: Testing exploratorio con Playwright MCP y automatización

## Estructura del Repositorio

```
single-spa-platform-agents/
├── README.md                    # Este archivo
├── CLAUDE.md                    # Instrucciones principales para single-spa
├── DOCS.md                      # Índice de documentación
├── docs/                        # Documentación del proyecto
│   ├── DIARY.md                # Diario de desarrollo
│   ├── architecture/           # Documentación de arquitectura
│   └── platform/               # Documentación de la plataforma
├── agents/                      # Perfiles de agentes
│   ├── platform/               # Agentes de plataforma
│   ├── frontend/               # Agentes de frontend
│   ├── backend/                # Agentes de backend
│   └── infrastructure/         # Agentes de infraestructura
└── claude_tools/               # Scripts y herramientas auxiliares
```

## Uso

Este repositorio está diseñado para ser utilizado con Claude Code y otros agentes de codificación. Cada perfil de agente contiene:
- Instrucciones específicas del rol
- Mejores prácticas para su dominio
- Guías de integración con otros agentes
- Planes de validación y testing

## Desarrollo

Todo el desarrollo debe seguir las siguientes directrices:
- Trazabilidad continua en Git
- Testing completo antes de integración
- Documentación actualizada en DIARY.md
- Uso de feature branches para nuevas funcionalidades
- CI/CD obligatorio para despliegues

## Licencia

Proyecto privado de GailenTech. Todos los derechos reservados.

---

*Generado con Claude Code - Proyecto experimental de agentes de desarrollo*