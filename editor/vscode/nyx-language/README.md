# Nyx Language Support (VS Code)

Provides language support for `.ny` files:

- syntax highlighting
- file icon for `.ny`
- comments/bracket auto-pairs
- common Nyx snippets

The extension auto-applies `Nyx Seti Icons` so `.ny` icons appear immediately.

## Install From `.vsix`

1. In VS Code, open command palette.
2. Run `Extensions: Install from VSIX...`.
3. Select `nyx-language.vsix`.

## Package Locally

```bash
cd editor/vscode/nyx-language
npm install
npx @vscode/vsce package
```

## Publish To Marketplace

1. Create a VS Code publisher account.
2. Login once with `npx @vscode/vsce login suryasekhar06jemsbond-lab`.
3. Publish with `npx @vscode/vsce publish`.
