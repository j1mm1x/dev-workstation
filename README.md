# dev-workstation

An Ansible-first workstation framework for `j1mm1x/dev-workstation`. Task 001 establishes a validation-only scaffold for native Apple Silicon macOS. Installation roles are intentionally pending.

## Terminal target

The workstation runs directly on the user's Mac. The intended toolset includes kubectl, Docker CLI, Docker Compose, Colima, Devbox and fzf, with Zsh configured through Oh My Zsh. Colima provides an optional local container runtime. Docker CLI may connect to an existing remote engine.

The shell milestone will install a managed configuration fragment and show the proposed `.zshrc` integration before applying it. Existing aliases, prompt settings and shell files must be preserved. Changes to existing files require a verified backup and explicit approval. The selected Oh My Zsh theme is `agnoster`. Plugins remain to be selected. Credentials and Kubernetes or Docker authentication remain outside the repository.

Task 001 records this target. The example retains disabled features until their roles are implemented and verified.

## Run

Run `./bootstrap.sh` to preview the workstation package plan. Run `./bootstrap.sh --apply` to install kubectl, Docker CLI, Docker Compose, Colima, Devbox and fzf using Homebrew for kubectl, Docker CLI, Docker Compose, Colima and fzf, and the official Jetify installer for Devbox. Ansible is optional for future configuration work. If Homebrew is missing, the bootstrap offers its official installer with explicit confirmation. Devbox installation also requests confirmation before invoking its installer. Devbox may require Nix setup before project environments can run.

The apply step also clones Oh My Zsh from its upstream default branch when absent. Run `./bootstrap.sh --configure-shell` to back up an existing `.zshrc` and append Agnoster configuration with the `git` plugin. Existing Oh My Zsh configuration and `.zshrc` symlinks require manual review. Choose a Powerline-compatible font in your terminal for Agnoster symbols. Font installation and selection are manual.

Run `./bootstrap.sh --check-containers` to report the current Docker context, whether its engine is reachable, and whether the default Colima profile is running. The check leaves startup and context selection to you. If `DOCKER_HOST` overrides the endpoint, the check reports that override without displaying its value.

Homebrew provides the `docker-compose` command. After starting Colima, use `docker --context colima info` to verify engine access and `docker-compose version` to check Compose.

## Layout

- `bootstrap.sh` detects OS and architecture and invokes Ansible.
- `ansible/site.yml` orchestrates shared roles and the macOS adapter.
- `ansible/roles/platform_*` own package manager integration.
- `config/` contains the versioned declarative configuration example.
- `docs/adr/` records architecture decisions.
- `docs/validation.md` describes verification and release gates.
- `tests/` exercises bootstrap behavior without configuring the host.

## Milestones

1. Implement typed configuration validation and capability-to-package mappings for Homebrew. Require existing Homebrew or a separately consented installer.
2. Implement runtime discovery and conflict reporting for Colima and Docker CLI. Starting Colima requires explicit consent because it can change the active Docker context. Preserve existing contexts and sockets.
3. Implement Devbox availability checks and installation. Treat Nix installation as a separate privileged operation with opt-in. Projects own `devbox.json` and `devbox.lock`.
4. Implement Zsh and Oh My Zsh integration, fzf shell integration and CLI completions. Provide a preview of managed settings, collision detection, per-file consent and backups for existing shell files. Include kubectl and Docker CLI in the macOS capability mappings.
5. Implement Debian/Ubuntu apt and Fedora dnf adapters, native Docker Engine installation and scoped privilege authorization. Docker group membership requires explicit consent because it grants powerful host access.

Colima's documented context behavior informs the runtime safeguard. [Colima FAQ](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md)
