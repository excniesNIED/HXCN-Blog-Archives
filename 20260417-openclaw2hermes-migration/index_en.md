---
title: Leaving the Lobster Farm: Migrating from OpenClaw to Hermes Agent
pubDatetime: 2026-04-17T00:00:00.000+08:00
slug: openclaw2hermes-migration-en
tags:
  - AI Agent
  - OpenClaw
  - Hermes Agent
  - Migration
category: Technical Tutorial
description: OpenClaw to Hermes Agent migration guide, covering why Hermes is gaining traction, how its harness, memory, and skill system differ from OpenClaw, and the practical setup path for installation, provider configuration, platform binding, and service startup. Suitable for AI agent users moving workflows to Hermes.
---

## Why this "horse" is taking off

Hermes Agent was open-sourced in late February and picked up 22,000 stars in its first month. After v0.8.0 shipped on April 8, it gained 6,400 stars in a single day, crossed 47,000 total, and held the #1 spot on GitHub's global trending list for several days running. A large number of OpenClaw users are already moving house to Hermes.

In short, Hermes is an AI agent that accumulates experience: when it finishes a task, it automatically summarizes the solution and saves it as a reusable skill, ready to be invoked the next time a similar situation shows up. It speaks to 200+ large models, plugs into Telegram, Discord, and Slack out of the box, and installs with a single command.

![Tweets from Gaj Varma and Teknium](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/6E84E04BF785493F4A6BF3B209A591E4.webp)

Gaj Varma reports that upgrading OpenClaw from 0.5 to 0.8 took him two or three hours of patching, whereas Hermes sailed through 695 commits without a single failure. Founder Teknium replied: "I genuinely want to ask what OpenClaw is doing to make an upgrade that painful."

![Tweet from LYi](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/C479815ADCD7AA6F4E7B94F24FE83678.webp)

LYi's hands-on observation: when Hermes hits an error it keeps trying until there is a clear outcome, with no inexplicable early exits. It is also frugal with tokens; even after long sessions the context stays around 30–40k, while OpenClaw would already be past 100k in the same scenario.

In the community, one user has Hermes running around the clock on a Mac mini, driven via SSH and Telegram. It aggregates Calendar, Gmail, and Todoist, dispatches work to Claude Code, and writes the results back to an Obsidian vault, all unattended. Another user built a Worms clone in 2.5 hours, and the agent itself distilled the physics-engine logic into a reusable skill plug-in.

## What Hermes does differently

Start with one term: **Harness**. In AI parlance, the harness is the control framework that sits between the model and human intent, and the metaphor is literal. The LLM is the wild horse; everything outside of it is the harness that keeps it from bolting. Strip away the agent's brain (the underlying LLM) and everything else belongs to the harness: where to run, how fast, and when to stop. In February, OpenAI published "Harness Engineering: Leveraging Codex in an Agent-First World," and the industry consensus is now clear. Prompt engineering and context engineering are no longer enough; we need a higher-level constraint system. The more autonomy you grant, the easier it is for the horse to bolt, and a well-fitted harness is what actually lets the agent run farther. As people on X like to put it, *"Harness = everything outside of the LLM."*

Hermes is developed by Nous Research under the MIT license. Nous positions itself as a decentralized AI research lab and is also advancing Psyche, a decentralized training network.

The biggest departure from traditional agents is **self-evolution**. A typical agent starts from scratch on every invocation; Hermes learns from the tasks it has already completed and keeps memory across sessions and across platforms. Give it a vague instruction like "write a script that scrapes some data and plots it," and it will break the task down, read error messages, attempt fixes, and summarize the approach itself. Its tagline, *"the agent that grows with you,"* captures the ambition: turn AI from one-shot calls into cumulative capability, with the data and memory living in the user's own hands rather than on someone's platform.

Memory noise, skill quality, and deployment friction are still being worked on, but the direction is clear.

## OpenClaw vs. Hermes (the lobster vs. the horse)

OpenClaw is an open-source AI agent that took off in early 2026, marked by its red lobster mascot. Overseas coverage tends to call it "the lobster-themed AI agent," and Chinese users who run it call themselves *"lobster farmers"*, a term that has been picked up verbatim on X and in r/openclaw threads. What it does is make LLMs actually get things done: tool calls, automated execution, long-term memory, sandboxing, multi-platform access. It behaves like a batteries-included digital butler.

The two projects agree on local-first, off-cloud data, and instant-messaging as the primary entry point. They diverge on how to get there:

**Skill origin.** OpenClaw relies on humans writing skills: developers author them in code or prompts. That's stable and predictable, but the ceiling is however much you are willing to hand-write. Hermes relies on emergence: after completing a complex task, it abstracts the method into a Skill and reuses it on the next run.

**Memory model.** OpenClaw is fundamentally RAG: it knows where information lives and fetches it on demand. Hermes uses layered memory and additionally builds a user model, remembering your coding style and tech-stack preferences across sessions.

**Team and architecture.** Hermes is led by Nous Research, a team with a strong engineering and research pedigree, and the project has been opinionated from day one. It's written in Python, with a tight, clearly organized core (agent loop, memory system, skill-generation pipeline) that favors a small, focused codebase over maximum ecosystem breadth. OpenClaw, by contrast, went viral early, attracted a flood of community PRs, and is built on Node.js/TypeScript with a sprawling plugin layer. Both code and skill ecosystem ballooned quickly, and maintenance burden grew right along with them.

**Code quality and CI discipline.** OpenClaw's main branch has been known to break the build outright, PRs frequently fail CI, and regression bugs are a recurring complaint. Community threads bluntly call out a "lack of basic DevOps discipline" (no staging, thin test coverage, merges that land too fast). Hermes already has 4k+ commits in the repo, yet the core layout is still clean, and release notes routinely advertise "hundreds of commits + many bug fixes and reliability enhancements." CI complaints are far rarer than on the OpenClaw side. Even with star count approaching 90k, Hermes has not repeated the "PR flood + CI meltdown" pattern, and the prevailing community read is "steadier, with depth prioritized over breadth."

**The security gap is the starkest difference.** OpenClaw grew too fast; its ecosystem (ClawHub) ballooned out of control, and regression bugs such as startup crashes and gateway freezes keep surfacing. Multiple high-severity CVEs have already been disclosed. CVE-2026-25253 has a CVSS score of 8.8 and enables one-click RCE, and ClawHub has repeatedly been caught hosting malicious skills that steal credentials.

![Summer Yue recounting how OpenClaw wiped her inbox overnight](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/aba5968c-ca5c-4e95-a320-7d125ebe36eb.webp)

Meta's Director of Safety Alignment, Summer Yue, had explicitly set a "confirm before acting" policy, and OpenClaw still went ahead and emptied her inbox. She couldn't stop it from her phone and ended up racing home to kill the process by hand. Hermes is more conservative: dangerous operations require manual approval (its Tirith pre-execution scanner inspects terminal commands first), its skill ecosystem is smaller, its attack surface is narrower, and no comparable cluster of high-severity incidents has occurred to date.

**Token cost.** The number-one gripe from lobster farmers is the burn rate and the unreliability of long-horizon tasks. OpenClaw tends to run out of tokens halfway through a 24-hour task, or veer off course at one step and stay wrong all the way down. Hermes users report starting around ten-thousand-plus tokens and staying in the 30–40k range even after extended sessions, whereas OpenClaw would already be past 100k in the same scenario. And when errors occur, Hermes keeps going until there is a clear success or failure.

That said, the prevailing community view is not that one replaces the other but that they complement each other: OpenClaw does the work, Hermes does the thinking. A common pattern is to stack Hermes on top of OpenClaw as a planner; a single `hermes claw migrate` command migrates existing skills, memories, and configuration cleanly.

The walkthrough below shows how to migrate from OpenClaw to Hermes Agent.

## Migrating from OpenClaw to Hermes Agent

I previously deployed OpenClaw on macOS and am now installing Hermes from the same macOS terminal. You can equally deploy on a Linux distribution or even on Android (via Termux). If you are on Windows, it's better to [install Ubuntu on WSL2](https://ain.hmgf.hxcn.space/sre/first-vm-2024#%E4%BD%BF%E7%94%A8-wsl-%E5%AE%89%E8%A3%85-ubuntu) first and deploy there.

### 1. Install Hermes Agent

Start by running the online install script:

```bash
# Linux / macOS / WSL2 / Android (Termux)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

The script provisions the runtime environment and skills, then drops you into Hermes Setup. The Setup Wizard detects the existing OpenClaw installation and offers to preview what would be imported before making any changes. Enter `Y` to continue, and the wizard will list every migratable item — configuration (platform integrations, settings, and so on), memory (long/short-term memory, `SOUL.md`, etc.), Skills, API keys, and portions of conversation history (better supported in newer versions). Once you've reviewed the list, enter `Y` again to proceed with the migration:

```bash
Would you like to see what can be imported? [Y/n]: Y

◆ Migration Preview — 166 item(s) would be imported
  No changes have been made yet. Review the list below:

  Would import:
      soul                   → ~/.hermes/SOUL.md
      user-profile           → ~/.hermes/memories/USER.md
      provider-keys          → ~/.hermes/.env
      model-config           → ~/.hermes/config.yaml
      shared-skills          → ~/.hermes/skills/openclaw-imports/antfu
      shared-skills          → ~/.hermes/skills/openclaw-imports/brave-web-search
......
      personal-skills        → ~/.hermes/skills/openclaw-imports/xlsx
      shared-skill-category  → ~/.hermes/skills/openclaw-imports/DESCRIPTION.md
      daily-memory           → ~/.hermes/memories/MEMORY.md
      agent-config           → config.yaml agent/compression/terminal
      env-var                → .env HERMES_GATEWAY_TOKEN
      full-providers         → config.yaml custom_providers[minimax-portal]

  ── Warnings ──
    ⚠ Config values — OpenClaw settings may not map 1:1 to Hermes equivalents
    ⚠ Context file — may contain OpenClaw-specific instructions
    ⚠ Gateway/messaging — this will configure Hermes to use your OpenClaw messaging channels
    ⚠ Instruction file — may contain OpenClaw-specific setup/restart procedures
    ⚠ Memory/context file — may reference OpenClaw-specific infrastructure
    ⚠ Slack — this will point Hermes at your OpenClaw Slack workspace

  Note: OpenClaw config values may have different semantics in Hermes.
  For example, OpenClaw's tool_call_execution: "auto" ≠ Hermes's yolo mode.
  Instruction files (.md) from OpenClaw may contain incompatible procedures.

Proceed with migration? [y/N]: y
```

> The migration tool only handles the standard `workspace/` path by default. If you keep multiple custom workspaces in OpenClaw (e.g. `workspace-project-a`), those directories are not migrated automatically and need extra steps — see [FAQ: Additional workspaces aren't migrated](#additional-workspaces-arent-migrated). If a chat turn later surfaces `AuthenticationError [HTTP 401]`, see [FAQ: AuthenticationError on chat](#authenticationerror-on-chat).

### 2. Set Up a Provider

With the migration done, the setup phase begins. The wizard asks whether you want Quick setup or Full setup. Use <kbd>↑</kbd><kbd>↓</kbd> to highlight **Quick setup**, press <kbd>Space</kbd> to select it, then <kbd>Enter</kbd> to move on:

![image-20260418012955409](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418012955409.webp)

Now pick a model provider. I'll use ark (Volcano Engine's coding plan), which I subscribe to, and enter the model name `ark-code-latest`:

![image-20260418013325785](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013325785.webp)

Pick whichever provider suits your needs. If you don't have a subscription yet, I recommend the [MiniMax Token Plan](https://platform.minimaxi.com/subscribe/token-plan?code=L5Ua6ZLLoY&source=link). MiniMax M2.7 is currently one of the most widely used models inside Hermes Agent, delivering strong results on tool-call accuracy, complex-Skill adherence, and Agent Harness compatibility, all at a compelling price. You can skip this for now and configure additional providers later via [FAQ: Adding extra model providers](#adding-extra-model-providers).

### 3. Set Up a Platform

Next, choose the messaging platform to hook up. The configuration flow here is **identical to OpenClaw** — the wizard will prompt you for the same credentials (e.g. bot token for Telegram/Discord/Slack, APP ID + APP Secret for Lark, etc.), connection mode, DM authorization, and group-chat handling that you already filled in for OpenClaw. If you migrated from OpenClaw, just re-use the existing bot and credentials; if you're setting things up from scratch, follow the bot-creation docs for your platform of choice and feed the resulting credentials into the wizard.

A couple of prompts are worth calling out because they aren't platform-specific:

- **How should direct messages be authorized?** The default `Use DM pairing approval` is the safest choice and is what we'll rely on later in step 6.
- **How should group chats be handled?** The default `Respond only when @mentioned in groups` is usually right. If you don't want Hermes active in groups at all, choose `Disable group chats`.
- **Home Chat ID** is optional. It funnels scheduled-task (Cron) results, system notifications, alerts, tool output, long-term memory updates, and skill-generation summaries into a single chat. If you've only wired up one platform, pressing <kbd>Enter</kbd> to accept the default is enough.

### 4. Register the gateway as a service

Registering the gateway as a system service makes Hermes start automatically when the machine boots, with no need to bring it up by hand. If you need to revisit gateway configuration later, drop back into the gateway wizard at any time:

```bash
hermes gateway setup
```

If you'd rather not register the gateway as a system service, you can run it in the foreground and keep it alive with tmux instead — see [FAQ: Run the gateway in the background with tmux](#run-the-gateway-in-the-background-with-tmux).

#### macOS

On macOS, Hermes registers the gateway as a launchd service. At this prompt, enter `Y` to confirm:

![image-20260418021920240](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021920240.webp)

At the **Start the service now?** prompt, enter `Y` to bring the service up immediately:

![image-20260418022036777](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022036777.webp)

#### Linux

TBD.

### 5. Getting started

The setup wizard is now complete. If you need to revisit configuration later, you can always rerun:

```bash
hermes setup
```

The wizard will then ask **Launch hermes chat now?**. Enter `Y` to start Hermes. When you see the prompt below, Hermes is up and running:

![image-20260418022548383](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022548383.webp)

If startup fails with `tirith security scanner enabled but not available` and exits straight away, see [FAQ: Tirith scanner error on startup](#tirith-scanner-error-on-startup); if a chat turn surfaces `AuthenticationError [HTTP 401]`, see [FAQ: AuthenticationError on chat](#authenticationerror-on-chat).

### 6. Pair your messaging account

The first message you send to the bot will come back unpaired, because Hermes doesn't yet know which Hermes user the messaging account belongs to. The bot replies with `Hi~ I don't recognize you yet!` plus a one-time pairing code.

Open a fresh terminal and run the pairing command, replacing the placeholder with the code you received in the chat (and the platform name with whatever you wired up in step 3 — `telegram`, `discord`, `slack`, `feishu`, etc.):

```bash
hermes pairing approve <platform> <pairing-code>
```

The terminal prints a confirmation like:

```bash
user@host:~$ hermes pairing approve feishu EFS7PRQ6

  Approved! User Alice (a*****e) on feishu can now use the bot~
  They'll be recognized automatically on their next message.
```

Send another message from the same account and the bot will respond normally.

## FAQ

### Adding extra model providers

Open a clean new terminal window (Terminal or iTerm2 both work) and run:

```bash
hermes model
```

In the menu, use <kbd>↑</kbd><kbd>↓</kbd> to highlight **Quick setup**, press <kbd>Space</kbd> to select, then <kbd>Enter</kbd> to confirm. To wire up the MiniMax Token Plan, choose **MiniMax China**:

![image-20260418151551231](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151551231.webp)

Next, supply the API key. Grab it from the [MiniMax Token Plan console](https://platform.minimaxi.com/user-center/payment/token-plan):

![image-20260418151742782](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151742782.webp)

Paste it into the terminal:

![image-20260418151822881](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151822881.webp)

When asked for a BaseURL, press <kbd>Enter</kbd> to accept the default, then pick `MiniMax-M2.7` as the model:

![image-20260418152012768](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418152012768.webp)

The terminal prints `Default model set to: MiniMax-M2.7 (via MiniMax (China))` and the provider is configured.

### Tirith scanner error on startup

If Hermes prints the following and exits straight away on launch:

```bash
  ⚠ tirith security scanner enabled but not available — command scanning will use pattern matching only

Goodbye! ⚕
```

Close the current terminal, open a fresh terminal window, and run the following command. The chat interface should come up normally:

```bash
hermes chat
```

If it still fails, run setup once more — the wizard will skip already-completed steps or ask you to reconfirm the configuration:

```bash
hermes setup
```

### AuthenticationError on chat

If a chat turn surfaces `API call failed (attempt 1/3): AuthenticationError [HTTP 401]`:

![image-20260418152644914](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418152644914.webp)

The likely cause is that you were running a third-party OpenClaw client such as Clawx. These clients don't persist the API key in plain text inside OpenClaw's config file, so the migration has nothing to read. Edit the env file with:

```bash
vim ~/.hermes/.env
```

In my case the Volcano Engine coding plan uses `ARK_API_KEY`. Once I checked the file, the value was indeed empty. Fill in the correct key and you're set:

![image-20260418153204888](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418153204888.webp)

### Run the gateway in the background with tmux

If you'd rather not register Hermes as a system service, the simplest path is to launch the gateway manually:

```bash
$ hermes gateway run
┌─────────────────────────────────────────────────────────┐
│           ⚕ Hermes Gateway Starting...                 │
├─────────────────────────────────────────────────────────┤
│  Messaging platforms + cron scheduler                    │
│  Press Ctrl+C to stop                                   │
└─────────────────────────────────────────────────────────┘
```

That works, but it requires keeping the terminal open: close the window and the gateway dies with it. Compared with older tools like screen or nohup, **tmux** is more modern, easier to use, and more reliable. Its sessions are completely decoupled from the terminal, so closing the window or dropping the SSH connection doesn't affect the process inside, and you can re-attach whenever you want to check on it. tmux is the recommended way to keep the gateway resident in the background.

If tmux isn't installed yet, pick the command that matches your distribution:

```bash
# macOS (requires Homebrew)
brew update && brew install tmux

# Debian family (Debian / Ubuntu / Kali / Pop!_OS, etc.)
sudo apt update && sudo apt install tmux -y

# RHEL family (CentOS / Rocky Linux / openEuler / Fedora, etc.)
sudo dnf makecache && sudo dnf install tmux -y

# Arch family (Arch Linux / Manjaro / CachyOS, etc.)
sudo pacman -Syu tmux

# SUSE family (openSUSE Leap / Tumbleweed / SLES, etc.)
sudo zypper refresh && sudo zypper install tmux
```

Then create a session named `hermes` and start the gateway inside it:

```bash
tmux new -s hermes 'hermes gateway run'
```

Press <kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>d</kbd> to detach and send the session to the background. To check on the gateway later, re-attach:

```bash
tmux attach -t hermes
```

List every active tmux session:

```bash
tmux ls
```

When you no longer need the gateway, kill the session outright:

```bash
tmux kill-session -t hermes
```

If your environment can't run tmux, fall back to a traditional session tool — see the next entry, [Run the gateway in the background with traditional sessions](#run-the-gateway-in-the-background-with-traditional-sessions).

### Run the gateway in the background with traditional sessions

The [previous entry](#run-the-gateway-in-the-background-with-tmux) recommends tmux for keeping `hermes gateway run` resident in the background. If tmux isn't available in your environment, screen and nohup can serve as fallbacks.

**screen** is an older terminal multiplexer that ships pre-installed on some legacy distributions, and its workflow is close to tmux. Start and enter a session named `hermes`:

```bash
screen -S hermes hermes gateway run
```

Detach with <kbd>Ctrl</kbd>+<kbd>a</kbd> then <kbd>d</kbd>; re-attach with:

```bash
screen -r hermes
```

List every session and kill a named session:

```bash
screen -ls
screen -X -S hermes quit
```

**nohup** wins on being available everywhere out of the box. Combined with `&`, it detaches the process from the terminal so it can keep running in the background, at the cost of clumsier log and process management:

```bash
nohup hermes gateway run > ~/.hermes/hermes.log 2>&1 &
```

Tail the log live:

```bash
tail -f ~/.hermes/hermes.log
```

Stop the background process:

```bash
pkill -f "hermes gateway run"
```

### Additional workspaces aren't migrated

When you run `hermes claw migrate --dry-run`, you may see messages like `workspace-agents  No workspace target was provided`, and notice that some custom workspaces aren't picked up:

```bash
user@Mac ~ % hermes claw migrate --dry-run

┌─────────────────────────────────────────────────────────┐
│          ⚕ Hermes — OpenClaw Migration                 │
└─────────────────────────────────────────────────────────┘


◆ Migration Settings
  Source:      /Users/user/.openclaw
  Target:      /Users/user/.hermes
  Preset:      full
  Overwrite:   no (skip conflicts)
  Secrets:     yes (allowlisted only)


✗ Hermes gateway is running with active connections: feishu
  Migrating bot tokens while the gateway is active will cause conflicts (Telegram, Discord, and Slack only allow one active session per token).
  Recommendation: stop the gateway first with 'hermes stop'.

Continue anyway? [y/N]: y


◆ Migration Preview — 7 item(s) would be imported
  No changes have been made yet. Review the list below:


◆ Dry Run Results
  No files were modified. This is a preview of what would happen.

  ✓ Would migrate:
      user-profile           → ~/.hermes/memories/USER.md
      daily-memory           → ~/.hermes/memories/MEMORY.md
      agent-config           → config.yaml agent/compression/terminal
      env-var                → .env HERMES_GATEWAY_TOKEN
      env-var                → .env ARK_API_KEY
      env-var                → .env UNICOM_CLOUD_API_KEY
      env-var                → .env MINIMAX_PORTAL_API_KEY

  ⚠ Conflicts (skipped — use --overwrite to force):
      soul                    Target exists and overwrite is disabled
      provider-keys           Destination .env already has different values
      model-config            Model already set and overwrite is disabled
      shared-skills           Destination skill already exists
      ......
      personal-skills         Destination skill already exists
      full-providers          Provider 'ark' already exists
      full-providers          Provider 'unicom-cloud' already exists
      full-providers          Provider 'minimax-portal' already exists

  ─ Skipped:
      workspace-agents        No workspace target was provided
      memory                  Source file not found
      ......

  Summary: 7 would migrate, 157 conflict(s), 23 skipped

  To execute the migration, run without --dry-run:
    hermes claw migrate --preset full
user@Mac ~ % ls .openclaw
agents                  extensions              openclaw.json.bak.2     update-check.json
browser                 identity                openclaw.json.bak.3     wechat-access-guid
canvas                  logs                    openclaw.json.bak.4     workspace
completions             media                   openclaw_copy.json      workspace-project-a
cron                    memory                  qqbot                   workspace-project-b
delivery-queue          openclaw.json           skills
devices                 openclaw.json.bak       subagents
exec-approvals.json     openclaw.json.bak.1     tasks
```

In Hermes's official migration logic, `hermes claw migrate` only looks for the standard `workspace/` or `workspace-main/` path by default. Because OpenClaw's multi-agent architecture stores different workspaces in dedicated directories like `workspace-project-a` or `workspace-project-b`, the tool silently skips these "non-standard" paths when not told otherwise (that's the `workspace-agents  No workspace target was provided` message above).

To pull these additional workspaces across, you'll need to either **point the migration at each one explicitly** or **copy the key files by hand**.

#### Option 1: Specify the target path (recommended)

Use the `--workspace-target` flag and run the migration once per workspace, telling it where to land:

```bash
# Migrate workspace-project-a to a dedicated Hermes directory
hermes claw migrate --preset full \
  --source ~/.openclaw/workspace-project-a \
  --workspace-target ~/.hermes/workspaces/project-a
```

> **Note**: If the workspace contains an API key (in a `.env` file), remember to pass `--migrate-secrets`.

#### Option 2: Move the files manually

Hermes's core layout (`SOUL.md`, `MEMORY.md`, etc.) is highly compatible with OpenClaw's, so when the automation can't pick up a directory, copying the key files by hand is usually the fastest and safest route.

For the directories listed above (e.g. `workspace-project-a`), the manual mapping is:

| OpenClaw source (per workspace) | Hermes target | Notes |
| --- | --- | --- |
| `SOUL.md` | `~/.hermes/memories/SOUL_{name}.md` | Agent persona definition |
| `MEMORY.md` | `~/.hermes/memories/MEMORY.md` (append) | Long-term memory (merge recommended) |
| `USER.md` | `~/.hermes/memories/USER.md` | User profile |
| `skills/` | `~/.hermes/skills/` | Custom skill scripts |

Recommended steps:

1. **Merge memories**: paste `MEMORY.md` content from each workspace into `~/.hermes/memories/MEMORY.md`. Hermes performs semantic dedup on startup.
2. **Move skills**: copy the directories under `.openclaw/skills` directly into `.hermes/skills`.

You can also let Hermes itself read and migrate the key files from the chat:

```
@~/.openclaw contains three workspaces: workspace, workspace-1, workspace-2. Please:
1. Copy SOUL.md verbatim to ~/.hermes/hermes-persona.md, USER.md to ~/.hermes/memories/USER.md, and skills/ to ~/.hermes/skills/.
2. Copy the contents of memory/ verbatim to ~/.hermes/memories/MEMORY.md.
3. Carry over the substantive parts of TOOLS.md into ~/.hermes/AGENTS.md — tool usage conventions, local paths, preferences (e.g. "use pnpm", "avoid certain commands"), etc.
4. Put detailed tool-usage specifics into SKILL.md files under ~/.hermes/skills/, and have ~/.hermes/AGENTS.md spell out strictly and in detail how to use these skills to complete tasks.
5. When inheriting config files, preserve content in full — do not summarize before copying.
```

![image-20260521151429812](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260521151429812.webp)

#### Option 3: Resolving conflicts

The mass of `Conflict (skipped)` entries in the dry run is caused by same-named files already living under `.hermes`. If you're sure you want OpenClaw's config to take precedence over the existing Hermes setup, add `--overwrite`:

```bash
hermes claw migrate --preset full --overwrite --migrate-secrets
```

#### Recommended flow

1. **Stop the gateway**: run `hermes stop` first to avoid messaging-connection conflicts.
2. **Run one full forced migration**:

   ```bash
   hermes claw migrate --preset full --overwrite --migrate-secrets
   ```

3. **Fill in the gaps for special workspaces**: manually move `SOUL.md` or `AGENTS.md` from `workspace-project-a` and `workspace-project-b` into the appropriate Hermes config files or the `memories` folder.
