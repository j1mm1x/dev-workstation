# Timestamp and command duration prompt

Keep upstream Agnoster untouched. The versioned fragment adds a date/time on the **left** and the last command duration on the **right** when it took at least one second. No date is repeated on the right. Zsh extended history is also enabled.

## Migrate from the hand-edited Atlas setup

On **each** Mac (Atlas and Neo), edit the existing shell setup first:

```sh
vim ~/.zshrc
```

- Set `ZSH_THEME="agnoster"`, not `agnoster-timestamp`.
- Remove only the old `source "$HOME/.config/zsh/command-timer.zsh"` line, if present. Keep the legacy file as a rollback backup until verified.
- Do not delete any existing non-managed shell configuration.

Then in a clone of this repository:

```sh
bash scripts/configure-prompt.sh          # preview only
bash scripts/configure-prompt.sh --apply  # explicit authorization
exec zsh
sleep 2
false
```

A new prompt should show one local `YYYY-MM-DD HH:MM:SS` timestamp on the left and a duration on the right for the `sleep 2` command. The failure status should still be indicated by Agnoster after `false`.

Run `bash scripts/configure-prompt.sh --apply` a second time: no duplicate source line should be added. Use `grep -nF '# dev-workstation prompt (managed)' ~/.zshrc` to verify.

The installer refuses to run if it finds an old timestamp theme or legacy timer source still enabled. It never deletes those files or edits the upstream theme.

## Rollback

The installer prints the path to each verified backup it creates. Restore that .zshrc backup if necessary, or remove the two-line managed block from `~/.zshrc` with `vim` and start a new shell. The earlier Agnoster customization and timer files remain available for manual restoration. No global Zsh installation or privileged files are changed.

## Limitations

The elapsed time is wall-clock time from Zsh `preexec` to the next `precmd`, not CPU time. Interactive commands include time spent inside the program. Pasted multiline submissions may be timed as one unit. Clock time follows the host's time zone. Prompt hooks are for interactive Zsh only.
