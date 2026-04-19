Devcontainer setup (secrets + login)

This project uses Podman secrets for credentials. Follow these steps on the remote server (only once per user):

1. Create the Podman secret from your local env file:

```bash
podman secret create azure-creds ~/.config/azure-dev-creds/california.env
```

2. Ensure `devcontainer.json` includes the `runArgs` for the secret (example):

```json
"runArgs": ["--secret", "azure-creds"]
```

3. Rebuild the devcontainer in VS Code: `Rebuild Container`.

What the container does on start

- The `postCreateCommand` runs `.devcontainer/login.sh`, which looks for `/run/secrets/azure-creds` and falls back to `/etc/azure-creds.env` if present.
- The script sources the creds, runs `az login`, then immediately unsets credential env vars.

Notes and troubleshooting

- Podman secrets are per-user for rootless Podman; each user on the server must create the secret under their account.

Security tips

- Keep the host env file readable (`chmod 600`) and out of version control.
- Rotate the service principal secret periodically and keep RBAC minimal.
