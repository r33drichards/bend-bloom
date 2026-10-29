import assert from 'node:assert/strict';
import {budgetFor, chooseSizing, predictedFpr, MiB, GPU_HEAP_BYTES} from '../sizing.mjs';
import {root, command} from './common.mjs';
import {pathToFileURL} from 'node:url';
const snapshot={memoryBytes:16*1024*MiB,freeMemoryBytes:8*1024*MiB,gpuMemory:{kind:'unified'}};
const budget=budgetFor(snapshot,'cpu');
const plan=(n,p,extra={})=>chooseSizing({expectedItems:n,targetFpr:p,budget,...extra});
assert.equal(budget.budgetBytes,1024*MiB);
assert.throws(()=>plan(10,.01,{budget:budgetFor({...snapshot,freeMemoryBytes:0},'cpu')}),/Insufficient/);
assert.equal(budgetFor(snapshot,'gpu').budgetBytes,GPU_HEAP_BYTES);
const dedicated={...snapshot,gpuMemory:{kind:'dedicated',freeBytes:800*MiB,totalBytes:4096*MiB}};
assert.equal(budgetFor(dedicated,'gpu').budgetBytes,400*MiB);
assert.throws(()=>plan(100,.01,{backend:'gpu',budget:budgetFor(dedicated,'gpu')}),/Insufficient/);
assert.throws(()=>budgetFor({},'cpu'),/unknown/);
assert.throws(()=>budgetFor({...snapshot,gpuMemory:{kind:'unknown'}},'gpu'),/unknown/);
assert.equal(budgetFor({},'cpu',128).budgetBytes,128*MiB);
assert.equal(budgetFor({...snapshot,freeMemoryBytes:MiB},'cpu',128).exceedsFreeSnapshot,true);
assert.throws(()=>budgetFor(snapshot,'cpu',32768),/total host/);
assert.throws(()=>budgetFor(dedicated,'gpu',4097),/total GPU/);
for(const b of [0,-1,Infinity,NaN,Number.MAX_VALUE,0.00000001]) assert.throws(()=>budgetFor(snapshot,'cpu',b));
assert.equal(budgetFor(snapshot,'gpu',1024).budgetBytes,512*MiB);
assert.throws(()=>budgetFor(snapshot,'other'));

const known=plan(1000,.01);
assert.equal(known.wordDepth,9);assert.equal(known.probes,11);
assert.ok(Math.abs(known.predictedFpr-0.0003822984983579275)<1e-15);
assert.equal(known.packedBytesPerShard,2048);
assert.ok(known.estimatedRequiredBytes>known.totalPackedBytes);
assert.equal(plan(1,.9).bitsPerShard,32);
// Independent direct-formula enumeration verifies minimum supported size and
// optimal integer probe count across easy, tight, and near-boundary requests.
let combinations=0;
for(const n of [1,3,32,100,1000,5000,50000]) for(const p of [.9,.5,.1,.01,.00001,1e-12]) {
  let reference;
  for(let d=0;d<=15&&!reference;d++) {
    const m=32*2**d;
    const ps=Array.from({length:32},(_,i)=>(1-Math.exp(-(i+1)*n/m))**(i+1));
    const best=Math.min(...ps);
    if(best<=p) reference={d,k:ps.indexOf(best)+1};
  }
  if(!reference) {assert.throws(()=>plan(n,p));continue;}
  const r=plan(n,p);
  assert.equal(r.wordDepth,reference.d);assert.equal(r.probes,reference.k);
  assert.ok(r.predictedFpr<=p);combinations++;
}
const boundary=predictedFpr(100,1024,7);
assert.equal(plan(100,boundary).bitsPerShard,1024);
assert.equal(plan(100,boundary*(1-1e-10)).bitsPerShard,2048);
const maxPlan=plan(70000,.001);
assert.equal(maxPlan.wordDepth,15);
assert.throws(()=>plan(1000000,.01),/maximum/);
assert.throws(()=>plan(1,Number.MIN_VALUE),/limits/);
for(const n of [0,-1,1.5,NaN,Infinity,Number.MAX_SAFE_INTEGER+1]) assert.throws(()=>plan(n,.01));
for(const p of [0,1,-.1,NaN,Infinity]) assert.throws(()=>plan(1,p));
for(const shards of [0,-1,1.5,16385]) assert.throws(()=>plan(100,.1,{shards}));
const exact={...budget,budgetBytes:known.estimatedRequiredBytes};
assert.equal(plan(1000,.01,{budget:exact}).wordDepth,9);
assert.throws(()=>plan(1000,.01,{budget:{...exact,budgetBytes:exact.budgetBytes-1}}),/Insufficient/);
const many=plan(1000,.01,{shards:8});
assert.equal(many.totalPackedBytes,known.totalPackedBytes*8);
assert.equal(many.estimatedRequiredBytes-budget.runtimeReserveBytes,(known.estimatedRequiredBytes-budget.runtimeReserveBytes)*8);
assert.throws(()=>plan(1000,.01,{shards:8,budget:exact}),/Insufficient/);
assert.throws(()=>plan(70000,.001,{backend:'gpu',shards:128,budget:budgetFor(snapshot,'gpu')}),/Insufficient/);

// Exercise the actual compiled Bend API using automatically selected settings.
const {default:B}=await import(pathToFileURL(`${root}/.build/bloom.mjs`));
const list=bytes=>bytes.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const key=n=>list([n&255,(n>>>8)&255,(n>>>16)&255,(n>>>24)&255]);
let insertedChecks=0;
for(const [n,p] of [[1,.9],[32,.1],[1000,.01],[2000,.00001]]) {
  const selected=plan(n,p);let f=B.create(selected.wordDepth,selected.probes).value;
  for(let i=0;i<n;i++) {const r=B.put(f,key(i));assert.equal(r.$,'Done');f=r.value;}
  for(let i=0;i<n;i++) {const r=B.mightContain(f,key(i));assert.equal(r.$,'Done');assert.equal(r.value.snd,true);f=r.value.fst;insertedChecks++;}
}
const sized=JSON.parse(command(process.execPath,['cli.mjs','size','--expected-items','1000','--fpp','0.01','--budget-mib','128']));
assert.equal(sized.wordDepth,9);
const benchmark=JSON.parse(command(process.execPath,['cli.mjs','benchmark','--expected-items','128','--fpp','0.01','--budget-mib','128','--items','128','--fork-depth','1','--iterations','1']));
assert.equal(benchmark.falseNegatives,0);
assert.ok(benchmark.parameters.sizing.predictedFpr<=.01);
assert.equal(benchmark.bitsPerShard,benchmark.parameters.sizing.bitsPerShard);
for(const args of [
 ['size','--expected-items','1'],
 ['size','--expected-items','9007199254740993','--fpp','.1'],
 ['size','--expected-items','1','--fpp','1e999'],
 ['size','--expected-items','1','--fpp','0'],
 ['size','--expected-items','1000','--fpp','.01','--budget-mib','1'],
 ['benchmark','--expected-items','128','--fpp','.01','--word-depth','5'],
 ['benchmark','--expected-items','128'],
 ['benchmark','--budget-mib','128'],
 ['benchmark','--expected-items','1','--fpp','.01'],
]) assert.throws(()=>command(process.execPath,['cli.mjs',...args]));
console.log(`PASS: sizing math (${combinations} feasible combinations), rounding/budget boundaries, unknown/unified/dedicated memory, input limits, ${insertedChecks} auto-sized inserted-key checks, and native auto-sized CLI workload`);
