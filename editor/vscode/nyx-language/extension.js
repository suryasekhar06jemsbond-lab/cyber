const vscode = require("vscode");

const ICON_THEME_ID = "cy-seti-icons";

async function activate(context) {
  const workbench = vscode.workspace.getConfiguration("workbench");
  const currentTheme = workbench.get("iconTheme");

  // Auto-apply Nyx icon theme so .nx files show the custom icon immediately.
  if (currentTheme !== ICON_THEME_ID) {
    try {
      await workbench.update(
        "iconTheme",
        ICON_THEME_ID,
        vscode.ConfigurationTarget.Global
      );
      await context.globalState.update("nyx.iconThemeAutoApplied", true);
    } catch (_) {
      // Ignore setting update failures (restricted environments/workspaces).
    }
  }
}

function deactivate() {}

module.exports = {
  activate,
  deactivate,
};
