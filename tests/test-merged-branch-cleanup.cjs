'use strict';

const assert = require('assert');
const {
  evaluateBranch,
  findMergedEvidence,
  isProtectedName,
} = require('../.github/scripts/merged-branch-cleanup.cjs');

const repositoryFullName = 'Lycidias93/pixel-10-pro-xl-thermal-fix';
const mergedPulls = [
  {
    number: 157,
    merged_at: '2026-07-30T12:00:00Z',
    head: {
      ref: 'dev13-runtime-fixes',
      sha: 'aaa111',
      repo: { full_name: repositoryFullName },
    },
    base: { ref: 'v2' },
  },
  {
    number: 158,
    merged_at: '2026-07-30T13:00:00Z',
    head: {
      ref: 'state-refresh-followup',
      sha: 'bbb222',
      repo: { full_name: repositoryFullName },
    },
    base: { ref: 'v2' },
  },
];

assert.strictEqual(isProtectedName('main', 'main'), true);
assert.strictEqual(isProtectedName('v2', 'main'), true);
assert.strictEqual(isProtectedName('release/2.0', 'main'), true);
assert.strictEqual(isProtectedName('feature/cleanup', 'main'), false);

const exactBranch = {
  name: 'dev13-runtime-fixes',
  protected: false,
  commit: { sha: 'aaa111' },
};

assert.strictEqual(
  findMergedEvidence(exactBranch, mergedPulls, repositoryFullName).number,
  157,
);

const baseInput = {
  branch: exactBranch,
  defaultBranch: 'main',
  repositoryFullName,
  openHeadBranches: new Set(),
  openBaseBranches: new Set(),
  mergedPulls,
};

assert.deepStrictEqual(
  evaluateBranch(baseInput),
  {
    action: 'delete',
    reason: 'exact_merged_pr_head_sha',
    pull_number: 157,
    pull_base: 'v2',
    merged_at: '2026-07-30T12:00:00Z',
  },
);

assert.strictEqual(
  evaluateBranch({ ...baseInput, openHeadBranches: new Set(['dev13-runtime-fixes']) }).reason,
  'open_pr_head',
);

assert.strictEqual(
  evaluateBranch({ ...baseInput, openBaseBranches: new Set(['dev13-runtime-fixes']) }).reason,
  'open_pr_base',
);

assert.strictEqual(
  evaluateBranch({ ...baseInput, branch: { ...exactBranch, protected: true } }).reason,
  'github_protected',
);

assert.strictEqual(
  evaluateBranch({
    ...baseInput,
    branch: { name: 'v2', protected: false, commit: { sha: 'aaa111' } },
  }).reason,
  'protected_name',
);

assert.strictEqual(
  evaluateBranch({
    ...baseInput,
    branch: { ...exactBranch, commit: { sha: 'advanced-after-merge' } },
  }).reason,
  'no_exact_merged_pr_evidence',
);

assert.strictEqual(
  evaluateBranch({
    ...baseInput,
    branch: { name: 'fork-head', protected: false, commit: { sha: 'fork123' } },
    mergedPulls: [{
      number: 200,
      merged_at: '2026-07-30T14:00:00Z',
      head: {
        ref: 'fork-head',
        sha: 'fork123',
        repo: { full_name: 'someone-else/fork' },
      },
      base: { ref: 'v2' },
    }],
  }).reason,
  'no_exact_merged_pr_evidence',
);

console.log('RESULT: MERGED_BRANCH_CLEANUP_TEST_PASS');
