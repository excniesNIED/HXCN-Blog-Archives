---
title: "How I Organized 2,098 GitHub Stars with gh CLI and GraphQL"
pubDatetime: 2026-08-01T00:00:00.000+08:00
slug: github-stars-batch-classification-en
tags:
  - GitHub
  - GitHub Star
  - gh CLI
  - GraphQL
  - Automation
  - AI Agent
category: 配置环境的日常
description: "Organize 2,098 GitHub Stars with gh CLI and GraphQL: back up 31 old lists, rebuild 25 categories, batch-assign repos, and verify every count."
---

# How I Organized 2,098 GitHub Stars with gh CLI and GraphQL

I finally got around to something I'd been putting off for a long time: going through all 2098 GitHub stars on my account and sorting them properly.

Stars had been piling up slowly, and so had the Lists: `LLM`, `AIStudy`, `AICollections`, `Benchmark4AI`... Eventually I had **31 of them**, one slot away from the 32-list ceiling. But those 31 lists had a combined total of **89 memberships**. Most starred repos weren't in any list at all. Every new star, I'd think about where to put it, draw a blank, and leave it unsorted.

When it was done, all 25 lists on GitHub matched the local classification file entry by entry — 2098 repos, none missing. The stars themselves were untouched; only the list memberships changed.

> GitHub's help pages still mark Lists as Public Preview, and the API and limits may change. The GraphQL fields, 32-list ceiling, and permission behavior described below reflect what I observed on my personal account on August 1, 2026.

## Why tear everything down and start fresh

`LLM`, `AIStudy`, `AICollections`, and `Benchmark4AI` overlapped badly; I couldn't clearly explain where `WebSrc`, `WebCollections`, and `Blog&Theme` differed from each other. Every new repo meant spending a moment trying to remember why I'd created each list in the first place, then making a best guess about where it belonged — and often getting it wrong, or just skipping it entirely. After a while, new stars stopped getting sorted at all, and the lists were just a pile of names.

There's also the ceiling. GitHub Lists max out at 32 on my account, and I was already using 31 of them. There was no room to gradually build 25 new lists alongside the old ones and migrate. The only path was: backup, delete everything, rebuild.

A rule like "group by project type" isn't enough either. A single repo can simultaneously be frontend, AI, and a developer tool. Without a fixed priority order, different batches — or different runs of the same batch — produce different classifications.

So I split it into two passes: the first pass just reads repos and figures out what each one does; the second pass classifies. It's slower, but you won't hit repo 1,500 and realize the criteria you used for the first 500 don't match the last 500, forcing a full restart.

## The 25 categories

| Category | Count | Category | Count |
|---|---:|---|---:|
| Information | 327 | AI & LLM | 204 |
| Applications and Tools | 171 | Frontend | 159 |
| Blog & Website | 158 | Agent | 129 |
| Developer Tools | 88 | Media | 79 |
| Desktop Customization | 78 | Windows | 77 |
| Office | 68 | Platforms and Services | 65 |
| Network & Proxy | 60 | Android & Mobile | 55 |
| AI Generation | 53 | Libraries and Frameworks | 52 |
| SRE | 44 | Design & Visual | 42 |
| OS & Kernel | 36 | Security | 35 |
| Notes & Markdown | 30 | Minecraft | 27 |
| Backend | 24 | Games | 20 |
| Robotics | 17 | Total | **2098** |

The nine broad categories I started with as a reference weren't nearly enough. Once I'd actually scanned the distribution, it was clear that applications, AI tooling, network utilities, and informational resources each numbered in the dozens or hundreds. Forcing them into broader buckets would just recreate the old problem. Twenty-five categories stays under the 32-list cap and leaves room to adjust later.

## Stars are REST; Lists are GraphQL-only

This is the part most likely to trip you up, so it's worth being explicit.

You fetch starred repos via REST:

```text
GET /user/starred
```

There's no REST endpoint for Lists. I tried `/user/starred_lists` and got a 404 straight away. Creating, deleting, querying, and updating memberships all go through GraphQL. The fields used here:

```text
viewer.lists
createUserList
deleteUserList
updateUserList
updateUserListsForItem
```

Three distinct IDs are in play — don't confuse them:

- The repo's REST integer ID, e.g. `1299334645`. Good as a local mapping key.
- The repo's GraphQL Node ID, e.g. `R_kgDOTXJF9Q`. This goes into `itemId` when adding to a list.
- The list's GraphQL ID, e.g. `UL_...`. This goes into `listIds`.

`updateUserListsForItem` replaces, it doesn't append. The `listIds` you pass in represent the complete set of lists the repo should end up in. One list per repo is straightforward; if you want a repo in multiple lists, you need to pass all the target IDs at once — you can't add them one by one.

Also: deleting a List doesn't unstar any repos. It just removes the list name and its membership data. Make sure the backup is complete and not just sitting in `/tmp` before you delete anything.

## Setting up gh CLI and the right permissions

Start by confirming the account and scopes are right:

```bash
gh --version
gh auth status
```

If you're not logged in:

```bash
gh auth login
```

Pulling stars worked fine, but the first time I tried a Lists mutation, GraphQL came back with `INSUFFICIENT_SCOPES` — the token didn't have the `user` scope. Fix it with:

```bash
gh auth refresh -s user
```

`gh auth refresh` opens the browser and walks you through the device flow, printing a one-time code valid for 15 minutes. If you have multiple accounts, run `gh auth switch` first.

If the device flow keeps stalling, generate a classic PAT with the `user` scope at [settings/tokens](https://github.com/settings/tokens) and import it this way — no PAT left in shell history:

```bash
read -rsp 'GitHub PAT: ' GH_PAT
printf '%s' "$GH_PAT" | gh auth login --with-token
unset GH_PAT
```

If you created a temporary PAT specifically for this, revoke it at <https://github.com/settings/tokens> once you're done.

## Take a fixed snapshot of your stars

Don't work in a temp directory. I'll get to this in a moment, but my first backup script wrote to a session temp directory, the environment reset, and the files vanished. Use `~/stars-work` directly:

```bash
mkdir -p ~/stars-work
cd ~/stars-work

gh api '/user/starred?per_page=100' \
  --paginate \
  --jq '.[]' > stars.jsonl

wc -l stars.jsonl
```

Output this time:

```text
2098 stars.jsonl
```

`stars.jsonl` is JSON Lines — one full repo object per line. The fields you'll actually use for classification:

```text
id
node_id
full_name
description
language
topics
```

You can also generate a TSV that's easier to read by eye or feed to a model:

```bash
jq -r '[
  .id,
  .node_id,
  .full_name,
  (.description // ""),
  (.language // ""),
  ((.topics // []) | join(","))
] | @tsv' stars.jsonl > stars.tsv
```

### Why `-f per_page=100` gives you a 404

My first attempt was:

```bash
gh api /user/starred -f per_page=100
```

That came back 404. The problem isn't the pagination parameter — it's that adding any `-f` or `-F` flag causes `gh api` to switch the request method to POST. The `/user/starred` listing endpoint only accepts GET.

Two ways to get it right:

```bash
# Inline query string — most straightforward
gh api '/user/starred?per_page=100'

# Or explicitly force GET
gh api -X GET /user/starred -f per_page=100
```

This behavior is documented in the `gh api` manual. The first time I hit the 404 I spent a while chasing the wrong leads — wrong endpoint, wrong permissions — before finding the real cause.

## Back up your lists completely before deleting anything

The script below backs up list names, descriptions, list IDs, and the full repo membership of each list. `items` uses cursor pagination so nothing gets cut off if a list has more than 100 items.

```bash
cat > backup_lists.py <<'PY'
import json
import subprocess
from pathlib import Path


def gql(query, **variables):
    cmd = ["gh", "api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        if value is not None:
            cmd.extend(["-f", f"{key}={value}"])

    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    body = json.loads(proc.stdout)
    if body.get("errors"):
        raise RuntimeError(json.dumps(body["errors"], ensure_ascii=False))
    return body["data"]


lists_query = r'''
query {
  viewer {
    lists(first: 100) {
      nodes { id name description }
    }
  }
}
'''

items_query = r'''
query($listId: ID!, $cursor: String) {
  node(id: $listId) {
    ... on UserList {
      items(first: 100, after: $cursor) {
        nodes {
          ... on Repository { id nameWithOwner }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
'''

lists = gql(lists_query)["viewer"]["lists"]["nodes"]
backup = []

for user_list in lists:
    cursor = None
    repositories = []

    while True:
        connection = gql(
            items_query,
            listId=user_list["id"],
            cursor=cursor,
        )["node"]["items"]

        repositories.extend(item for item in connection["nodes"] if item)
        page = connection["pageInfo"]
        if not page["hasNextPage"]:
            break
        cursor = page["endCursor"]

    backup.append({
        **user_list,
        "repositories": repositories,
    })

path = Path.home() / "stars-backup" / "old-lists-backup.json"
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(
    json.dumps(backup, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
print(f"saved {len(backup)} lists to {path}")
PY

python3 backup_lists.py
jq -r '.[] | [.name, (.repositories | length)] | @tsv' \
  ~/stars-backup/old-lists-backup.json
```

The `items.nodes` field on a UserList is a union type. When querying repo-specific fields you have to write:

```graphql
... on Repository { id nameWithOwner }
```

Accessing repo fields directly under `nodes` without this inline fragment triggers `selectionMismatch`.

I actually stepped into a worse version of this problem: my first backup only wrote to a temporary working directory. When the session later reset, the files were wiped. The list names were still visible on GitHub, but the 89 historical memberships were gone for good. The new system already covers all 2098 repos so the final result wasn't affected, but I lost my rollback safety net.

So the version above writes directly to `~/stars-backup/old-lists-backup.json`. Before deleting anything, open the file manually and confirm that the list count, membership count, and file path all look right.

## Figure out what you've actually starred

Throwing all 2098 repos at a model at once doesn't work: the first batch gets categorized carefully, then quality degrades, category names start drifting, and a huge chunk of everything ends up in a catch-all Misc.

I split `stars.jsonl` into 8 batches and ran them in parallel. The first pass asked only two things per repo: what does it primarily do, and what broad categories does this batch point to? `description + language + topics` is usually enough. For repos with missing or ambiguous descriptions, pull the README:

```bash
gh api repos/OWNER/REPO/readme \
  -H 'Accept: application/vnd.github.raw+json'
```

Once all eight batches were done I combined the results: Information came to 327, AI & LLM to 204, blog/site-related repos to 158. Minecraft and Robotics were small in absolute terms, but their domain boundaries are so clear that having them as dedicated categories makes things much easier to find than lumping them into Applications. Those numbers are what drove the granularity decisions — not intuition.

The second pass maps every repo to a final category, with a fixed output format:

```json
{
  "repo REST integer ID": "category name"
}
```

For example:

```json
{
  "1299334645": "Minecraft",
  "268690468": "Agent"
}
```

Using the integer ID as the key is intentional — if a repo gets renamed or transferred to a different owner, `full_name` changes, but the ID doesn't. When writing to Lists, look up the corresponding `node_id` from `stars.jsonl`.

## Lock the classification boundaries in a file

Twenty-five names listed out isn't enough. The hard part is the boundaries — is this repo AI & LLM or Agent? SRE or Network & Proxy? Without a fixed rule, a future run (or future me) will reach a different answer.

I wrote an `AGENTS.md` in the backup directory covering:

- Decision order (top-to-bottom, first match wins);
- Description and inclusion criteria for each category;
- Counterexamples and commonly confused boundaries;
- The incremental command for filing new stars.

The first several entries in the decision order:

```text
Minecraft
Robotics
Agent
AI Generation
AI & LLM
Frontend
Notes & Markdown
Office
Blog & Website
Information
...
Applications and Tools (catch-all, last resort)
```

The order directly affects outcomes. For example:

| What it is | Category |
|---|---|
| LLM API bridge or gateway | AI & LLM |
| Personal proxy client (e.g. Clash) | Network & Proxy |
| Server-side reverse proxy, mirror service | SRE |
| OCR model or engine | AI & LLM |
| OCR end-user application | Office |
| Media player app | Media |
| Media player library | Libraries and Frameworks |
| Tutorial, book, Awesome list | Information |
| Autonomous AI agent | Agent |
| Image / video / speech generation | AI Generation |

This file isn't meant to be polished. If the rules only live in your head, the next time is basically starting over.

## Validate classification.json before writing

Start by building an allowlist of category names:

```bash
cat > categories.txt <<'EOF'
Minecraft
AI & LLM
Agent
AI Generation
Robotics
Backend
Frontend
Notes & Markdown
Office
Blog & Website
Information
Security
SRE
OS & Kernel
Platforms and Services
Media
Network & Proxy
Windows
Android & Mobile
Desktop Customization
Design & Visual
Games
Libraries and Frameworks
Developer Tools
Applications and Tools
EOF
```

Then check for missing repos, extra IDs that don't match any star, and misspelled category names:

```bash
python3 - <<'PY'
import json
from pathlib import Path

stars = [json.loads(line) for line in Path("stars.jsonl").read_text().splitlines()]
classification = json.loads(Path("classification.json").read_text())
categories = set(Path("categories.txt").read_text().splitlines())

star_ids = {str(repo["id"]) for repo in stars}
classified_ids = set(classification)
used_categories = set(classification.values())

missing = sorted(star_ids - classified_ids)
extra = sorted(classified_ids - star_ids)
invalid = sorted(used_categories - categories)

print("stars:", len(star_ids))
print("classified:", len(classified_ids))
print("missing:", len(missing), missing[:10])
print("extra:", len(extra), extra[:10])
print("invalid categories:", invalid)

if missing or extra or invalid:
    raise SystemExit(1)
PY
```

Output this run:

```text
stars: 2098
classified: 2098
missing: 0 []
extra: 0 []
invalid categories: []
```

Don't force confusing repos into the catch-all category. During the classification pass, it's fine to output `UNKNOWN` and resolve each one individually at the end using the README. I cross-checked both passes, clearing out obvious misfiled repos and all `UNKNOWN` entries before touching anything on GitHub.

## Delete the 31 old lists, then create 25 new ones

This is the one stage that can't be casually rerun. First, confirm the backup isn't empty:

```bash
jq 'length' ~/stars-backup/old-lists-backup.json
jq '[.[].repositories | length] | add' \
  ~/stars-backup/old-lists-backup.json
```

Once everything looks right, set the explicit delete flag:

```bash
export CONFIRM_DELETE_LISTS=yes

python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

if os.environ.get("CONFIRM_DELETE_LISTS") != "yes":
    raise SystemExit("set CONFIRM_DELETE_LISTS=yes first")

backup = json.loads(
    (Path.home() / "stars-backup" / "old-lists-backup.json").read_text()
)
mutation = r'''
mutation($listId: ID!) {
  deleteUserList(input: {listId: $listId}) {
    clientMutationId
  }
}
'''

for user_list in backup:
    proc = subprocess.run(
        [
            "gh", "api", "graphql",
            "-f", f"query={mutation}",
            "-f", f"listId={user_list['id']}",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    body = json.loads(proc.stdout)
    if body.get("errors") or body["data"]["deleteUserList"] is None:
        raise RuntimeError(json.dumps(body, ensure_ascii=False))
    print("deleted", user_list["name"])
PY

unset CONFIRM_DELETE_LISTS
```

Then create the new lists from `categories.txt` and save the category-name-to-list-ID mapping:

```bash
python3 - <<'PY'
import json
import subprocess
from pathlib import Path

mutation = r'''
mutation($name: String!) {
  createUserList(input: {name: $name}) {
    list { id name }
  }
}
'''

created = {}
for name in Path("categories.txt").read_text().splitlines():
    proc = subprocess.run(
        [
            "gh", "api", "graphql",
            "-f", f"query={mutation}",
            "-f", f"name={name}",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    body = json.loads(proc.stdout)
    if body.get("errors"):
        raise RuntimeError(json.dumps(body["errors"], ensure_ascii=False))
    user_list = body["data"]["createUserList"]["list"]
    created[user_list["name"]] = user_list["id"]
    print("created", user_list["name"])

Path("new-lists.json").write_text(
    json.dumps(created, ensure_ascii=False, indent=2) + "\n"
)
PY
```

### Why a missing `query=` silently swallows the error

My first mutation looked like:

```bash
gh api graphql -f 'mutation { createUserList(...) { ... } }'
```

`-f` requires `key=value` format, and the GraphQL text must go into a field literally named `query`. The correct form is:

```bash
gh api graphql -f 'query=mutation { ... }'
```

The wrong form fails at the `gh` CLI argument-parsing layer — the request never reaches GraphQL at all. So there's no `errors` field in the output. If your script checks for `"errors"` to detect failures, these CLI-level errors all look like successes.

A batch script should check the process exit code, whether the output is valid JSON, and whether the target `data` field is actually populated.

## File 2098 repos into their lists

First, join the REST IDs, repo Node IDs, and target list IDs together:

```bash
python3 - <<'PY'
import json
from pathlib import Path

stars = {
    str(repo["id"]): repo
    for repo in map(json.loads, Path("stars.jsonl").read_text().splitlines())
}
classification = json.loads(Path("classification.json").read_text())
list_ids = json.loads(Path("new-lists.json").read_text())

with Path("assign.tsv").open("w", encoding="utf-8") as output:
    for repo_id, category in classification.items():
        output.write(f'{stars[repo_id]["node_id"]}\t{list_ids[category]}\n')
PY

wc -l assign.tsv
```

Output should be 2098 lines.

The function below sends one mutation per repo, 4-way parallel. It backs off incrementally on rate-limit responses and logs other errors immediately:

```bash
: > assign-errors.log

assign_one() {
  local node="$1"
  local list_id="$2"
  local out
  local attempt

  for attempt in 1 2 3 4 5 6; do
    if out=$(gh api graphql -f "query=mutation {
      updateUserListsForItem(
        input: {itemId: \"$node\", listIds: [\"$list_id\"]}
      ) { clientMutationId }
    }" 2>&1) && printf '%s' "$out" | jq -e '
      .data.updateUserListsForItem != null and
      ((.errors // []) | length == 0)
    ' >/dev/null; then
      return 0
    fi

    case "$out" in
      *RATE_LIMITED*|*"rate limit"*|*secondary*)
        sleep $((attempt * 20))
        ;;
      *)
        printf '%s\t%s\t%.200s\n' "$node" "$list_id" "$out" \
          >> assign-errors.log
        return 1
        ;;
    esac
  done

  printf '%s\t%s\trate limit retries exhausted\n' "$node" "$list_id" \
    >> assign-errors.log
  return 1
}

export -f assign_one
xargs -n 2 -P 4 bash -c 'assign_one "$1" "$2"' _ < assign.tsv

wc -l assign-errors.log
```

I didn't push the concurrency higher. GraphQL quota, secondary rate limits, and account state can all shift, and `-P 4` is fast enough while being much easier to diagnose when something goes wrong. Before running, check your current rate limit:

```bash
gh api graphql -f 'query=query {
  rateLimit { cost remaining resetAt }
}'
```

### `-F 'listIds=["UL_xxx"]'' is not an array

Another real mistake was treating a JSON-looking string as a GraphQL array variable:

```bash
-F 'listIds=["UL_xxx"]'
```

The server receives the string `['UL_xxx']` and reports that it can't resolve the corresponding Global ID.

This doesn't mean `-F` can't pass arrays — the `gh api` manual specifies that array fields take the repeated `key[]=value` form. Since every repo in this run belongs to exactly one list, inlining a single list ID directly into the mutation literal is simpler, and it worked completely.

## Verifying by total count alone isn't enough

If you only check that "25 lists add up to 2098", it's entirely possible for the total to be right while two categories are off by the same amount in opposite directions. Verification needs to compare each category individually.

```bash
cat > verify_lists.py <<'PY'
import json
import subprocess
from collections import Counter
from pathlib import Path

classification = json.loads(Path("classification.json").read_text())
expected = dict(Counter(classification.values()))

query = r'''
query {
  viewer {
    lists(first: 100) {
      nodes { name items { totalCount } }
    }
  }
}
'''

proc = subprocess.run(
    ["gh", "api", "graphql", "-f", f"query={query}"],
    check=True,
    capture_output=True,
    text=True,
)
body = json.loads(proc.stdout)
if body.get("errors"):
    raise RuntimeError(json.dumps(body["errors"], ensure_ascii=False))

actual = {
    node["name"]: node["items"]["totalCount"]
    for node in body["data"]["viewer"]["lists"]["nodes"]
}

all_names = sorted(set(expected) | set(actual))
failed = False
for name in all_names:
    want = expected.get(name, 0)
    got = actual.get(name, 0)
    status = "OK" if want == got else "DIFF"
    print(f"{status}\t{name}\texpected={want}\tactual={got}")
    failed |= want != got

matched = sum(expected[name] == actual.get(name) for name in expected)
print(f"matched categories: {matched}/{len(expected)}")
print("expected total:", sum(expected.values()))
print("actual total:", sum(actual.values()))

if failed or set(actual) != set(expected) or sum(actual.values()) != len(classification):
    raise SystemExit(1)
PY

python3 verify_lists.py
```

Final output this run — 25 lines, all OK:

```text
matched categories: 25/25
expected total: 2098
actual total: 2098
```

I also spot-checked a few lists directly on GitHub, confirming the repo names matched the local `by-category/*.md` files. Scripts verify counts; manual spot-checks verify the actual contents. Both need to pass.

## One more star appeared while writing this

The batch classification used a fixed snapshot of 2098 repos. When I re-queried `/user/starred` while writing this article, the live count had already become **2099**, while the 25 lists still totaled 2098. One star was added after the snapshot was taken, and it's not in the original `stars.jsonl` or `classification.json`.

This isn't a missed repo from the original run — the data just kept growing after the batch job finished. It's a good illustration of why verification needs to reference a snapshot timestamp, and why the classification rubric needs to support incremental maintenance.

To find repos added after the snapshot:

```bash
jq -r '.id' stars.jsonl | sort -n > snapshot.ids

gh api '/user/starred?per_page=100' \
  --paginate \
  --jq '.[].id' | sort -n > current.ids

comm -13 snapshot.ids current.ids
```

For each new repo, read its metadata, pick a category from `AGENTS.md`, and fire one mutation — no need to rerun all 2098:

```bash
gh api graphql -f 'query=mutation {
  updateUserListsForItem(
    input: {
      itemId: "R_REPO_NODE_ID"
      listIds: ["UL_TARGET_LIST_ID"]
    }
  ) { clientMutationId }
}'
```

Then update `stars.jsonl`, `classification.json`, the per-category listing files, and the count overview.

## Where the time actually went

GraphQL mutations aren't complicated in themselves, but a few details are genuinely hard to guess.

The interface and permission split trips most people first. Stars go through REST; Lists only go through GraphQL — they're completely separate. I tried `/user/starred_lists` immediately and got a 404. Being able to pull stars successfully doesn't mean a mutation will have permission either — writing to Lists requires the `user` scope, `repo` scope isn't enough, and GraphQL will respond with `INSUFFICIENT_SCOPES`.

Then there are the `gh api` quirks. Adding any `-f` flag switches the request method to POST; the `/user/starred` GET endpoint with `-f per_page=100` tacked on returns 404 — inline the query string instead. GraphQL text must go into a field named `query=`; writing `-f 'mutation {...}'` fails in the CLI argument-parsing layer with no `errors` field in the output — if your script checks for `"errors"` to detect failures, these all silently look like successes. `-F 'listIds=["UL_xxx"]'` looks like a JSON array but arrives at the server as a string, which can't be resolved as a Global ID.

`UserList.items.nodes` is a union type; reading repo-specific fields directly triggers `selectionMismatch` unless you add `... on Repository`. `updateUserListsForItem` replaces, not appends — passing one list ID means "this repo belongs to exactly this one list", not "add it to this list".

I actually lost a backup once. The first script wrote to a session temp directory, the environment reset, and the files were gone — 89 old list memberships, unrecoverable. The new system covers all 2098 repos so the final result wasn't affected, but the rollback safety net was gone.

Don't verify by total count only. Two categories can be off by the same amount in opposite directions and still sum to 2098. This run compared expected/actual per category, and all 25 had to pass.

Stars keep accumulating during a batch job. The batch only verifies the fixed snapshot; new stars go through the incremental path. By the time I finished writing this, the live count was already 2099.

The backup directory now holds the full star snapshot, a REST ID to Node ID mapping, 2098 classification entries, 25 per-category listing files, and `AGENTS.md`. The next time a new star comes in: check the rubric, fire one mutation, update the local files. Done.

## References

- [GitHub Docs: Saving repositories with stars](https://docs.github.com/en/get-started/exploring-projects-on-github/saving-repositories-with-stars)
- [GitHub CLI Manual: gh api](https://cli.github.com/manual/gh_api)
- [GitHub CLI Manual: gh auth refresh](https://cli.github.com/manual/gh_auth_refresh)
- [GitHub GraphQL API: Mutations](https://docs.github.com/en/graphql/reference/mutations)
