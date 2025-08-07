# 📋 Claude Code Agent Manager

## 🎯 Herramienta de Gestión de Agentes

Esta es una herramienta para organizar, instalar y gestionar agentes especializados de Claude Code. Los agentes están organizados por categorías y pueden instalarse selectivamente según las necesidades del proyecto.

## 🚀 Uso Principal

### Instalador Interactivo
```bash
./copy-agents-interactive.sh
```

### Instalador Básico
```bash
./copy-agents.sh
```

## 📁 Estructura de Agentes

Los agentes están organizados en `agents-collection/` por categorías:

- **platform/**: Gestión de productos y plataformas
- **frontend/**: Desarrollo de interfaces de usuario
- **backend/**: Servicios y APIs backend
- **infrastructure/**: DevOps, arquitectura y testing

## ✨ Características

- Interfaz interactiva con checkboxes
- Previsualización de descripciones de agentes
- Detección y gestión de conflictos
- Navegación completa adelante/atrás
- Instalación selectiva o masiva

## 🔧 Mantenimiento

Para añadir nuevos agentes, colócalos en la categoría apropiada dentro de `agents-collection/` usando el formato estándar con frontmatter YAML.

---

*Herramienta de gestión de agentes para Claude Code*