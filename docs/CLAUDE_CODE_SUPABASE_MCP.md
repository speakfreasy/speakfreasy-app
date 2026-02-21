# Using Supabase MCP with Claude Code Extension

Use the same Supabase MCP server from the **Claude Code** extension (not Cursor Composer) by configuring MCP in one of these ways.

---

## Prerequisites

- **Node.js** installed (`node -v`)
- **Supabase Personal Access Token (PAT)** from [Account → Access Tokens](https://supabase.com/dashboard/account/tokens)

Set the token as an environment variable so it’s not committed:

```powershell
# PowerShell (current session)
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."

# Or set permanently: System Properties → Environment Variables → New (user)
# Name: SUPABASE_ACCESS_TOKEN
# Value: sbp_...
```

---

## Option 1: Add via Claude Code CLI (recommended)

From a terminal in your project (or any folder), run:

**Windows (native):**

```powershell
claude mcp add --transport stdio --env SUPABASE_ACCESS_TOKEN supabase -- cmd /c npx -y @supabase/mcp-server-supabase@latest --read-only --project-ref=rtbjubzgvsedfnumjksu
```

**macOS / Linux / WSL:**

```bash
claude mcp add --transport stdio --env SUPABASE_ACCESS_TOKEN supabase -- npx -y @supabase/mcp-server-supabase@latest --read-only --project-ref=rtbjubzgvsedfnumjksu
```

- `--read-only`: database tools run as read-only (recommended).
- `--project-ref=rtbjubzgvsedfnumjksu`: limits access to this project (from `docs/supabase.md`).

**Scopes:**

- **Local (default):** only this machine, this project → stored in `~/.claude.json`.
- **User:** all your projects → `claude mcp add ... --scope user ...`
- **Project:** team-shared → `claude mcp add ... --scope project ...` (creates/updates `.mcp.json` in project root).

**Check it:**

```bash
claude mcp list
claude mcp get supabase
```

In Claude Code chat, type `/mcp` to see connected servers. Then you can ask things like “list tables in my Supabase project” or “run this SQL …”.

---

## Option 2: Project-level `.mcp.json`

Commit a shared config (no secrets) and have each dev set `SUPABASE_ACCESS_TOKEN` locally.

**1. Create `.mcp.json` in the project root:**

- **Windows:** Copy `.mcp.json.example` to `.mcp.json`.
- **macOS/Linux:** Use the same file but replace the `command`/`args` with:
  `"command": "npx", "args": ["-y", "@supabase/mcp-server-supabase@latest", "--read-only", "--project-ref=rtbjubzgvsedfnumjksu"]` and remove the `cmd /c` wrapper.

Ensure `SUPABASE_ACCESS_TOKEN` is set in your environment (see Prerequisites).

**2. Set your token** (as in Prerequisites above).

**3. Restart Claude Code** so it picks up the new MCP config.

Claude Code will prompt for approval before using project-scoped servers from `.mcp.json`; you only need to approve once per project.

---

## Windows note

On Windows, **stdio** servers that use `npx` must be run via `cmd /c`:

```text
cmd /c npx -y @supabase/mcp-server-supabase@latest ...
```

Otherwise you may see “Connection closed” errors. The CLI command in Option 1 already includes this.

---

## Security (same as Cursor)

- Prefer a **dev** Supabase project, not production.
- Use **`--read-only`** when possible.
- Use **`--project-ref`** so the server only sees one project.
- Review tool calls before approving; don’t expose the MCP to end users.

---

## Reference

- [Claude Code – Connect to tools via MCP](https://code.claude.com/docs/en/mcp)
- [Supabase MCP server (cursormcp.dev)](https://cursormcp.dev/mcp-servers/304-supabase)
- Project ref and schema: `docs/supabase.md`
