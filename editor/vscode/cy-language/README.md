# Cyper Language Support (VS Code)

Provides language support for `.cy` files:

- syntax highlighting
- file icon for `.cy`
- comments/bracket auto-pairs
- common Cyper snippets

For `.cy` file icons in Explorer, set icon theme to `Cyper Seti Icons`.

## Install From `.vsix`

1. In VS Code, open command palette.
2. Run `Extensions: Install from VSIX...`.
3. Select `cy-language.vsix`.

## Package Locally

```bash
cd editor/vscode/cy-language
npm install
npx @vscode/vsce package
```

## Publish To Marketplace

1. Create a VS Code publisher account.
2. Login once with `npx @vscode/vsce login suryasekhar06jemsbond-lab`.
3. Publish with `npx @vscode/vsce publish`.
