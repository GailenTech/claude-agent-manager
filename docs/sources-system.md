# Agent Sources System

## Architecture Overview

The Agent Sources System allows users to manage multiple repositories of Claude agents, enabling extensibility and community contributions.

## Configuration Structure

```json
{
  "version": "1.0",
  "sources": [
    {
      "id": "default",
      "name": "Claude Agent Manager Official",
      "url": "https://github.com/GailenTech/claude-agent-manager.git",
      "path": "agents-collection",
      "enabled": true,
      "priority": 100,
      "last_sync": "2025-01-15T10:30:00Z",
      "branch": "main",
      "readonly": false
    },
    {
      "id": "awesome-agents",
      "name": "Awesome Claude Agents",
      "url": "https://github.com/awesome-claude-agents/collection.git",
      "path": "agents",
      "enabled": true,
      "priority": 90,
      "last_sync": null,
      "branch": "main",
      "readonly": true
    }
  ],
  "sync": {
    "auto_sync": true,
    "sync_interval": 86400,
    "last_auto_sync": "2025-01-15T10:30:00Z"
  }
}
```

## Storage Locations

- **User config**: `~/.config/claude-agent-manager/sources.json`
- **Sources cache**: `~/.cache/claude-agent-manager/sources/`
  - `default/` - Official collection
  - `awesome-agents/` - Community collection
  - etc.

## Source Types

### Git Sources
- Clone from public/private Git repositories
- Support for branches and tags
- Automatic updates with git pull
- Conflict resolution

### Local Sources
- Point to local filesystem directories
- Useful for development and custom collections
- Watch for file changes (optional)

### HTTP Sources
- Download zip/tar.gz archives
- Periodic updates from URLs
- Checksum validation

## UI Integration

### Sources Menu (new)
```
[s] Sources Manager
├── [a] Add New Source
├── [l] List Sources  
├── [e] Enable/Disable Sources
├── [r] Remove Source
├── [u] Update/Sync Sources
└── [c] Configure Auto-sync
```

### Main View Updates
- Show source origin for each agent
- Filter by source
- Conflict resolution when same agent exists in multiple sources

## Priority System

Sources have priority (0-100):
- Higher priority sources override lower ones
- Same agent name → highest priority wins
- User can see which source provides each agent
- Manual override possible

## Sync Behavior

### Manual Sync
- User triggered via UI or CLI
- Shows progress and conflicts
- Allows conflict resolution

### Auto Sync
- Configurable interval (daily default)
- Silent updates in background
- Notifications on conflicts or errors

## CLI Commands

```bash
agent-manager sources add <url> [--name=<name>] [--priority=<n>]
agent-manager sources list
agent-manager sources enable <id>
agent-manager sources disable <id>
agent-manager sources remove <id>
agent-manager sources sync [id]
agent-manager sources info <id>
```

## Security Considerations

- Git sources: verify SSL certificates
- Local sources: check file permissions  
- HTTP sources: verify checksums
- Sandboxed execution of source updates
- User confirmation for new sources

## Implementation Plan

1. **Core infrastructure** - Source config, storage, base classes
2. **Git source implementation** - Clone, pull, branch handling
3. **UI integration** - Sources menu, filtering, conflict resolution
4. **Auto-sync system** - Background updates, scheduling
5. **CLI commands** - Command line interface
6. **Documentation** - User guide, source creation guide