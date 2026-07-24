// Dump all exports from the il2cpp/GameAssembly module
// Run: frida -l dump_symbols.js -p <PID>
// Output goes to: C:\Users\Maver\Downloads\il2cpp_exports.txt

const fs = require('fs');
const outPath = 'C:\\Users\\Maver\\Downloads\\il2cpp_exports.txt';

const modules = Process.enumerateModules();
let il2cppMod = null;
for (const m of modules) {
    if (m.name.toLowerCase().includes('il2cpp') || m.name.toLowerCase().includes('gameassembly')) {
        il2cppMod = m;
        break;
    }
}
if (!il2cppMod) {
    console.log('[!] il2cpp module not found. All modules:');
    modules.forEach(m => console.log('  ' + m.name));
} else {
    console.log('[+] Found: ' + il2cppMod.name + ' at ' + il2cppMod.base);
    const exports = il2cppMod.enumerateExports();
    console.log('[+] ' + exports.length + ' exports found');
    const lines = exports.map(e => e.name);
    fs.writeFileSync(outPath, lines.join('\n'), 'utf8');
    console.log('[+] Saved to ' + outPath);
}
