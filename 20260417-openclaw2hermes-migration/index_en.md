# Leaving the Lobster Farm: A Step-by-Step Guide to Migrating from OpenClaw to Hermes Agent

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

### 2. Set Up a Provider

With the migration done, the setup phase begins. The wizard asks whether you want Quick setup or Full setup. Use <kbd>↑</kbd><kbd>↓</kbd> to highlight **Quick setup**, press <kbd>Space</kbd> to select it, then <kbd>Enter</kbd> to move on:

![image-20260418012955409](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418012955409.png)

Now pick a model provider. I'll use ark (Volcano Engine's coding plan), which I subscribe to, and enter the model name `ark-code-latest`:

![image-20260418013325785](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418013325785.png)

Pick whichever provider suits your needs. If you don't have a subscription yet, I recommend the [MiniMax Token Plan](https://platform.minimaxi.com/subscribe/token-plan?code=L5Ua6ZLLoY&source=link). MiniMax M2.7 is currently one of the most widely used models inside Hermes Agent, delivering strong results on tool-call accuracy, complex-Skill adherence, and Agent Harness compatibility, all at a compelling price. You can skip this for now and configure the model later by following [6. Adding extra model providers](#6-adding-extra-model-providers).

### 3. Set Up a Platform

Next, choose the chat platform to hook up. Here we'll use Lark (Feishu): log in via APP ID and bind the Lark bot:

![image-20260418013430828](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418013430828.png)

I already created a Lark bot while setting up OpenClaw earlier. If you haven't done so, head over to the [Lark Open Platform](https://open.feishu.cn/app) to create one. After signing in, click **Create Custom App**, fill in the app name and description, optionally set an icon, then click **Create**:

![image-20260418014150010](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418014150010.png)

Click **Add Features** on the left, then add a **Bot**:

![image-20260418020151521](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020151521.png)

Click **Events & Callbacks** on the left, hit the edit button next to **Subscription Method**, switch the subscription mode to **Long Connection**, then click **Save**:

![image-20260418015229088](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418015229088.png)

Still on **Events & Callbacks**, click **Add Event**, search for **Receive Message**, tick it, click **Add**, and confirm the permission grant in the popup:

![image-20260418015803619](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418015803619.png)

Go to **Permissions**, choose **Enable Permissions**, tick every permission, and confirm:

![image-20260418020425172](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020425172.png)

![image-20260418020446781](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020446781.png)

Finally, open **Version Management & Release** on the left, click **Create Version**, enter a version number (e.g. 1.0.0) and release notes, click **Save**, then **Confirm Release**:

![image-20260418020601681](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020601681.png)

![image-20260418020652380](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020652380.png)

![image-20260418020731932](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020731932.png)

![image-20260418020811484](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418020811484.png)

Open **Credentials & Basic Info**. If you need to update bot metadata, edit the relevant fields here (note: any change has to be re-released):

![image-20260418021101878](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021101878.png)

Copy **APP ID** and **APP Secret**, then paste them into the terminal in order:

![image-20260418013746135](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418013746135.png)

Select the Lark China edition:

![image-20260418013820810](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418013820810.png)

For the connection mode, choose **WebSocket**:

![image-20260418021214604](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021214604.png)

For **How should direct messages be authorized?**, keep the default **Use DM pairing approval**:

![image-20260418021242947](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021242947.png)

For **How should group chats be handled?**, keep the default **Respond only when @mentioned in groups**, which means the bot only replies in group chats when explicitly @-mentioned. If you don't want Hermes active in groups at all, choose **Disable group chats**:

![image-20260418021343280](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021343280.png)

**Home Chat ID** is optional. It lets you funnel scheduled-task (Cron) results and reminders, system notifications, alerts, tool-execution output, long-term memory updates, and summaries of newly generated skills into a single chat channel. Since Lark is my only connected platform here, pressing <kbd>Enter</kbd> to accept the default is enough; if you've wired up multiple platforms, set it to taste.

![image-20260418021853819](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021853819.png)

### 4. Install the gateway as a launchd service

Registering the gateway as a system service makes Hermes start automatically when the machine boots. Enter `Y` to confirm:

![image-20260418021920240](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418021920240.png)

At the **Start the service now?** prompt, enter `Y` to bring the service up immediately:

![image-20260418022036777](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418022036777.png)

### 5. Getting started

The setup wizard is now complete. If you need to revisit configuration later, you can always rerun:

```bash
hermes setup
```

The wizard will then ask **Launch hermes chat now?**. Enter `Y` to start Hermes. When you see the prompt below, Hermes is up and running:

![image-20260418022548383](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418022548383.png)

If you run into this error:

```bash
  ⚠ tirith security scanner enabled but not available — command scanning will use pattern matching only

Goodbye! ⚕
```

Close the current terminal, open a fresh terminal window, and run the following command. The chat interface should come up normally:

```bash
hermes chat
```

If it still fails, run setup once more (it will skip already-completed steps or ask you to reconfirm the configuration):

```bash
hermes setup
```

If a chat turn surfaces `API call failed (attempt 1/3): AuthenticationError [HTTP 401]`:

![image-20260418152644914](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418152644914.png)

The likely cause is that you were running a third-party OpenClaw client such as Clawx. These clients don't persist the API key in plain text inside OpenClaw's config file, so the migration has nothing to read. Edit the env file with:

```bash
vim ~/.hermes/.env
```

In my case the Volcano Engine coding plan uses `ARK_API_KEY`. Once I checked the file, the value was indeed empty. Fill in the correct key and you're set:

![image-20260418153204888](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418153204888.png)

### 6. Adding extra model providers

Open a clean new terminal window (Terminal or iTerm2 both work) and run:

```bash
hermes model
```

In the menu, use <kbd>↑</kbd><kbd>↓</kbd> to highlight **Quick setup**, press <kbd>Space</kbd> to select, then <kbd>Enter</kbd> to confirm. To wire up the MiniMax Token Plan, choose **MiniMax China**:

![image-20260418151551231](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418151551231.png)

Next, supply the API key. Grab it from the [MiniMax Token Plan console](https://platform.minimaxi.com/user-center/payment/token-plan):

![image-20260418151742782](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418151742782.png)

Paste it into the terminal:

![image-20260418151822881](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418151822881.png)

When asked for a BaseURL, press <kbd>Enter</kbd> to accept the default, then pick `MiniMax-M2.7` as the model:

![image-20260418152012768](C:\Users\excnies\AppData\Roaming\Typora\typora-user-images\image-20260418152012768.png)

The terminal prints `Default model set to: MiniMax-M2.7 (via MiniMax (China))` and the provider is configured.
