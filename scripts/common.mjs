import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
export const root = fileURLToPath(new URL('../', import.meta.url));
export const bend = process.env.BEND || resolve(root, '.tools/bend/bin/bend');
export function command(executable, args, options = {}) {
  const r = spawnSync(executable, args, {cwd: root, encoding: 'utf8', timeout: 120000,
    maxBuffer: 4 * 1024 * 1024, env: {...process.env, BEND_NO_TELEMETRY: '1'}, ...options});
  if (r.error || r.status !== 0) throw new Error(`${executable}: ${r.error?.message || r.stderr || r.stdout || `exit ${r.status}`}`);
  return r.stdout.trim();
}
export function checkVersion() {
  const version = command(bend, ['version']);
  if (!/\b2\.0\.39\b/.test(version)) throw new Error(`Expected Bend 2.0.39; got ${version}`);
  return version;
}
