# Engineering standards

Keep bootstrap compatible with macOS Bash 3.2. Use strict mode and quoted arrays. Bootstrap detects the host and invokes Ansible. Package installation belongs exclusively to platform adapters.

Use fully qualified Ansible modules, explicit changed conditions for commands, and idempotent tasks. Shared roles express capabilities through adapter contracts. Fail on unsupported configurations. Add regression tests for safety boundaries. Run shell syntax checks, bootstrap tests, Ansible syntax validation and check mode before review.

Preserve existing dotfiles by default. Any future replacement requires per-file consent and a verified backup. Detect existing container applications, contexts and sockets before runtime changes. Require an explicit migration plan and consent before replacement. Privileged tasks require both a scoped configuration opt-in and interactive become authorization. Never enable become globally.

Keep credentials, tokens, private keys and machine-specific configuration out of version control. Inspect staged changes for secrets. Use external secret references and no_log for sensitive tasks. Document architecture changes in an ADR. Keep changes small and avoid unrelated formatting.
