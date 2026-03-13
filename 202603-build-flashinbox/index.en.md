# How to Set Up FlashInbox on Cloudflare for a Private Temp Mail Service

This guide walks through deploying `FlashInbox` on Cloudflare as a self-managed temporary email service.

`FlashInbox` is built around a simple stack: `Next.js` for the web app, Cloudflare Workers for runtime, Cloudflare Email Routing for inbound mail, and `D1` for storage. It is designed for temporary inboxes, not for full-featured email hosting.

Repository: `https://github.com/CtelSpecu/FlashInbox`

By the end of this guide, the deployment should provide:

- A web app hosted at a domain such as `mail.example.com`
- Temporary inboxes using addresses such as `bluepanda23@example.com`
- Working inbound mail delivery
- An admin panel for domains, rules, and quarantine management

## What FlashInbox Provides

`FlashInbox` is closer to a lightweight inbound mail station than a traditional mailbox service. Out of the box, it can:

- Create temporary inboxes anonymously
- Receive inbound email
- Skip attachment storage
- Let users claim an inbox and receive a one-time plaintext key
- Restore access with `username + key`
- Provide an admin dashboard

It is a good fit for temporary email under your own domain. It is not intended to replace a full mailbox platform such as Gmail or Microsoft 365.

## Before You Start

You will need:

- A Cloudflare account with `Workers`, `D1`, `Email Routing`, and `Turnstile` enabled
- A domain already managed in Cloudflare DNS, such as `example.com`
- `bun` installed locally
- `wrangler` available locally

One important detail: the web app domain and the mail-receiving domain do not need to be the same.

- The web app can live at `mail.example.com`
- The receiving mail domain can be `example.com`

This split is usually cleaner because Cloudflare Email Routing catch-all rules apply to the main mail domain, not to a web-facing subdomain such as `mail.example.com`.

## Architecture Overview

This deployment is not powered by one Worker doing everything. It is three separate pieces working together:

1. `flashinbox`
   This is the main application. It serves the website, APIs, user inbox views, and the admin panel. It is configured through `wrangler.toml`.

2. `flashinbox-email`
   This is the inbound mail Worker. It receives messages from Email Routing, parses them, and writes them into D1. It is configured through `wrangler.email.toml`.

3. `flashinbox-scheduled`
   This is the scheduled Worker. It handles cleanup and periodic background work. It is configured through `wrangler.scheduled.toml`.

All three components must point to the same D1 database. If the UI loads but mail never appears, this is one of the first settings to verify.

## Step 1: Clone the Repo and Install Dependencies

Start by cloning the project:

```bash
git clone https://github.com/CtelSpecu/FlashInbox.git
cd FlashInbox
```

Then install dependencies:

```bash
bun install
```

The repository already includes `wrangler`, so `bunx wrangler` also works.

For a quick local sanity check, these are the main scripts:

```bash
bun run build:worker
bun run dev
bun test
```

## Step 2: Create the D1 Database

Log in to Cloudflare first:

```bash
wrangler login
```

Then create the production database:

```bash
wrangler d1 create flashinbox-db
```

Cloudflare will return a `database_id`. Put that same value into:

- `wrangler.toml`
- `wrangler.email.toml`
- `wrangler.scheduled.toml`

The `database_id` must be identical across all three configs. Updating only the main app config is not enough. The UI may still load and the admin panel may still look normal, while the email Worker writes to the wrong place.

## Step 3: Run the Database Migrations

Now create the schema:

```bash
wrangler d1 execute flashinbox-db --remote --file=migrations/0001_init.sql
wrangler d1 execute flashinbox-db --remote --file=migrations/0002_mailboxes_banned.sql
```

Run both migrations.

`0001_init.sql` creates the core schema. `0002_mailboxes_banned.sql` adds support for mailbox banning in the admin panel. If the second migration is skipped, the problem may only appear later when admin actions start failing on status constraints.

If you see errors involving `BEGIN TRANSACTION` or `COMMIT`, that usually means the migration file is not compatible with D1’s execution rules. The migration files in the current repository are already prepared for D1, so the default path should work.

## Step 4: Configure the Domains

Two settings in `wrangler.toml` require special attention.

The first is the production route:

```toml
[env.production]
name = "flashinbox"
routes = [
  { pattern = "mail.example.com", custom_domain = true }
]
```

The second is the default inbox domain:

```toml
[env.production.vars]
DEFAULT_DOMAIN = "example.com"
```

These are not interchangeable.

- `mail.example.com` is where people open the web app
- `example.com` is the domain used for generated mailbox addresses

These values serve different purposes. Mixing them up will make routing and inbox generation harder to debug later.

## Step 5: Create Turnstile

`FlashInbox` uses Turnstile in the inbox-claim flow, so create a Turnstile site in Cloudflare and bind it to your app domain, for example `mail.example.com`.

Once the site is created, keep these two values available:

- `TURNSTILE_SITE_KEY`
- `TURNSTILE_SECRET_KEY`

You will need both for the app configuration.

## Step 6: Set the Secrets

Now configure the production secrets for the main app:

```bash
wrangler secret put ADMIN_TOKEN --env production
wrangler secret put KEY_PEPPER --env production
wrangler secret put SESSION_SECRET --env production
wrangler secret put TURNSTILE_SECRET_KEY --env production
wrangler secret put TURNSTILE_SITE_KEY --env production
```

The most important values here are `ADMIN_TOKEN`, `KEY_PEPPER`, and `SESSION_SECRET`.

- `ADMIN_TOKEN` is your admin login token
- `KEY_PEPPER` is used in key hashing
- `SESSION_SECRET` is used for session signing

Be careful with `KEY_PEPPER`. Changing it later will effectively invalidate existing recovery keys.

## Step 7: Deploy the Main App

The main app is deployed through the `Next.js + OpenNext + Cloudflare Workers` path.

Build it first:

```bash
bun run build:worker
```

Then deploy it:

```bash
wrangler deploy --env production
```

At this point, the site itself should already be reachable, for example:

```text
https://mail.example.com
```

If the website does not load yet, troubleshoot the main app build, routes, and custom domain binding before checking the mail path.

## Step 8: Deploy the Other Two Workers

The main app is only the front end of the system. Inbound mail and cleanup still depend on the other two Workers.

Deploy the email Worker:

```bash
wrangler deploy --config wrangler.email.toml
```

Deploy the scheduled Worker:

```bash
wrangler deploy --config wrangler.scheduled.toml
```

This is an easy step to miss. When it is missing, the site may still load and inbox creation may still appear to work, while inbound mail fails silently.

## Step 9: Initialize the `domains` Table

This is another common failure point.

The email Worker checks the `domains` table in D1 before accepting mail. If the receiving domain is missing or not set to `enabled`, inbound mail will not be processed.

You can initialize the table in either of two ways.

### Option A: Add the Domain in the Admin Panel

After deployment, open:

```text
https://mail.example.com/admin
```

Sign in with `ADMIN_TOKEN`, then add `example.com` in the Domains page and set its status to `enabled`.

### Option B: Insert It Directly into D1

```bash
wrangler d1 execute flashinbox-db --remote --command "INSERT INTO domains (name, status, note, created_at, updated_at) VALUES ('example.com', 'enabled', 'prod', strftime('%s','now')*1000, strftime('%s','now')*1000);"
```

If you plan to receive mail for multiple domains, such as `example.com` and `example.net`, each one needs its own row.

## Step 10: Configure Email Routing

Now wire up the actual inbound mail path.

In the Cloudflare Dashboard, open your domain, go to Email Routing, and configure these items:

- Enable Email Routing
- Create a catch-all rule
- Set the action to `Send to a Worker`
- Select `flashinbox-email` as the target Worker

The flow is straightforward: mail sent to `anything@example.com` is first received by Cloudflare and then forwarded to the email Worker.

The two most common points of confusion here are:

1. The catch-all applies to the actual receiving domain

That usually means `example.com`, not `mail.example.com`.

2. If the catch-all is not pointed at the Worker

Mail may simply be dropped, and the feedback is often minimal. In many cases, the only visible signal is a `Dropped` result in the Activity log.

## Step 11: Verify Mail Delivery

Once everything is configured, test mail delivery immediately.

Open the site, create a temporary inbox, and assume you get something like:

```text
bluepanda23@example.com
```

Then send a test message to that address from another mailbox.

Verify three things:

- Does the inbox appear in the frontend?
- Does the domain status look correct in the admin panel?
- Does Cloudflare Email Routing show the message as delivered rather than dropped?

If nothing shows up in the frontend, work through this checklist:

- Is `example.com` present in the `domains` table?
- Is that domain set to `enabled`?
- Is the catch-all actually pointed at `flashinbox-email`?
- Were all three Workers deployed?
- Do all three Wrangler configs point to the same D1 database?

If needed, inspect the email Worker logs directly:

```bash
wrangler tail flashinbox-email
```

If you see messages such as `Domain not found` or `Domain is disabled`, stop guessing and fix the configuration first.

## Common Pitfalls

### 1. A working website does not mean working inbound mail

A healthy UI only proves that the main app is deployed. Mail delivery still depends on Email Routing, the email Worker, and the `domains` table being configured correctly.

### 2. All three Workers must share the same D1 database

Treat them as three entry points into the same system, not as separate deployments with independent state.

### 3. `DEFAULT_DOMAIN` is not the web app domain

It controls the default receiving domain for generated inboxes. If it is wrong, the frontend will generate mailbox addresses you did not intend to use.

### 4. Attachments are not stored

That is part of the design. Verification emails, notifications, and signup links are good use cases. Large attachment-heavy workflows are not.

### 5. Cloudflare Email Routing has platform limits

Do not expect messages larger than `25 MiB` to fit comfortably into this setup. That limit comes from Cloudflare Email Routing itself, not from FlashInbox.

## Recommended Use Cases

This is a good fit if:

- You want temp mail under your own domain
- You do not want to rely on public temp mail providers anymore
- You do not want to run a full traditional mail server
- You want the website, inbound mail flow, storage, and admin tooling to stay inside the Cloudflare ecosystem

This setup is not a replacement for a business mailbox, and it is not intended for full-featured email hosting. It works best when the goal is simple, self-managed temporary inboxes under your own domain.
