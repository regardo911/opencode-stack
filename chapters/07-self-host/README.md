# Chapter 7: a fixer on your own machine

[`opencode.ch07.jsonc`](opencode.ch07.jsonc) adds Ollama as a provider and three agents that use it: `local-fixer` (Project #5), plus the `orchestrator-local` / `fixer-local` pair. Every model call goes to `127.0.0.1:11434`, and `webfetch` is denied so the agent cannot fetch pages either.

Copy the provider block carefully. The book's version fails (see [BOOK-FIXES.md](../../BOOK-FIXES.md)); this one runs on opencode 1.4.3 and 1.19.5.

## Run it

```bash
brew install ollama            # Linux: curl -fsSL https://ollama.com/install.sh | sh
ollama serve                   # leave it running in its own pane
ollama pull qwen3.5:9b         # 6.6 GB
```

Merge the file into `~/.config/opencode/opencode.json` (the book's place for it), or copy it to `<your project>/opencode.json`. Then from your project:

```bash
opencode debug agent local-fixer     # "providerID": "ollama", "modelID": "qwen3.5:9b"
opencode --agent local-fixer
```

Give it a small real task, such as adding one endpoint. While it works, watch the wire from a second pane:

```bash
sudo tcpdump -i any 'host api.deepseek.com or host api.anthropic.com or host api.openai.com or host opencode.ai' -n
```

On macOS, swap `-i any` for `-i en0` if `any` errors. Zero packets during the session means the session stayed local. A packet means something is calling out; the book's first suspects are a telemetry plugin and a `webfetch` you forgot to deny.

Then log it:

```bash
chapters/09-cost-dashboard/cost-dash log --project project-05-self-host --last --csv ~/your-project/cost-log.csv
```

Project #5 is done when the session ran against `localhost:11434`, your tcpdump pane printed no packets, and `cost-log.csv` has a row with model `ollama/qwen3.5:9b` and `cost_usd` `0.0000`.

## Pick the tag for your machine

| Your machine | Pull | Agents that use it |
|---|---|---|
| 16 GB Mac (the book's tier 1) | `qwen3.5:9b` (6.6 GB) | `local-fixer`, `fixer-local` |
| 24 GB GPU (the book's tier 2) | `qwen3.6:27b` (17.8 GB) | `orchestrator-local` |

A tag works only when it is in two places: under `provider.ollama.models` in the config, and in `ollama list`. If you pull something else, change both. The local pair needs both pulls.

The book's three failure fixes, as commands: out of memory, pull a smaller tag; garbage after turn 15, `ollama show <tag>` for the context length and `/compact` in the TUI; text that runs past the answer, `ollama show <tag> --modelfile` and pull the tag again.
