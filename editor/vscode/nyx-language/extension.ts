import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { execSync } from 'child_process';

const NYX_MODE: vscode.DocumentFilter = { language: 'nyx', scheme: 'file' };

// Get path to embedded nyx binary
function getNyxPath(): string {
    const extPath = __dirname;
    const isWindows = process.platform === 'win32';
    return path.join(extPath, isWindows ? 'nyx.exe' : 'nyx');
}

// Install nyx to PATH if not already available
async function ensureNyxInstalled(): Promise<string> {
    const extPath = path.join(__dirname, 'nyx.exe');
    
    // Check if bundled nyx exists
    if (!fs.existsSync(extPath)) {
        throw new Error('Nyx runtime not found in extension');
    }
    
    // Check if nyx is already in PATH
    try {
        execSync('nyx --version', { stdio: 'ignore' });
        return 'nyx';
    } catch {
        // nyx not in PATH, install it
    }
    
    // Install to user's local bin directory
    const isWindows = process.platform === 'win32';
    const installDir = isWindows 
        ? path.join(os.homedir(), 'AppData', 'Local', 'Programs', 'nyx')
        : path.join(os.homedir(), '.local', 'bin');
    
    if (!fs.existsSync(installDir)) {
        fs.mkdirSync(installDir, { recursive: true });
    }
    
    const destPath = isWindows 
        ? path.join(installDir, 'nyx.exe')
        : path.join(installDir, 'nyx');
    
    // Copy nyx to install directory
    fs.copyFileSync(extPath, destPath);
    
    if (!isWindows) {
        fs.chmodSync(destPath, '755');
    }
    
    // Add to PATH (user environment)
    const currentPath = process.env.PATH || '';
    if (!currentPath.includes(installDir)) {
        // For Windows, we need to set user PATH
        if (isWindows) {
            try {
                execSync(`setx PATH "${installDir};%PATH%"`, { stdio: 'ignore' });
            } catch {
                // Fallback: create a wrapper script
            }
        }
    }
    
    return destPath;
}

export function activate(context: vscode.ExtensionContext) {
    console.log('Nyx extension is now active!');
    
    // Try to ensure nyx is available
    ensureNyxInstalled().then(nyxPath => {
        console.log('Nyx runtime ready:', nyxPath);
    }).catch(err => {
        console.error('Failed to ensure nyx:', err);
    });

    const commands = [
        'nyx.run.file',
        'nyx.build.package',
        'nyx.build.workspace',
        'nyx.install.package',
        'nyx.test.package',
        'nyx.test.file',
        'nyx.test.cursor',
        'nyx.test.workspace',
        'nyx.test.coverage',
        'nyx.benchmark.package',
        'nyx.benchmark.file',
        'nyx.benchmark.cursor',
        'nyx.debug.cursor',
        'nyx.lint.package',
        'nyx.lint.workspace',
        'nyx.vet.package',
        'nyx.vet.workspace',
        'nyx.impl.cursor',
        'nyx.import.add',
        'nyx.tools.install',
        'nyx.playground',
        'nyx.add.tags',
        'nyx.remove.tags',
        'nyx.run.modinit',
        'nyx.get.package',
        'nyx.create.project'
    ];

    commands.forEach(cmd => {
        context.subscriptions.push(vscode.commands.registerCommand(cmd, async () => {
            // Placeholder for command implementation
            // In a real implementation, this would call the Nyx CLI or Language Server
            const action = cmd.split('.').slice(1).join(' ');
            vscode.window.showInformationMessage(`Nyx: ${action} triggered`);
            
            // Run current file with embedded nyx
            if (cmd === 'nyx.run.file') {
                const editor = vscode.window.activeTextEditor;
                if (!editor) {
                    vscode.window.showErrorMessage('No active file');
                    return;
                }
                const filePath = editor.document.uri.fsPath;
                if (!filePath.endsWith('.ny') && !filePath.endsWith('.nx')) {
                    vscode.window.showErrorMessage('Please open a .ny or .nx file to run');
                    return;
                }
                const nyxPath = getNyxPath();
                const terminal = vscode.window.createTerminal('Nyx Run');
                terminal.show();
                terminal.sendText(`"${nyxPath}" "${filePath}"`);
                return;
            }
            
            // Example integration with CLI for build
            if (cmd === 'nyx.build.package') {
                const terminal = vscode.window.createTerminal('Nyx Build');
                terminal.show();
                terminal.sendText('nyx build .');
            }

            // Initialize module
            if (cmd === 'nyx.run.modinit') {
                if (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0) {
                    const rootPath = vscode.workspace.workspaceFolders[0].uri.fsPath;
                    const modPath = path.join(rootPath, 'nyx.mod');
                    
                    if (!fs.existsSync(modPath)) {
                        fs.writeFileSync(modPath, 'module "main" {\n\tversion "1.0.0"\n}\n');
                        vscode.window.showInformationMessage('Created nyx.mod');
                        const doc = await vscode.workspace.openTextDocument(modPath);
                        vscode.window.showTextDocument(doc);
                    } else {
                        vscode.window.showWarningMessage('nyx.mod already exists');
                    }
                } else {
                    vscode.window.showErrorMessage('No workspace open');
                }
            }

            // Install package
            if (cmd === 'nyx.install.package') {
                const pkgName = await vscode.window.showInputBox({ prompt: 'Enter package name to install' });
                if (pkgName) {
                    const terminal = vscode.window.createTerminal('Nyx Install');
                    terminal.show();
                    terminal.sendText(`nyx install ${pkgName}`);
                }
            }

            // Create Project
            if (cmd === 'nyx.create.project') {
                const folderUri = await vscode.window.showOpenDialog({
                    canSelectFiles: false,
                    canSelectFolders: true,
                    canSelectMany: false,
                    openLabel: 'Select Project Folder'
                });

                if (folderUri && folderUri[0]) {
                    const projectPath = folderUri[0].fsPath;
                    const projectName = path.basename(projectPath);

                    fs.writeFileSync(path.join(projectPath, 'main.nx'), 'print("Hello, Nyx!");\n');
                    fs.writeFileSync(path.join(projectPath, 'nyx.mod'), `module "${projectName}" {\n\tversion "0.1.0"\n}\n`);
                    fs.writeFileSync(path.join(projectPath, 'README.md'), `# ${projectName}\n\nA new Nyx project.\n`);

                    vscode.commands.executeCommand('vscode.openFolder', folderUri[0]);
                }
            }
        }));
    });

    // Register CodeLens Provider
    context.subscriptions.push(vscode.languages.registerCodeLensProvider(
        { language: 'nyx', scheme: 'file' },
        new NyxCodeLensProvider()
    ));

    // Diagnostics
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('nyx');
    context.subscriptions.push(diagnosticCollection);
    subscribeToDocumentChanges(context, diagnosticCollection);

    // Language Features
    context.subscriptions.push(vscode.languages.registerHoverProvider(NYX_MODE, new NyxHoverProvider()));
    context.subscriptions.push(vscode.languages.registerSignatureHelpProvider(NYX_MODE, new NyxSignatureHelpProvider(), '(', ','));
    context.subscriptions.push(vscode.languages.registerCompletionItemProvider(NYX_MODE, new NyxCompletionItemProvider(), '.', ' '));
    context.subscriptions.push(vscode.languages.registerDocumentSymbolProvider(NYX_MODE, new NyxDocumentSymbolProvider()));
    context.subscriptions.push(vscode.languages.registerDefinitionProvider(NYX_MODE, new NyxDefinitionProvider()));
    
    const legend = new vscode.SemanticTokensLegend(['class', 'function', 'variable', 'parameter'], ['declaration', 'readonly']);
    context.subscriptions.push(vscode.languages.registerDocumentSemanticTokensProvider(NYX_MODE, new NyxSemanticTokensProvider(legend), legend));
    
    context.subscriptions.push(vscode.languages.registerCodeActionsProvider(NYX_MODE, new NyxCodeActionProvider()));
    context.subscriptions.push(vscode.languages.registerDocumentFormattingEditProvider(NYX_MODE, new NyxDocumentFormattingEditProvider()));
    context.subscriptions.push(vscode.languages.registerReferenceProvider(NYX_MODE, new NyxReferenceProvider()));
    context.subscriptions.push(vscode.languages.registerRenameProvider(NYX_MODE, new NyxRenameProvider()));

    // Test Controller
    setupTestController(context);

    // Command for CodeLens
    let runTerminal: vscode.Terminal | undefined;
    context.subscriptions.push(vscode.window.onDidCloseTerminal(t => {
        if (t === runTerminal) {
            runTerminal = undefined;
        }
    }));

    context.subscriptions.push(vscode.commands.registerCommand('nyx.run.file', async (uri?: vscode.Uri) => {
        const targetUri = uri || vscode.window.activeTextEditor?.document.uri;
        if (targetUri) {
            const doc = vscode.workspace.textDocuments.find(d => d.uri.toString() === targetUri.toString());
            if (doc && doc.isDirty) {
                await doc.save();
            }

            if (!runTerminal) {
                runTerminal = vscode.window.createTerminal('Nyx Run');
            }
            runTerminal.show();
            runTerminal.sendText(`nyx "${targetUri.fsPath}"`);
        }
    }));

    context.subscriptions.push(vscode.commands.registerCommand('nyx.debug.file', (uri?: vscode.Uri) => {
        const targetUri = uri || vscode.window.activeTextEditor?.document.uri;
        if (targetUri) {
            vscode.debug.startDebugging(undefined, {
                type: 'nyx',
                name: 'Debug File',
                request: 'launch',
                program: targetUri.fsPath
            });
        }
    }));
}

export function deactivate() {
    console.log('Nyx extension deactivated');
}

class NyxCodeLensProvider implements vscode.CodeLensProvider {
    provideCodeLenses(document: vscode.TextDocument): vscode.CodeLens[] {
        const codeLenses: vscode.CodeLens[] = [];
        const text = document.getText();
        // Look for 'function main('
        const regex = /function\s+main\s*\(/g;
        let match;
        while ((match = regex.exec(text))) {
            const position = document.positionAt(match.index);
            const range = new vscode.Range(position, position);
            const command: vscode.Command = {
                title: "$(play) Run",
                command: "nyx.run.file",
                arguments: [document.uri]
            };
            codeLenses.push(new vscode.CodeLens(range, command));

            const debugCmd: vscode.Command = {
                title: "$(debug-alt) Debug",
                command: "nyx.debug.file",
                arguments: [document.uri]
            };
            codeLenses.push(new vscode.CodeLens(range, debugCmd));
        }
        return codeLenses;
    }
}

// --- Providers Implementation ---

class NyxHoverProvider implements vscode.HoverProvider {
    provideHover(document: vscode.TextDocument, position: vscode.Position): vscode.ProviderResult<vscode.Hover> {
        const range = document.getWordRangeAtPosition(position);
        const word = document.getText(range);
        
        // Simple mock for docstrings
        if (word === 'print') {
            return new vscode.Hover(new vscode.MarkdownString('**print**\n\nPrints values to stdout.'));
        }
        return null;
    }
}

class NyxSignatureHelpProvider implements vscode.SignatureHelpProvider {
    provideSignatureHelp(document: vscode.TextDocument, position: vscode.Position): vscode.ProviderResult<vscode.SignatureHelp> {
        const line = document.lineAt(position).text;
        const prefix = line.substring(0, position.character);
        
        if (prefix.trim().endsWith('print(')) {
            const signature = new vscode.SignatureInformation('print(...args: any)', 'Prints values to the console.');
            signature.parameters = [new vscode.ParameterInformation('...args', 'Values to print')];
            const help = new vscode.SignatureHelp();
            help.signatures = [signature];
            help.activeSignature = 0;
            help.activeParameter = 0;
            return help;
        }
        return null;
    }
}

class NyxCompletionItemProvider implements vscode.CompletionItemProvider {
    provideCompletionItems(document: vscode.TextDocument, position: vscode.Position): vscode.ProviderResult<vscode.CompletionItem[]> {
        const completions: vscode.CompletionItem[] = [];

        // Keywords
        ['var', 'let', 'if', 'else', 'function', 'class', 'return', 'import'].forEach(kw => {
            completions.push(new vscode.CompletionItem(kw, vscode.CompletionItemKind.Keyword));
        });

        // Snippets
        const funcSnippet = new vscode.CompletionItem('function', vscode.CompletionItemKind.Snippet);
        funcSnippet.insertText = new vscode.SnippetString('function ${1:name}(${2:args}) {\n\t$0\n}');
        funcSnippet.detail = 'Function definition';
        completions.push(funcSnippet);

        // Standard Library Snippets
        const fsSnippet = new vscode.CompletionItem('fs.readFile', vscode.CompletionItemKind.Snippet);
        fsSnippet.insertText = new vscode.SnippetString('fs.readFile("${1:path}")');
        fsSnippet.detail = 'Read file content';
        completions.push(fsSnippet);

        const netSnippet = new vscode.CompletionItem('net.get', vscode.CompletionItemKind.Snippet);
        netSnippet.insertText = new vscode.SnippetString('net.get("${1:url}")');
        netSnippet.detail = 'HTTP GET request';
        completions.push(netSnippet);
        
        const jsonSnippet = new vscode.CompletionItem('json.parse', vscode.CompletionItemKind.Snippet);
        jsonSnippet.insertText = new vscode.SnippetString('json.parse(${1:string})');
        jsonSnippet.detail = 'Parse JSON string';
        completions.push(jsonSnippet);

        const dateSnippet = new vscode.CompletionItem('date.now', vscode.CompletionItemKind.Snippet);
        dateSnippet.insertText = 'date.now()';
        dateSnippet.detail = 'Get current ISO date';
        completions.push(dateSnippet);

        const colorSnippet = new vscode.CompletionItem('color.hexToRgb', vscode.CompletionItemKind.Snippet);
        colorSnippet.insertText = new vscode.SnippetString('color.hexToRgb("${1:#ffffff}")');
        colorSnippet.detail = 'Convert Hex to RGB';
        completions.push(colorSnippet);

        return completions;
    }
}

class NyxDocumentSymbolProvider implements vscode.DocumentSymbolProvider {
    provideDocumentSymbols(document: vscode.TextDocument): vscode.ProviderResult<vscode.DocumentSymbol[]> {
        const symbols: vscode.DocumentSymbol[] = [];
        const text = document.getText();
        
        // Regex for functions: function name(...)
        const funcRegex = /function\s+([a-zA-Z_]\w*)/g;
        let match;
        while ((match = funcRegex.exec(text))) {
            const line = document.positionAt(match.index).line;
            const range = new vscode.Range(line, 0, line, match[0].length);
            const symbol = new vscode.DocumentSymbol(
                match[1],
                'Function',
                vscode.SymbolKind.Function,
                range, range
            );
            symbols.push(symbol);
        }

        // Regex for classes: class Name
        const classRegex = /class\s+([a-zA-Z_]\w*)/g;
        while ((match = classRegex.exec(text))) {
            const line = document.positionAt(match.index).line;
            const range = new vscode.Range(line, 0, line, match[0].length);
            const symbol = new vscode.DocumentSymbol(
                match[1],
                'Class',
                vscode.SymbolKind.Class,
                range, range
            );
            symbols.push(symbol);
        }

        return symbols;
    }
}

class NyxDefinitionProvider implements vscode.DefinitionProvider {
    provideDefinition(document: vscode.TextDocument, position: vscode.Position): vscode.ProviderResult<vscode.Definition> {
        const wordRange = document.getWordRangeAtPosition(position);
        const word = document.getText(wordRange);
        const text = document.getText();
        
        // Simple search for declaration in same file
        const regex = new RegExp(`(function|class|var|let)\\s+${word}\\b`);
        const match = regex.exec(text);
        
        if (match) {
            const targetPos = document.positionAt(match.index);
            return new vscode.Location(document.uri, targetPos);
        }
        return null;
    }
}

class NyxSemanticTokensProvider implements vscode.DocumentSemanticTokensProvider {
    constructor(private legend: vscode.SemanticTokensLegend) {}

    provideDocumentSemanticTokens(document: vscode.TextDocument): vscode.ProviderResult<vscode.SemanticTokens> {
        const builder = new vscode.SemanticTokensBuilder(this.legend);
        const text = document.getText();
        
        // Highlight 'class' names
        const classRegex = /class\s+([a-zA-Z_]\w*)/g;
        let match;
        while ((match = classRegex.exec(text))) {
            const pos = document.positionAt(match.index + match[0].indexOf(match[1]));
            builder.push(pos.line, pos.character, match[1].length, 0, 1); // 0=class, 1=declaration
        }

        return builder.build();
    }
}

class NyxCodeActionProvider implements vscode.CodeActionProvider {
    provideCodeActions(document: vscode.TextDocument, range: vscode.Range, context: vscode.CodeActionContext): vscode.ProviderResult<(vscode.Command | vscode.CodeAction)[]> {
        const actions: vscode.CodeAction[] = [];
        
        // Example: If diagnostic says "Unknown variable 'math'", suggest import
        context.diagnostics.forEach(diag => {
            if (diag.message.includes("Unknown variable")) {
                const action = new vscode.CodeAction('Add import for module', vscode.CodeActionKind.QuickFix);
                action.edit = new vscode.WorkspaceEdit();
                action.edit.insert(document.uri, new vscode.Position(0, 0), "import math;\n");
                actions.push(action);
            }
        });

        return actions;
    }
}

class NyxDocumentFormattingEditProvider implements vscode.DocumentFormattingEditProvider {
    provideDocumentFormattingEdits(document: vscode.TextDocument, options: vscode.FormattingOptions, token: vscode.CancellationToken): vscode.ProviderResult<vscode.TextEdit[]> {
        const edits: vscode.TextEdit[] = [];
        // Basic formatter: Trim trailing whitespace
        for (let i = 0; i < document.lineCount; i++) {
            const line = document.lineAt(i);
            if (line.text.endsWith(' ') || line.text.endsWith('\t')) {
                edits.push(vscode.TextEdit.delete(new vscode.Range(i, line.text.trimRight().length, i, line.text.length)));
            }
        }
        return edits;
    }
}

class NyxReferenceProvider implements vscode.ReferenceProvider {
    provideReferences(document: vscode.TextDocument, position: vscode.Position, context: vscode.ReferenceContext, token: vscode.CancellationToken): vscode.ProviderResult<vscode.Location[]> {
        const range = document.getWordRangeAtPosition(position);
        if (!range) return [];
        
        const word = document.getText(range);
        const references: vscode.Location[] = [];
        const text = document.getText();
        const escapedWord = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const regex = new RegExp(`\\b${escapedWord}\\b`, 'g');
        
        let match;
        while ((match = regex.exec(text))) {
            const startPos = document.positionAt(match.index);
            const endPos = document.positionAt(match.index + word.length);
            references.push(new vscode.Location(document.uri, new vscode.Range(startPos, endPos)));
        }
        return references;
    }
}

class NyxRenameProvider implements vscode.RenameProvider {
    provideRenameEdits(document: vscode.TextDocument, position: vscode.Position, newName: string, token: vscode.CancellationToken): vscode.ProviderResult<vscode.WorkspaceEdit> {
        const range = document.getWordRangeAtPosition(position);
        if (!range) return null;

        const word = document.getText(range);
        const edit = new vscode.WorkspaceEdit();
        const text = document.getText();
        const escapedWord = word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const regex = new RegExp(`\\b${escapedWord}\\b`, 'g');

        let match;
        while ((match = regex.exec(text))) {
            const startPos = document.positionAt(match.index);
            const endPos = document.positionAt(match.index + word.length);
            edit.replace(document.uri, new vscode.Range(startPos, endPos), newName);
        }
        return edit;
    }
}

// --- Diagnostics Logic ---

function subscribeToDocumentChanges(context: vscode.ExtensionContext, emojiDiagnostics: vscode.DiagnosticCollection): void {
    if (vscode.window.activeTextEditor) {
        refreshDiagnostics(vscode.window.activeTextEditor.document, emojiDiagnostics);
    }
    context.subscriptions.push(
        vscode.window.onDidChangeActiveTextEditor(editor => {
            if (editor) {
                refreshDiagnostics(editor.document, emojiDiagnostics);
            }
        })
    );
    context.subscriptions.push(
        vscode.workspace.onDidChangeTextDocument(e => refreshDiagnostics(e.document, emojiDiagnostics))
    );
    context.subscriptions.push(
        vscode.workspace.onDidCloseTextDocument(doc => emojiDiagnostics.delete(doc.uri))
    );
}

function refreshDiagnostics(doc: vscode.TextDocument, collection: vscode.DiagnosticCollection): void {
    if (doc.languageId !== 'nyx') return;

    const diagnostics: vscode.Diagnostic[] = [];
    const config = vscode.workspace.getConfiguration('nyx');
    const mode = config.get('analysis.typeCheckingMode');
    const lintingEnabled = config.get('linting.enabled');

    if (mode === 'off' || !lintingEnabled) {
        collection.clear();
        return;
    }

    for (let lineIndex = 0; lineIndex < doc.lineCount; lineIndex++) {
        const lineOfText = doc.lineAt(lineIndex);
        
        // Example check: Missing semicolon
        if (lineOfText.text.trim().length > 0 && 
            !lineOfText.text.trim().endsWith(';') && 
            !lineOfText.text.trim().endsWith('{') &&
            !lineOfText.text.trim().endsWith('}') &&
            !lineOfText.text.startsWith('//')) {
            
            const range = new vscode.Range(lineIndex, 0, lineIndex, lineOfText.text.length);
            const diagnostic = new vscode.Diagnostic(range, "Missing semicolon", vscode.DiagnosticSeverity.Warning);
            diagnostics.push(diagnostic);
        }

        // Example check: Strict mode 'var' usage
        if (mode === 'strict' && lineOfText.text.includes('var ')) {
            const index = lineOfText.text.indexOf('var ');
            const range = new vscode.Range(lineIndex, index, lineIndex, index + 3);
            const diagnostic = new vscode.Diagnostic(range, "Use 'let' or 'const' instead of 'var' in strict mode.", vscode.DiagnosticSeverity.Error);
            diagnostics.push(diagnostic);
        }
    }

    collection.set(doc.uri, diagnostics);
}

// --- Test Controller Logic ---

function setupTestController(context: vscode.ExtensionContext) {
    const controller = vscode.tests.createTestController('nyxTestController', 'Nyx Tests');
    context.subscriptions.push(controller);

    const runHandler = (request: vscode.TestRunRequest, token: vscode.CancellationToken) => {
        const run = controller.createTestRun(request);
        const queue: vscode.TestItem[] = [];

        if (request.include) {
            request.include.forEach(test => queue.push(test));
        } else {
            controller.items.forEach(test => queue.push(test));
        }

        while (queue.length > 0 && !token.isCancellationRequested) {
            const test = queue.pop()!;
            if (request.exclude?.includes(test)) {
                continue;
            }

            const start = Date.now();
            run.started(test);
            // Mock execution: Pass if name doesn't contain "fail"
            if (test.id.includes('fail')) {
                run.failed(test, new vscode.TestMessage('Test failed intentionally'), Date.now() - start);
            } else {
                run.passed(test, Date.now() - start);
            }
            
            test.children.forEach(child => queue.push(child));
        }
        run.end();
    };

    controller.createRunProfile('Run', vscode.TestRunProfileKind.Run, runHandler);

    // Simple discovery: look for functions starting with 'test_'
    vscode.workspace.onDidOpenTextDocument(doc => parseTestsInDocument(doc, controller));
    vscode.workspace.onDidChangeTextDocument(e => parseTestsInDocument(e.document, controller));
    if (vscode.window.activeTextEditor) {
        parseTestsInDocument(vscode.window.activeTextEditor.document, controller);
    }
}

function parseTestsInDocument(doc: vscode.TextDocument, controller: vscode.TestController) {
    if (doc.languageId !== 'nyx') return;

    const regex = /function\s+(test_[a-zA-Z0-9_]*)/g;
    const text = doc.getText();
    let match;

    while ((match = regex.exec(text))) {
        const name = match[1];
        const id = `${doc.uri.toString()}::${name}`;
        const line = doc.positionAt(match.index).line;
        
        let testItem = controller.items.get(id);
        if (!testItem) {
            testItem = controller.createTestItem(id, name, doc.uri);
            controller.items.add(testItem);
        }
        testItem.range = new vscode.Range(line, 0, line, match[0].length);
    }
}