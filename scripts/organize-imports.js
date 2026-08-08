const fs = require('fs');
const path = require('path');
const ts = require('typescript');

const roots = ['src', 'test'];
const files = [];
for (const root of roots) {
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const target = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(target);
      else if (entry.name.endsWith('.ts')) files.push(path.resolve(target));
    }
  };
  visit(path.resolve(root));
}

const options = ts.parseJsonConfigFileContent(
  ts.readConfigFile('tsconfig.json', ts.sys.readFile).config,
  ts.sys,
  process.cwd(),
).options;
const versions = new Map(files.map((file) => [file, '0']));
const host = {
  getScriptFileNames: () => files,
  getScriptVersion: (file) => versions.get(file) || '0',
  getScriptSnapshot: (file) => {
    if (!fs.existsSync(file)) return undefined;
    return ts.ScriptSnapshot.fromString(fs.readFileSync(file, 'utf8'));
  },
  getCurrentDirectory: () => process.cwd(),
  getCompilationSettings: () => options,
  getDefaultLibFileName: (opts) => ts.getDefaultLibFilePath(opts),
  fileExists: ts.sys.fileExists,
  readFile: ts.sys.readFile,
  readDirectory: ts.sys.readDirectory,
};
const service = ts.createLanguageService(host);

for (const file of files) {
  const changes = service.organizeImports(
    { type: 'file', fileName: file, skipDestructiveCodeActions: false },
    {},
    {},
  );
  if (!changes.length) continue;
  let text = fs.readFileSync(file, 'utf8');
  const edits = changes.flatMap((change) => change.textChanges);
  edits.sort((a, b) => b.span.start - a.span.start);
  for (const edit of edits) {
    text =
      text.slice(0, edit.span.start) +
      edit.newText +
      text.slice(edit.span.start + edit.span.length);
  }
  fs.writeFileSync(file, text);
}
