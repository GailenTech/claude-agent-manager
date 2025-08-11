# Distribution Guide

Claude Agent Manager can be distributed through multiple package managers for maximum accessibility.

## 📦 Distribution Options

### 1. PyPI (Python Package Index) - Recommended

**For Python developers and users with Python installed:**

```bash
pip install claude-agent-manager
agent-manager
```

**Publishing to PyPI:**
```bash
# Install build tools
pip install build twine

# Build package
python -m build

# Upload to PyPI (requires account)
twine upload dist/*
```

### 2. npm (Node.js Package Manager)

**For JavaScript/Node.js developers:**

```bash
npm install -g claude-agent-manager
agent-manager
```

**How it works:**
- Downloads precompiled binary from GitHub releases
- Wraps binary in Node.js wrapper for cross-platform compatibility
- Works without Python installation

**Publishing to npm:**
```bash
npm publish
```

### 3. GitHub Releases (Current Method)

**Direct binary downloads:**

```bash
# macOS Intel
curl -L https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-macos-x86_64.tar.gz | tar -xz
sudo mv agent-manager-macos-x86_64 /usr/local/bin/agent-manager

# macOS Apple Silicon
curl -L https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-macos-arm64.tar.gz | tar -xz
sudo mv agent-manager-macos-arm64 /usr/local/bin/agent-manager

# Linux
curl -L https://github.com/GailenTech/claude-agent-manager/releases/latest/download/agent-manager-linux-x86_64.tar.gz | tar -xz
sudo mv agent-manager-linux-x86_64 /usr/local/bin/agent-manager
```

### 4. Homebrew (macOS/Linux)

**For Homebrew users:**

```bash
brew install claude-agent-manager
```

**Setup required:** Create and submit formula to homebrew-core or custom tap

### 5. Install Script (Universal)

**One-liner installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/GailenTech/claude-agent-manager/main/install.sh | sh
```

## 🎯 Recommendation by User Type

### Python Developers
```bash
pip install claude-agent-manager
```

### JavaScript/Node.js Developers  
```bash
npm install -g claude-agent-manager
```

### macOS Users
```bash
brew install claude-agent-manager  # (when available)
# or
curl -fsSL https://install.gailentech.com/agent-manager | sh
```

### Linux Users
```bash
pip install claude-agent-manager
# or
curl -fsSL https://install.gailentech.com/agent-manager | sh
```

### CI/CD & Automation
```bash
# Docker
FROM python:3.11
RUN pip install claude-agent-manager

# GitHub Actions
- name: Install Agent Manager
  run: pip install claude-agent-manager
```

## 📋 Package Configurations

### PyPI Package Structure
```
src/
└── claude_agent_manager/
    ├── __init__.py          # Entry point
    ├── agent-manager        # Main script
    └── agents-collection/   # Default agents
pyproject.toml              # Package metadata
```

### npm Package Structure  
```
bin/
└── agent-manager.js        # Node.js wrapper
scripts/
└── download-binary.js      # Binary downloader
package.json               # Package metadata
```

## 🚀 Publishing Workflow

### Automated Publishing (Recommended)

**.github/workflows/publish.yml:**
```yaml
name: Publish Packages
on:
  release:
    types: [published]

jobs:
  publish-pypi:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Build and publish to PyPI
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
        run: |
          pip install build twine
          python -m build
          twine upload dist/*

  publish-npm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          registry-url: 'https://registry.npmjs.org'
      - name: Publish to npm
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: npm publish
```

### Manual Publishing

**PyPI:**
```bash
python -m build
twine check dist/*
twine upload dist/*
```

**npm:**
```bash
npm version patch  # or minor/major
npm publish
```

## 🔧 Maintenance

### Version Management
- Use semantic versioning (1.0.0)
- Update version in both `pyproject.toml` and `package.json`
- Tag releases in Git

### Updates
- PyPI: Users run `pip install --upgrade claude-agent-manager`
- npm: Users run `npm update -g claude-agent-manager`
- Auto-update checking can be built into the tool

## 📊 Usage Analytics

### Package Download Stats
- PyPI: https://pypistats.org/packages/claude-agent-manager
- npm: https://npmjs.com/package/claude-agent-manager
- GitHub: Repository insights and release download counts

This multi-channel distribution strategy maximizes accessibility across different developer ecosystems while maintaining a single source of truth in the GitHub repository.