import assert from 'node:assert/strict';
import {mkdtempSync, readdirSync, readFileSync, writeFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {root, bend, command} from './common.mjs';

// Each mutant lives in a fresh copy; production sources are never modified.
const mutants = [
  ['XOR instead of OR', 'bits.bend', '(word .|. mask : U32)', '(word .^. mask : U32)'],
  ['zero position mask', 'bits.bend', '(1 << U32.to_nat((pos .&. 31 : U32)) : U32)', '0'],
  ['discard insertion', 'bloom.bend', 'set_bit(words, (h .&. mask : U32))', 'words'],
  ['query always false', 'bloom.bend', 'Bits.hit(value, bit)', 'False{}'],
];
for (const [name, file, before, after] of mutants) {
  const dir = mkdtempSync(join(tmpdir(), 'bend-bloom-proof-'));
  try {
    for (const file of readdirSync(root).filter(n=>n.endsWith('.bend')))
      writeFileSync(join(dir,file),readFileSync(join(root,file)));
    const original = readFileSync(join(dir,file),'utf8');
    assert.ok(original.includes(before),`Mutation target must exist: ${name}`);
    writeFileSync(join(dir,file),original.replace(before,after));
    const r = spawnSync(bend,['PROOF.bend'],{cwd:dir,encoding:'utf8',timeout:30000,
      env:{...process.env,BEND_NO_TELEMETRY:'1'}});
    assert.ifError(r.error);
    assert.notEqual(r.status,0,`Proof checker accepted mutant: ${name}`);
    assert.match(r.stdout+r.stderr,/SOME PROOFS FAIL/,`Expected proof rejection: ${name}`);
  } finally { rmSync(dir,{recursive:true,force:true}); }
}
command(bend,['PROOF.bend','-o','.build/PROOF.bendtt']);
console.log('PASS: four deliberate bit/insertion/query regressions rejected by proof gate; BendTT elaboration emitted (independent kernel not run)');
