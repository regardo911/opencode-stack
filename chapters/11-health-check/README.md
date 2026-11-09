# Chapter 11: the Monday health check

```bash
bash chapters/11-health-check/health-check.sh
```

Eight checks, one line each, then `Summary: 8 PASS, 0 FAIL` and exit 0 on a healthy setup. One FAIL makes it exit 1. Check 6 (`~/.config/opencode/skills`) and check 8 (cost-dash rows from the last 7 days) fail until you've done chapters 8 and 9.

The book's version ran `opencode debug rg`, which prints help and exits 1 even with ripgrep installed, so every machine failed it. This one runs `opencode debug rg files`.

Keep it next to your other tools and run it from cron every Monday at 9. Cron starts with a short PATH, so the line below writes in the folder your `opencode` lives in:

```bash
cp chapters/11-health-check/health-check.sh ~/your-project/tools/
( crontab -l 2>/dev/null; echo "0 9 * * 1 PATH=$(dirname "$(command -v opencode)"):/usr/bin:/bin bash $HOME/your-project/tools/health-check.sh > $HOME/health-check.log" ) | crontab -
```

`crontab -l` shows the line it added. On a FAIL the script exits 1 and `~/health-check.log` says which check.

If you keep skills or the store somewhere else: `SKILLS_DIR=... COST_DB=... bash tools/health-check.sh`.
