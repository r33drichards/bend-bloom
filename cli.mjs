#!/usr/bin/env node
import os from 'node:os';
import {spawnSync} from 'node:child_process';
import {mkdirSync, writeFileSync} from 'node:fs';
import {performance} from 'node:perf_hooks';
import {root, bend, command, checkVersion} from './scripts/common.mjs';

const help = `Usage: node cli.mjs stats
       node cli.mjs benchmark|start|run [options]
  --backend cpu|gpu     Native CPU (default) or strict GPU execution
  --word-depth 0..10    Bits per shard = 32 * 2^depth (default 5)
  --probes 1..32        Hash probes per key (default 5)
  --items 1..4096       Four-byte keys per shard (default 128)
  --fork-depth 0..14    Independent shards = 2^depth (default 3)
  --threads 1..32       CPU workers (default min(8, available CPUs))
  --warmup 1..5         Untimed iterations (default 1)
  --iterations 1..10    Measured iterations (default 3)
Caps: 262144 keys/iteration, 8 MiB packed filter payload across shards,
      512 MiB GPU runtime heap, 120-second compile/run timeout.
Each iteration creates shards, inserts all keys, then queries every key.
Reports workload wall time, process wall time, build time and false negatives.
GPU mode requires real GPU support; it never silently falls back to CPU.`;
function probe(exe,args) {
  const r=spawnSync(exe,args,{encoding:'utf8',timeout:10000,maxBuffer:2**20});
  return r.error || r.status!==0 ? {available:false,reason:r.error?.message || r.stderr.trim() || `exit ${r.status}`} : {available:true,output:r.stdout.trim()};
}
function stats() {
  return {os:os.platform(),architecture:os.arch(),cpuModel:os.cpus()[0]?.model || 'unavailable',
    logicalCpus:os.cpus().length,availableParallelism:os.availableParallelism(),memoryBytes:os.totalmem(),
    compiler:probe(bend,['version']),nativeCompiler:probe(process.env.CC || 'clang',['--version']),sdkRoot:process.env.SDKROOT || null,
    graphics:os.platform()==='darwin' ? probe('system_profiler',['SPDisplaysDataType','-json']) : probe('nvidia-smi',['--query-gpu=name,memory.total,driver_version','--format=csv,noheader']),
    gpuNote:'Hardware discovery is informational. Only a successful native GPU benchmark verifies Bend runtime support. JavaScript is sequential. No utilization/occupancy telemetry is collected.'};
}
function integer(value,name,min,max) {
  if(!/^\d+$/.test(value) || Number(value)<min || Number(value)>max) throw new Error(`${name} must be an integer ${min}..${max}`);
  return Number(value);
}
function parse(args) {
  const defaults={'backend':'cpu','word-depth':5,'probes':5,'items':128,'fork-depth':3,'threads':Math.min(8,os.availableParallelism()),'warmup':1,'iterations':3};
  const limits={'word-depth':[0,10],probes:[1,32],items:[1,4096],'fork-depth':[0,14],threads:[1,32],warmup:[1,5],iterations:[1,10]};
  const seen=new Set();
  for(let i=0;i<args.length;i+=2) {
    const name=args[i].replace(/^--/,''); const value=args[i+1];
    if(!args[i].startsWith('--') || !(name in defaults) || value===undefined || seen.has(name)) throw new Error(`Invalid or repeated option: ${args[i]}`);
    seen.add(name);
    defaults[name]=name==='backend' ? value : integer(value,name,...limits[name]);
  }
  if(!['cpu','gpu'].includes(defaults.backend)) throw new Error('backend must be cpu or gpu');
  const shards=2**defaults['fork-depth'];
  if(shards*defaults.items>262144) throw new Error('Total keys exceed 262144');
  if(shards*4*2**defaults['word-depth']>8*1024*1024) throw new Error('Packed shard payload exceeds 8 MiB');
  return defaults;
}
function source(p) {
  const call=`Work.run${p.backend==='gpu'?'!':''}(${p['fork-depth']}n, ${p['word-depth']}, ${p.probes}, ${p.items}n, 0)`;
  return `import Base
import ../workload.bend as Work

def warm(n: Nat) -> IO(Unit):
  match n:
    case 0n: IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        errors : U32 = ${call}
        IO.print("warmup_errors=" ++ U32.show(errors))
        warm(p)

def measure(n: Nat) -> IO(Unit):
  match n:
    case 0n: IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        start : Nat <- IO.now()
        errors : U32 = ${call}
        IO.print("errors=" ++ U32.show(errors))
        stop : Nat <- IO.now()
        IO.print("workload_ms=" ++ Nat.show(Nat.sub(stop, start)))
        measure(p)

def main() -> IO(Unit):
  do IO<Unit>:
    warm(${p.warmup}n)
    measure(${p.iterations}n)
`;
}
function benchmark(p) {
  const version=checkVersion();
  mkdirSync(`${root}/.build`,{recursive:true});
  // One fixed local build target: do not launch simultaneous CLI runs in one checkout.
  writeFileSync(`${root}/.build/benchmark.bend`,source(p));
  const buildStart=performance.now();
  command(bend,['.build/benchmark.bend','-o','.build/benchmark']);
  const buildMs=performance.now()-buildStart;
  const t=performance.now();
  // Explicit GPU memory mode forces gpu_probe failure to be fatal in Bend 2.0.39.
  const output=command(`${root}/.build/benchmark`,['+RTS','--threads',String(p.threads),'--gpu',p.backend==='gpu'?'512MB':'off']);
  const endToEndMs=performance.now()-t;
  const errors=[...output.matchAll(/(?:warmup_)?errors=(\d+)/g)].map(m=>Number(m[1]));
  const samples=[...output.matchAll(/workload_ms=(\d+)/g)].map(m=>Number(m[1]));
  if(errors.length!==p.warmup+p.iterations || errors.some(n=>n!==0) || samples.length!==p.iterations) throw new Error(`Correctness or output check failed:\n${output}`);
  const totalMs=samples.reduce((a,b)=>a+b,0);
  const shards=2**p['fork-depth']; const keys=shards*p.items;
  console.log(JSON.stringify({compiler:version,backend:p.backend,parameters:p,shards,bitsPerShard:32*2**p['word-depth'],keysPerIteration:keys,
    operationsPerIteration:2*keys,falseNegatives:0,buildMs,processWallMs:endToEndMs,warmupIterations:p.warmup,workloadMs:samples,
    operationsPerSecond:totalMs>0 ? Math.round(2*keys*p.iterations*1000/totalMs):null,
    timingNote:'Workload wall time has millisecond resolution and includes allocation, key generation, insertion, query, reduction and one diagnostic print. GPU time includes dispatch/synchronization; isolated kernel time and occupancy are not measured. Process wall time includes warmup and runtime startup, excludes build. Null throughput means below clock resolution.',
    topology:'Independent filters per shard; sequential inserts within each shard. No shared bit writes or single global filter.'},null,2));
}
try {
  const [cmd,...args]=process.argv.slice(2);
  if(cmd==='stats' && args.length===0) console.log(JSON.stringify(stats(),null,2));
  else if(['benchmark','start','run'].includes(cmd)) benchmark(parse(args));
  else if(!cmd || ['--help','help','-h'].includes(cmd)) console.log(help);
  else throw new Error(help);
} catch(e) { console.error(e.message);process.exitCode=1; }
