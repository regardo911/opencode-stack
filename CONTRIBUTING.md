# Contributing

Fixes welcome. Best kind: a command or config line that broke on a newer opencode, or a model id that left OpenCode Go.

- Say which opencode version you ran (`opencode --version`) and paste the output that shows the problem.
- Every file belongs to a chapter of the book and says which one in its first lines. Keep the book's names (agents, skills, commands, thresholds) so a reader who followed along still recognises them.
- `bash tests/run.sh` must end with `0 failed`. It needs no key; if `opencode` is on your PATH it also checks both configs against it.
- `cost-dash` stays one file that runs on Python 3.9 with nothing installed.
