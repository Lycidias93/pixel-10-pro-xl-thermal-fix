'use strict';

const fs = require('fs');

const DEFAULT_PROTECTED_EXACT = Object.freeze([
  'main',
  'master',
  'v1',
  'v2',
  'dev',
  'develop',
  'development',
  'stable',
  'next',
  'canary',
  'beta',
]);

const DEFAULT_PROTECTED_PREFIXES = Object.freeze([
  'release/',
  'hotfix/',
  'stable/',
  'support/',
  'long-lived/',
]);

function normalizeRepoFullName(value) {
  return String(value || '').trim().toLowerCase();
}

function isProtectedName(name, defaultBranch, extraExact = [], extraPrefixes = []) {
  const candidate = String(name || '').trim();
  if (!candidate) return true;

  const exact = new Set([
    ...DEFAULT_PROTECTED_EXACT,
    String(defaultBranch || '').trim(),
    ...extraExact.map((item) => String(item || '').trim()),
  ].filter(Boolean));

  if (exact.has(candidate)) return true;

  const prefixes = [
    ...DEFAULT_PROTECTED_PREFIXES,
    ...extraPrefixes.map((item) => String(item || '').trim()),
  ].filter(Boolean);

  return prefixes.some((prefix) => candidate.startsWith(prefix));
}

function findMergedEvidence(branch, mergedPulls, repositoryFullName) {
  const repo = normalizeRepoFullName(repositoryFullName);
  const matches = mergedPulls.filter((pull) => {
    if (!pull || !pull.merged_at || !pull.head || !pull.head.repo) return false;
    return normalizeRepoFullName(pull.head.repo.full_name) === repo
      && pull.head.ref === branch.name
      && pull.head.sha === branch.commit.sha;
  });

  matches.sort((left, right) => String(right.merged_at).localeCompare(String(left.merged_at)));
  return matches[0] || null;
}

function evaluateBranch({
  branch,
  defaultBranch,
  repositoryFullName,
  openHeadBranches,
  openBaseBranches,
  mergedPulls,
  extraProtectedExact = [],
  extraProtectedPrefixes = [],
}) {
  if (!branch || !branch.name || !branch.commit || !branch.commit.sha) {
    return { action: 'skip', reason: 'invalid_branch_record' };
  }

  if (branch.protected) {
    return { action: 'skip', reason: 'github_protected' };
  }

  if (isProtectedName(branch.name, defaultBranch, extraProtectedExact, extraProtectedPrefixes)) {
    return { action: 'skip', reason: 'protected_name' };
  }

  if (openHeadBranches.has(branch.name)) {
    return { action: 'skip', reason: 'open_pr_head' };
  }

  if (openBaseBranches.has(branch.name)) {
    return { action: 'skip', reason: 'open_pr_base' };
  }

  const evidence = findMergedEvidence(branch, mergedPulls, repositoryFullName);
  if (!evidence) {
    return { action: 'skip', reason: 'no_exact_merged_pr_evidence' };
  }

  return {
    action: 'delete',
    reason: 'exact_merged_pr_head_sha',
    pull_number: evidence.number,
    pull_base: evidence.base && evidence.base.ref ? evidence.base.ref : null,
    merged_at: evidence.merged_at,
  };
}

function parseCsv(value) {
  return String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

async function cleanup({ github, context, core }) {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const repositoryFullName = `${owner}/${repo}`;
  const receiptPath = process.env.BRANCH_CLEANUP_RECEIPT || 'branch-cleanup-receipt.json';
  const extraProtectedExact = parseCsv(process.env.BRANCH_CLEANUP_PROTECTED_EXACT);
  const extraProtectedPrefixes = parseCsv(process.env.BRANCH_CLEANUP_PROTECTED_PREFIXES);

  const repository = await github.rest.repos.get({ owner, repo });
  const defaultBranch = repository.data.default_branch;

  const branches = await github.paginate(github.rest.repos.listBranches, {
    owner,
    repo,
    per_page: 100,
  });

  const openPulls = await github.paginate(github.rest.pulls.list, {
    owner,
    repo,
    state: 'open',
    per_page: 100,
  });

  const closedPulls = await github.paginate(github.rest.pulls.list, {
    owner,
    repo,
    state: 'closed',
    sort: 'updated',
    direction: 'desc',
    per_page: 100,
  });

  const mergedPulls = closedPulls.filter((pull) => Boolean(pull.merged_at));
  const sameRepo = normalizeRepoFullName(repositoryFullName);
  const openHeadBranches = new Set();
  const openBaseBranches = new Set();

  for (const pull of openPulls) {
    if (pull.head && pull.head.repo && normalizeRepoFullName(pull.head.repo.full_name) === sameRepo) {
      openHeadBranches.add(pull.head.ref);
    }
    if (pull.base && pull.base.repo && normalizeRepoFullName(pull.base.repo.full_name) === sameRepo) {
      openBaseBranches.add(pull.base.ref);
    }
  }

  let candidateNames = null;
  if (context.eventName === 'pull_request') {
    const pull = context.payload.pull_request;
    if (!pull || !pull.merged) {
      candidateNames = new Set();
    } else if (!pull.head || !pull.head.repo || normalizeRepoFullName(pull.head.repo.full_name) !== sameRepo) {
      candidateNames = new Set();
    } else {
      candidateNames = new Set([pull.head.ref]);
    }
  }

  const receipt = {
    schema_version: 1,
    policy: 'GITHUB_POST_MERGE_BRANCH_CLEANUP_POLICY_V1',
    repository: repositoryFullName,
    event_name: context.eventName,
    event_action: context.payload.action || null,
    run_id: context.runId || null,
    default_branch: defaultBranch,
    protected_exact: [...DEFAULT_PROTECTED_EXACT, ...extraProtectedExact],
    protected_prefixes: [...DEFAULT_PROTECTED_PREFIXES, ...extraProtectedPrefixes],
    branch_count: branches.length,
    open_pull_count: openPulls.length,
    merged_pull_count: mergedPulls.length,
    deleted: [],
    skipped: [],
    pending: [],
  };

  for (const branch of branches) {
    if (candidateNames && !candidateNames.has(branch.name)) continue;

    const decision = evaluateBranch({
      branch,
      defaultBranch,
      repositoryFullName,
      openHeadBranches,
      openBaseBranches,
      mergedPulls,
      extraProtectedExact,
      extraProtectedPrefixes,
    });

    const record = {
      branch: branch.name,
      sha: branch.commit.sha,
      reason: decision.reason,
      pull_number: decision.pull_number || null,
      pull_base: decision.pull_base || null,
      merged_at: decision.merged_at || null,
    };

    if (decision.action !== 'delete') {
      receipt.skipped.push(record);
      continue;
    }

    try {
      await github.rest.git.deleteRef({
        owner,
        repo,
        ref: `heads/${branch.name}`,
      });
      receipt.deleted.push(record);
      core.info(`DELETED branch=${branch.name} sha=${branch.commit.sha} pr=${decision.pull_number}`);
    } catch (error) {
      const status = error && error.status ? error.status : null;
      const message = error && error.message ? error.message : String(error);
      receipt.pending.push({ ...record, status, error: message });
      core.warning(`PENDING branch=${branch.name} status=${status || 'unknown'} error=${message}`);
    }
  }

  receipt.summary = {
    deleted: receipt.deleted.length,
    skipped: receipt.skipped.length,
    pending: receipt.pending.length,
  };

  fs.writeFileSync(receiptPath, `${JSON.stringify(receipt, null, 2)}\n`, 'utf8');

  core.setOutput('deleted_count', String(receipt.deleted.length));
  core.setOutput('pending_count', String(receipt.pending.length));
  core.setOutput('receipt_path', receiptPath);

  await core.summary
    .addHeading('Merged branch cleanup')
    .addRaw(`Repository: ${repositoryFullName}\n\n`)
    .addRaw(`Deleted: ${receipt.deleted.length}\n\n`)
    .addRaw(`Skipped: ${receipt.skipped.length}\n\n`)
    .addRaw(`Pending: ${receipt.pending.length}\n`)
    .write();

  core.info(`RESULT: MERGED_BRANCH_CLEANUP_DONE deleted=${receipt.deleted.length} skipped=${receipt.skipped.length} pending=${receipt.pending.length}`);
}

module.exports = cleanup;
module.exports.DEFAULT_PROTECTED_EXACT = DEFAULT_PROTECTED_EXACT;
module.exports.DEFAULT_PROTECTED_PREFIXES = DEFAULT_PROTECTED_PREFIXES;
module.exports.evaluateBranch = evaluateBranch;
module.exports.findMergedEvidence = findMergedEvidence;
module.exports.isProtectedName = isProtectedName;
