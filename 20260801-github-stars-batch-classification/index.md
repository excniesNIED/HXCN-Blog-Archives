---
title: GitHub Star 批量分类：gh CLI 一键搞定 2098 个仓库！
pubDatetime: 2026-08-01T00:00:00.000+08:00
slug: github-stars-batch-classification
tags:
  - GitHub
  - GitHub Star
  - gh CLI
  - GraphQL
  - 自动化
  - AI Agent
category: 配置环境的日常
description: 用 gh CLI 和 GitHub GraphQL 批量分类 2098 个 Star：备份 31 个旧列表，重建 25 个 Lists，并记录权限、分页、静默失败与逐分类核验。
---

# GitHub Star 批量分类：gh CLI 一键搞定 2098 个仓库！

这次干了件积压了很久的事：把账号里 2098 个 GitHub Star 重新分了一遍类。

Star 是慢慢堆起来的，Lists 也跟着越建越多：`LLM`、`AIStudy`、`AICollections`、`Benchmark4AI`……最后搞出 **31 个**，离 32 的上限就差一个坑位。但这 31 个列表加起来只有 **89 条成员关系**，大多数 Star 根本没进任何列表。每次新收藏，想不清楚该往哪里放，干脆就放着不管了。

做完之后，GitHub 上 25 个列表和本地分类文件逐项对上，2098 个没有漏的。Star 本身一个没动，换掉的只是 Lists 里的归属关系。

> GitHub 官方帮助页目前仍把 Lists 标记为 Public Preview，接口和限制以后可能调整。下面的 GraphQL 字段、32 个列表上限和权限表现，均为 2026 年 8 月 1 日在个人账号上的实测结果。

## 旧列表为什么要全部删掉重建

`LLM`、`AIStudy`、`AICollections`、`Benchmark4AI` 四个分类严重重叠，`WebSrc`、`WebCollections`、`Blog&Theme` 的边界我自己也说不清。每次收藏新仓库，都要先想一遍当初为什么建这个列表，再决定放哪里——想了半天经常还是放错，或者干脆跳过不放。久了之后，新 Star 基本不分类，列表只剩一堆名字。

再一个问题是上限。GitHub Lists 在这个账号上最多 32 个，旧列表已经用了 31 个，没位置在旁边慢慢建 25 个新列表再迁移，只能先把旧的备份、删干净，再重建。

分类规则也不能只有一句"按项目类型分组"。同一个仓库可能同时是前端、AI 和开发者工具，不定好命中顺序，换一批仓库处理就会给出不同的分类。

所以分了两轮做：第一轮只读仓库，把每个仓库是什么搞清楚；第二轮再归类。慢了一些，但不用在处理到第 1500 个时发现前面的标准对不上后面，然后全推翻重来。

## 完成后的 25 类

| 分类 | 数量 | 分类 | 数量 |
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
| Robotics | 17 | 合计 | **2098** |

最开始参考的九个大类远远不够。真正扫完仓库分布才知道，应用、AI、网络工具、内容资源每一块都有几十上百个，硬塞在一起只会重演旧问题。25 类还在 32 个上限以内，也留了余量以后调整。

## Star 用 REST，Lists 只能走 GraphQL

这是最容易搞混的部分，下面拆开说一下。

收藏仓库用 REST 拉取：

```text
GET /user/starred
```

Lists 没有 REST 端点，我试过 `/user/starred_lists`，直接 404。创建、删除、查询和成员更新全部只能走 GraphQL，当前用到的字段：

```text
viewer.lists
createUserList
deleteUserList
updateUserList
updateUserListsForItem
```

这里有三种 ID，别混：

- 仓库 REST 数字 ID，例如 `1299334645`，适合作为本地映射键。
- 仓库 GraphQL Node ID，例如 `R_kgDOTXJF9Q`，加入列表时传给 `itemId`。
- 列表 GraphQL ID，例如 `UL_...`，传给 `listIds`。

`updateUserListsForItem` 不是追加，是替换——传进去的 `listIds` 是该仓库最终属于的完整集合。每个仓库只进一个列表时没问题；要一个仓库进多个列表，就必须把全部目标 ID 一次传进去，不能一条一条加。

另外，删掉一个 List 不会取消仓库的 Star，但列表名称和成员关系一起消失了。备份要在删除之前做好，而且不能只放在 `/tmp`。

## 准备 gh CLI 和权限

先确认账号和 scope 都对：

```bash
gh --version
gh auth status
```

未登录时直接运行：

```bash
gh auth login
```

拉 Star 没问题，到写 Lists 的 mutation 时，GraphQL 直接返回 `INSUFFICIENT_SCOPES`——当前 token 没有 `user` scope。补一下：

```bash
gh auth refresh -s user
```

`gh auth refresh` 会开浏览器走设备流，打印一个 15 分钟有效的一次性验证码。有多个账号时，先 `gh auth switch` 再刷新。

设备流反复卡时，直接去 [settings/tokens](https://github.com/settings/tokens) 生成一个带 `user` scope 的 classic PAT，用下面方式导入，不会把 PAT 留在 shell history 里：

```bash
read -rsp 'GitHub PAT: ' GH_PAT
printf '%s' "$GH_PAT" | gh auth login --with-token
unset GH_PAT
```

如果为了这次操作临时创建了 PAT，用完后应到 <https://github.com/settings/tokens> 吊销。

## 固定一份 Star 快照

不要在临时目录工作。后面会提到，我第一版备份脚本输出到了会话临时目录，环境重置后文件没了。直接用 `~/stars-work`：

```bash
mkdir -p ~/stars-work
cd ~/stars-work

gh api '/user/starred?per_page=100' \
  --paginate \
  --jq '.[]' > stars.jsonl

wc -l stars.jsonl
```

本次输出：

```text
2098 stars.jsonl
```

`stars.jsonl` 是 JSON Lines，每行一个完整仓库对象。分类时主要读取这些字段：

```text
id
node_id
full_name
description
language
topics
```

可以再生成一份便于人工和模型阅读的 TSV：

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

### `-f per_page=100` 为什么会 404

我一开始写的是：

```bash
gh api /user/starred -f per_page=100
```

结果返回 404。原因不是分页参数有问题，而是 `gh api` 在加入 `-f` 或 `-F` 参数后会默认把请求方法切换为 `POST`；`/user/starred` 的列表端点需要 `GET`。

两种正确写法：

```bash
# 写进 query string，最直观
gh api '/user/starred?per_page=100'

# 或显式指定 GET
gh api -X GET /user/starred -f per_page=100
```

这个行为在 `gh api` 官方手册里有说明。第一次看到 404 时，我把排查方向放在 endpoint 和权限上，浪费了不少时间。

## 删除之前，完整备份旧 Lists

下面的脚本会备份列表名称、描述、列表 ID，以及列表里的全部仓库成员。`items` 做了游标分页，不会在单个列表超过 100 项时截断。

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

列表的 `items.nodes` 是联合类型。查询仓库字段时必须写：

```graphql
... on Repository { id nameWithOwner }
```

直接在 `nodes` 下面读取仓库专属字段会触发 `selectionMismatch`。

这一步我实际踩过一个更严重的坑：第一版备份只放在临时工作目录，后续会话重置时文件被清理，31 个旧列表的名称还在，89 条历史成员关系却没能保留下来。新体系已经覆盖全部 2098 个仓库，所以最终分类没有受影响，但回滚安全网确实丢了。

因此上面的版本直接写到 `~/stars-backup/old-lists-backup.json`。删除前还要人工打开一次，确认列表数量、成员数量和文件位置都对。

## 先搞清楚自己收藏的是什么

2098 个仓库一次全塞给模型不现实：前面分得很细，后面就开始偷懒，分类名开始漂移，最后大量项目全堆进一个 Misc。

我把 `stars.jsonl` 切成 8 份并行跑，第一轮只问两件事：每个仓库主要做什么，以及这批里能看出哪些可复用的大类。`description + language + topics` 通常够判断，描述为空或名字含糊的再去拉 README：

```bash
gh api repos/OWNER/REPO/readme \
  -H 'Accept: application/vnd.github.raw+json'
```

八份跑完合起来看：Information 327 个，AI & LLM 204 个，博客建站类 158 个；Minecraft 和 Robotics 数量虽然不大，但领域边界太清楚了，单独一类比塞进 Applications 好找得多。这些数字才是分类粒度的依据，不是拍脑袋想出来的。

第二轮才把全部仓库映射到正式分类，格式固定为：

```json
{
  "仓库 REST 数字 ID": "分类名"
}
```

例如：

```json
{
  "1299334645": "Minecraft",
  "268690468": "Agent"
}
```

本地使用数字 ID 做键，是因为仓库改名或转移 owner 后，`full_name` 可能变化；仓库 ID 更稳定。真正写入 Lists 时，再通过 `stars.jsonl` 找到对应的 `node_id`。

## 把分类边界写死在文件里

25 个名字列出来不够用。问题出在边界上——同一个仓库，是放进 AI & LLM 还是 Agent？是 SRE 还是 Network & Proxy？没有固定规则，下次操作（或者下次的我）会给出不同答案。

在备份目录写了一份 `AGENTS.md`，记了：

- 决策顺序（自上而下，命中即停）；
- 每一类的描述和划入标准；
- 反例和容易混淆的边界；
- 新 Star 的增量入库命令。

决策顺序的前几项是：

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
Applications and Tools（最后兜底）
```

顺序会直接改变结果。比如：

| 仓库性质 | 分类 |
|---|---|
| LLM API 桥接、网关 | AI & LLM |
| Clash 一类的个人代理客户端 | Network & Proxy |
| 服务端反向代理、镜像服务 | SRE |
| OCR 模型、OCR 引擎 | AI & LLM |
| OCR 成品工具 | Office |
| 播放器应用 | Media |
| 播放器库 | Libraries and Frameworks |
| 教程、书籍、Awesome 清单 | Information |
| 自主执行任务的 AI | Agent |
| 文生图、文生视频、语音合成 | AI Generation |

这东西不是为了好看。规则只存在记忆里的话，下次就等于重做一遍。

## 写入前先校验 classification.json

先建立分类名称白名单：

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

再检查仓库有没有漏、有没有多、分类名有没有拼错：

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

本次校验结果：

```text
stars: 2098
classified: 2098
missing: 0 []
extra: 0 []
invalid categories: []
```

看不懂的仓库不要硬塞进兜底类。分类阶段可以先输出 `UNKNOWN`，最后逐个补 README。我的两轮结果也做过交叉复查，把明显落错的项目和全部 `UNKNOWN` 清完后才开始改 GitHub。

## 删除 31 个旧列表，再创建 25 个新列表

这是唯一不可随便重跑的阶段。先确认备份文件不为空：

```bash
jq 'length' ~/stars-backup/old-lists-backup.json
jq '[.[].repositories | length] | add' \
  ~/stars-backup/old-lists-backup.json
```

确认无误后，再显式设置删除开关：

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

然后根据 `categories.txt` 创建新列表，并保存“分类名到 List ID”的映射：

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

### `query=` 少了，为什么错误会“静默”

我最早把 mutation 写成了：

```bash
gh api graphql -f 'mutation { createUserList(...) { ... } }'
```

`-f` 要求参数必须是 `key=value`，GraphQL 文本也必须放在名为 `query` 的字段里。正确形式是：

```bash
gh api graphql -f 'query=mutation { ... }'
```

错误写法在 `gh` CLI 解析参数时就失败了，请求根本没有到 GraphQL。因此输出里没有 GraphQL 的 `errors` 字段。如果脚本只搜索 `"errors"`，会把这些 CLI 错误全部当成成功。

批处理脚本应同时检查进程退出码、JSON 是否可解析，以及目标 `data` 字段是否非空。

## 把 2098 个仓库批量归位

先把 REST ID、仓库 Node ID、目标 List ID 连接起来：

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

输出应为 2098 行。

下面的函数每个仓库发送一条 mutation，4 路并发；遇到 rate limit 相关响应时逐步退避，其他错误立即写入日志：

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

我没有把并发开到几十。GraphQL 的剩余额度、secondary rate limit 和账号状态都可能变化，`-P 4` 足够快，也比较容易在失败后定位。运行前可以先看当前额度：

```bash
gh api graphql -f 'query=query {
  rateLimit { cost remaining resetAt }
}'
```

### `-F 'listIds=["UL_xxx"]'` 不是数组

另一个真实错误是把 JSON 外观的字符串当成 GraphQL 数组变量：

```bash
-F 'listIds=["UL_xxx"]'
```

服务器收到的是字符串 `['UL_xxx']`，随后报无法解析对应的 Global ID。

这不代表 `-F` 完全不能传数组。`gh api` 手册规定数组字段要用重复的 `key[]=value` 形式。只是本次每个仓库固定进入一个列表，直接把单个 List ID 写进 mutation 字面量更简单，也已经完整跑通。

## 核验不能只看总数

如果只验证“25 个列表合计 2098”，两个分类一多一少时，总数仍然可能正确。验收要同时比较每个分类的数量。

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

本次最终输出中 25 行全部是 `OK`：

```text
matched categories: 25/25
expected total: 2098
actual total: 2098
```

我还在 GitHub 网页随机打开几个列表复查，仓库名称与本地 `by-category/*.md` 一致。脚本验数量，网页抽查验对象，两边都过了才结束。

## 写稿时又多了一个 Star

批量分类使用的是 2098 个仓库的固定快照。写这篇文章时我重新请求 `/user/starred`，实时数量已经变成 **2099**，而 25 个列表仍合计 2098。期间新增了一个 Star，它不在原来的 `stars.jsonl` 和 `classification.json` 里。

这不是前面 2098 个仓库漏分，而是数据在任务结束后继续增长。它刚好说明为什么验收必须注明快照时间，也说明分类手册要能支持增量维护。

找出快照之后新增的仓库：

```bash
jq -r '.id' stars.jsonl | sort -n > snapshot.ids

gh api '/user/starred?per_page=100' \
  --paginate \
  --jq '.[].id' | sort -n > current.ids

comm -13 snapshot.ids current.ids
```

对新增仓库读取元数据，按 `AGENTS.md` 选择分类，再执行一条 mutation 即可，不需要重跑全部 2098 个：

```bash
gh api graphql -f 'query=mutation {
  updateUserListsForItem(
    input: {
      itemId: "R_仓库NodeID"
      listIds: ["UL_目标列表ID"]
    }
  ) { clientMutationId }
}'
```

然后同步更新 `stars.jsonl`、`classification.json`、分类清单和数量总览。

## 坑都踩在哪里

GraphQL mutation 本身不复杂，但几处细节真的不好猜。

接口和权限是最常踩的。Star 走 REST，Lists 只能走 GraphQL，这是两套不相干的接口。我一开始就去试 `/user/starred_lists`，404。能成功拉到 Star 也不代表 mutation 有权限——写列表需要 `user` scope，`repo` scope 完全不够，GraphQL 直接报 `INSUFFICIENT_SCOPES`。

然后是 `gh api` 的几个细节。加了 `-f` 参数，请求方法自动变成 POST；`/user/starred` 这个 GET 端点加完 `-f per_page=100` 就 404，换成内联 query string 就好了。GraphQL 字段名必须是 `query=`，写成 `-f 'mutation {...}'` 会在 CLI 层失败，输出里没有 `errors` 字段——如果脚本只搜索 `"errors"` 来判断失败，这些错误会全部静默漏掉。`-F 'listIds=["UL_xxx"]'` 看起来像 JSON 数组，实际上传给服务器的是字符串，解析 Global ID 时报错。

`UserList.items.nodes` 是联合类型，直接读仓库字段会触发 `selectionMismatch`，要加 `... on Repository`。`updateUserListsForItem` 不是追加，是替换——传一个 List ID，就是说这个仓库只属于这一个列表，而不是说"把它加进去"。

备份我实际丢过一次。第一版脚本输出到会话临时目录，环境重置后文件没了，89 条旧列表成员关系丢失，无法恢复。新体系已经覆盖全部 2098 个仓库，对最终结果影响不大，但回滚安全网就没有了。

验收别只看总数。两个分类一多一少，总数还是 2098，但分错了。这次是逐分类比 expected/actual，25 个全过才算完。

Star 会在分类期间继续增加，批量任务只验固定快照，新收藏走增量流程。写这篇文章时重新拉了一次，实时数量已经是 2099 了。

现在备份目录里有完整 Star 快照、REST ID 到 Node ID 的映射、2098 条分类结果、25 份仓库清单和 `AGENTS.md`。下次新增 Star 时，按手册判类，发一条 mutation，更新本地文件，完事。

## 参考资料

- [GitHub Docs：Saving repositories with stars](https://docs.github.com/en/get-started/exploring-projects-on-github/saving-repositories-with-stars)
- [GitHub CLI Manual：gh api](https://cli.github.com/manual/gh_api)
- [GitHub CLI Manual：gh auth refresh](https://cli.github.com/manual/gh_auth_refresh)
- [GitHub GraphQL API：Mutations](https://docs.github.com/en/graphql/reference/mutations)
