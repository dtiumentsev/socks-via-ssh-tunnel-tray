# Security Policy

## Supported versions

Security fixes are applied to the latest version on the `main` branch.

## Reporting a vulnerability

Do not open a public issue for vulnerabilities that could expose private keys,
tunnel endpoints, local configuration, or bypass intended access controls.

Report security issues privately to: <your-email-or-GitHub-contact-method>

## Security expectations

- Never commit private SSH keys.
- Keep the SOCKS listener bound to `127.0.0.1`.
- Verify SSH host keys before trusting a new endpoint.
- Keep `config.ps1` outside version control.