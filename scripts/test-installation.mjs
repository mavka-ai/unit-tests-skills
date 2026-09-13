// Smoke-test the public installation commands against the working tree.
// Requires Node.js 22.20+, Git, and npm/network access for the skills CLI.
// Run: node --test scripts/test-installation.mjs
// SKILLS_CLI can point at an already installed skills bin/cli.mjs for offline runs.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, lstatSync, mkdtempSync, readFileSync, readdirSync,
  realpathSync, rmSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const cli = process.env.SKILLS_CLI;

function verifyFiles(source, installed) {
  assert.deepEqual(readdirSync(installed).sort(), readdirSync(source).sort());
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const destination = join(installed, entry.name);
    assert.ok(!lstatSync(destination).isSymbolicLink(), `Bundled file must be local: ${destination}`);
    if (entry.isDirectory()) verifyFiles(join(source, entry.name), destination);
    else assert.deepEqual(readFileSync(destination), readFileSync(join(source, entry.name)));
  }
}

function verifyRuleReferences(installed) {
  const skill = readFileSync(join(installed, 'SKILL.md'), 'utf8');
  const references = [...skill.matchAll(/`([^`\n]+\.md)`/g)]
    .map((match) => match[1]).filter((ref) => ref !== 'SKILL.md');
  assert.ok(references.length > 0, 'Skill must reference its bundled rules');
  for (const ref of references) {
    const candidates = [join(installed, ref), join(installed, 'rules', ref),
      join(installed, 'rules/tests', ref)];
    // Bare names in workflow prose refer to one of the explicit rule paths.
    if (!ref.includes('/')) {
      for (const other of references.filter((path) => path.endsWith(`/${ref}`))) {
        candidates.push(join(installed, other));
      }
    }
    assert.ok(candidates.some((path) => existsSync(path) &&
      realpathSync(path).startsWith(realpathSync(installed) + sep)),
    `Rule must resolve within the installed skill: ${ref}`);
  }
}

for (const skill of ['generate-tests', 'generate-test-cases']) {
  for (const scenario of [
    { name: 'select one skill from collection for Codex and Claude', standalone: false,
      agents: ['codex', 'claude-code'], claude: true },
    { name: 'install standalone for Claude with neutral storage', standalone: true,
      agents: ['universal', 'claude-code'], claude: true },
    { name: 'install standalone for Codex only', standalone: true,
      agents: ['codex'], claude: false },
  ]) {
    test(`${skill}: ${scenario.name}`, () => {
      const work = mkdtempSync(join(tmpdir(), 'unit-tests-install-'));
      try {
        const project = join(work, 'project');
        mkdirSync(project);
        const original = join(root, 'skills', skill);
        let source = root;
        if (scenario.standalone) {
          source = join(work, 'source', skill);
          cpSync(original, source, { recursive: true });
          // The source contains only this skill: no sibling skill or manifests.
          assert.deepEqual(readdirSync(dirname(source)), [skill]);
        }
        const args = ['add', source, '--skill', skill, '--agent', ...scenario.agents, '--yes'];
        try {
          execFileSync(cli ? process.execPath : 'npx',
            cli ? [resolve(cli), ...args] : ['--yes', 'skills', ...args], {
              cwd: project, encoding: 'utf8', timeout: 120_000,
              env: { ...process.env, DISABLE_TELEMETRY: '1' },
            });
        } catch (error) {
          throw new Error(`Installer failed:\n${error.stdout ?? ''}\n${error.stderr ?? ''}`, { cause: error });
        }
        const canonical = join(project, '.agents/skills', skill);
        assert.deepEqual(readdirSync(dirname(canonical)), [skill], 'Only the selected skill is installed');
        assert.ok(!lstatSync(canonical).isSymbolicLink(), 'Canonical directory holds real files');
        verifyFiles(original, canonical);
        verifyRuleReferences(canonical);
        const claude = join(project, '.claude/skills', skill);
        if (scenario.claude) {
          assert.deepEqual(readdirSync(dirname(claude)), [skill]);
          assert.ok(lstatSync(claude).isSymbolicLink(), 'Claude must receive a symlink, not a copy');
          assert.equal(realpathSync(claude), realpathSync(canonical));
        } else {
          assert.ok(!existsSync(join(project, '.claude')), 'Codex-only install must not create Claude files');
        }
      } finally {
        rmSync(work, { recursive: true, force: true });
      }
    });
  }
}
