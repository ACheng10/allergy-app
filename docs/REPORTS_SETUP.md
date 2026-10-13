# In-app problem reports, diagnosed by Claude

ELI5: the app drops a note in a letterbox (the worker), the letterbox turns it into a GitHub issue, Claude reads the issue and the code and writes back "here are three ways to fix it", you pick one from your phone, and Claude makes the change for you to approve.

```
iPhone app ──POST──▶ Cloudflare Worker ──▶ GitHub issue (label: user-report)
                                               │
                         Claude diagnoses ◀────┘
                         comments 2–3 options
                                               │
           you reply "@claude option 2" ───────┘
                         Claude opens a PR ──▶ you review and merge
```

Running cost: $0 with your Claude Pro plan, GitHub Actions' free minutes, and Cloudflare's free Workers plan. Claude runs count against your Pro usage limits.

## One-time setup (about 30 minutes)

### 1. Make the repo private
Reports are health information. GitHub > repo > **Settings** > scroll to **Danger Zone** > **Change visibility** > Private.

### 2. Let Claude run in GitHub
1. Install the Claude GitHub app on this repo: https://github.com/apps/claude
2. On your Mac, install Claude Code if you haven't (see https://docs.anthropic.com/en/docs/claude-code), then run `claude setup-token` and copy the token it prints.
3. GitHub > repo > **Settings** > **Secrets and variables** > **Actions** > **New repository secret**. Name `CLAUDE_CODE_OAUTH_TOKEN`, value the token.
4. GitHub > repo > **Issues** > **Labels** > **New label** named `user-report`.

Test it: create an issue yourself, add the `user-report` label while creating it, and write "The Emergency tab shows the wrong number for Italy". Within a few minutes Claude should comment with options.

### 3. Deploy the worker (the letterbox)
1. Make a free account at https://dash.cloudflare.com
2. GitHub > your profile picture > **Settings** > **Developer settings** > **Fine-grained tokens** > **Generate new token**. Repository access: only `allergy-app`. Permissions: **Issues: Read and write**. Copy it.
3. In Terminal:

   ```
   cd allergy-app/reports-worker
   npx wrangler login
   npx wrangler secret put GITHUB_TOKEN     # paste the fine-grained token
   npx wrangler secret put APP_KEY          # type any long random string
   npx wrangler deploy
   ```

   `deploy` prints a URL like `https://allergy-card-reports.yourname.workers.dev`.

### 4. Point the app at it
In `AllergyApp/AllergyApp/Models/ProblemReport.swift` set:

```swift
static let endpoint: URL? = URL(string: "https://allergy-card-reports.yourname.workers.dev/report")
static let appKey = "the same random string you used for APP_KEY"
```

Run the app, go to **Profile > Report a problem**, and send a test.

## Using it
- Turn on GitHub notifications on your phone (GitHub app > Settings > Notifications) so new reports and Claude's options reach you.
- Reply on the issue with `@claude option 2` (or anything more specific). Only your own comments trigger a fix.
- Claude pushes a branch and links a pull request. Merge it from the GitHub app if CI is green.

## Safety notes
- Report text is treated as untrusted. In the diagnose step Claude can only read code and comment; it cannot change anything. Changes only happen after your reply.
- The `APP_KEY` sits inside the app, so it's not truly secret. It only blocks random web traffic. If spam appears, rotate it and add Cloudflare rate limiting.
- Never let the automation mark a translation as `human_reviewed`; that is your reviewers' job.
