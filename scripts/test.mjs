import assert from 'node:assert/strict';
import {mkdirSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
import {root, bend, command, checkVersion} from './common.mjs';
checkVersion();
mkdirSync(`${root}/.build`, {recursive:true});
console.log(command(bend, ['PROOF.bend']));
command(bend, ['bloom.bend', '-o', '.build/bloom.mjs']);
const {default:B} = await import(pathToFileURL(`${root}/.build/bloom.mjs`));
const list = bytes => bytes.reduceRight((tail, head) => ({$: 'Con',head,tail}), {$:'Nil'});
const unwrap = r => {assert.equal(r.$,'Done'); return r.value;};
const make = (d,k) => {const r=B.create(d,k); assert.equal(r.$,'Some');return r.value;};
const fnv = (bytes,seed) => bytes.reduce((a,b)=>Math.imul(a^b,16777619)>>>0,seed);
const mix = h => {h=Math.imul(h^(h>>>16),2246822507);h=Math.imul(h^(h>>>13),3266489909);return (h^(h>>>16))>>>0;};
const positions = (bytes,m,k) => {
  let h=mix(fnv(bytes,2166136261)); const step=(mix(fnv(bytes,3339675911))|1)>>>0;
  return Array.from({length:k},()=>{const p=h%m;h=(h+step)>>>0;return p;});
};
assert.equal(B.hash(list([]),2166136261),2166136261);
assert.equal(B.hash(list([...Buffer.from('hello')]),2166136261),0x4f9f2cab);
for(const [d,k] of [[16,3],[0,0],[0,33],[4294967295,1]]) assert.equal(B.create(d,k).$,'None');
assert.equal(B.create(15,32).$,'Some');
for(const bytes of [[256],[0,4294967295]]) {
  assert.equal(B.put(make(1,3),list(bytes)).$,'Fail');
  assert.equal(B.mightContain(make(1,3),list(bytes)).$,'Fail');
}
let state=0x12345678;
const random=()=>{state=(Math.imul(state,1664525)+1013904223)>>>0;return state;};
const keys=[[],[0],[255,254,128],[65,0,66], [...Buffer.from('héllo 🌻')], Array.from({length:256},(_,i)=>i)];
for(let i=0;i<300;i++) keys.push(Array.from({length:random()%48},()=>random()>>>24));
let checked=0;
for(const [d,k] of [[0,1],[0,32],[1,3],[4,7],[8,5],[10,12]]) {
  let f=make(d,k);const bits=new Uint8Array(32*2**d);
  for(const bytes of keys) {
    const result=unwrap(B.mightContain(f,list(bytes)));f=result.fst;
    assert.equal(result.snd,false,'empty filter');
  }
  for(const bytes of keys) {
    f=unwrap(B.put(f,list(bytes)));
    positions(bytes,bits.length,k).forEach(p=>bits[p]=1);
  }
  // Repeat insertion must not change packed storage.
  const snapshot=[...f.words];
  for(const bytes of keys) f=unwrap(B.put(f,list(bytes)));
  assert.deepEqual(f.words,snapshot);
  for(let i=0;i<bits.length;i++) assert.equal((f.words[i>>>5]>>>(i&31))&1,bits[i]);
  for(const bytes of keys) {
    const r=unwrap(B.mightContain(f,list(bytes))); f=r.fst;
    assert.equal(r.snd,true,'inserted byte key must be present');checked++;
  }
  for(let i=0;i<1000;i++) {
    const bytes=Array.from({length:8},()=>random()>>>24);
    const r=unwrap(B.mightContain(f,list(bytes)));f=r.fst;
    assert.equal(r.snd,positions(bytes,bits.length,k).every(p=>bits[p]===1));
  }
}
// A single insertion with all 32 distinct probes saturates a 32-bit filter.
let saturated=unwrap(B.put(make(0,32),list([1])));
assert.equal(unwrap(B.mightContain(saturated,list([2]))).snd,true,'expected false positive');
command(bend,['example.bend','-o','.build/example']);
assert.equal(command(`${root}/.build/example`,[]),'True{}');
console.log(`PASS: ${checked} inserted-key checks; 6000 independent-oracle queries; six configurations; byte validation; duplicate insertion; expected false positive; native example`);
const encode = n => [n&255,(n>>>8)&255,(n>>>16)&255,n>>>24];
let fppFilter=make(9,11);
for(let i=0;i<1000;i++) fppFilter=unwrap(B.put(fppFilter,list(encode(i))));
let falsePositives=0;
for(let i=1000;i<11000;i++) {
  const r=unwrap(B.mightContain(fppFilter,list(encode(i)))); fppFilter=r.fst;
  falsePositives+=Number(r.snd);
}
console.log(`Observed false positives: ${falsePositives}/10000 absent integer-byte keys (1000 inserted; 16384 bits; 11 probes). Descriptive sample, not a guarantee.`);
const native=JSON.parse(command(process.execPath,['cli.mjs','benchmark','--items','128','--fork-depth','3','--iterations','1']));
assert.equal(native.falseNegatives,0);
assert.equal(native.keysPerIteration,1024);
for(const args of [['--backend','bogus'],['--items','0'],['--probes','33'],['--fork-depth','14','--items','4096'],['--word-depth','10','--fork-depth','14']]) {
  assert.throws(()=>command(process.execPath,['cli.mjs','benchmark',...args]));
}
console.log('PASS: native CPU workload (1024 inserted keys per iteration) and CLI input/resource bounds');
