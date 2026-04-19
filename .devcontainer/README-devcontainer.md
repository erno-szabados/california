Devcontainer setup (secrets + login)

This project uses Podman secrets for credentials. Follow these steps on the remote server (only once per user):

1. Create the Podman secret from your local env file:

```bash
podman secret create azure-creds-ml-training ~/.config/azure-dev-creds/california.env
```

2. (Optional) Create a GitHub token secret (recommended to store separately):

```bash
printf '%s' "ghp_xxx..." > ~/.config/gh/gh_token
chmod 600 ~/.config/gh/gh_token
podman secret create gh-token-california ~/.config/gh/gh_token
```

3. Ensure `devcontainer.json` includes the `runArgs` for the secrets (example):

```json
"runArgs": ["--secret", "azure-creds-ml-training", "--secret", "gh-token-california"]
```

3. Rebuild the devcontainer in VS Code: `Rebuild Container`.

What the container does on start

- The `postCreateCommand` runs `.devcontainer/login.sh`, which looks for `/run/secrets/azure-creds` and `/run/secrets/github-token`.
- The script performs `az login` (using the env-file format) and `gh auth login --with-token` (reads token from stdin), then unsets any in-memory vars. It also tightens permissions on `~/.config/gh/hosts.yml` if created.

Notes and troubleshooting

- Podman secrets are per-user for rootless Podman; each user on the server must create the secret under their account.

Security tips

- Keep the host env file readable (`chmod 600`) and out of version control.
- Rotate the service principal secret periodically and keep RBAC minimal.
