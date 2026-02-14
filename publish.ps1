# publish.ps1 — build Hugo site into /docs and push to GitHub Pages
# Run from the repo root: C:\hugo\ccllee

$ErrorActionPreference = "Stop"

function Run($cmd) {
  Write-Host ">> $cmd" -ForegroundColor Cyan
  iex $cmd
}

# Ensure we're in a git repo
Run "git rev-parse --is-inside-work-tree | Out-Null"

# Ensure we're on main (avoids detached HEAD surprises)
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main") {
  Write-Host "You are on branch '$branch'. Switching to 'main'..." -ForegroundColor Yellow
  Run "git switch main"
}

# Make sure there isn't an unfinished rebase/merge
$status = git status --porcelain=v1
$rebaseMergePath = Join-Path (git rev-parse --git-dir) "rebase-merge"
$rebaseApplyPath = Join-Path (git rev-parse --git-dir) "rebase-apply"
if ((Test-Path $rebaseMergePath) -or (Test-Path $rebaseApplyPath)) {
  throw "It looks like a rebase is in progress. Finish it (git rebase --continue) or abort (git rebase --abort) then rerun."
}

# Build to docs/
Run "hugo --destination docs --cleanDestinationDir"

# Stage changes
Run "git add -A"

# Commit only if there are staged changes
$staged = git diff --cached --name-only
if ([string]::IsNullOrWhiteSpace($staged)) {
  Write-Host "No changes to commit. (Already up to date.)" -ForegroundColor Green
} else {
  $msg = "Publish site " + (Get-Date -Format "yyyy-MM-dd HH:mm")
  Run "git commit -m `"$msg`""
}

# Pull (rebase) then push
Run "git pull --rebase"
Run "git push"

Write-Host "`nDone. Your site should update shortly." -ForegroundColor Green
