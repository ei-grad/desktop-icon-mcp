# Publishing

This package is intended to be published to npm from GitHub Actions using npm
trusted publishing with OIDC. The release workflow is
`.github/workflows/publish.yml`.

## One-Time Bootstrap

npm trusted publishing is configured from an existing package's npmjs.com
settings, so a brand-new package must be created first. Use the one-time
bootstrap workflow to publish the first version from GitHub Actions with a
temporary token and provenance, then switch the package to trusted publishing
and revoke the token.

Before the first publish:

1. Push this repository to GitHub as a public repository.
2. Confirm the npm package name is available or rename `package.json#name`.
3. Create a temporary npm automation token and save it as the GitHub Actions
   secret `NPM_TOKEN`.
4. Run `.github/workflows/bootstrap-publish.yml` manually with confirmation:

   ```powershell
   publish desktop-icon-mcp@0.1.0
   ```

The bootstrap workflow runs tests, checks package contents, injects the exact
GitHub `repository`, `homepage`, and `bugs` metadata into the publish-time
`package.json`, then runs `npm publish --provenance --access public`.

## Enable Trusted Publishing

On npmjs.com, open the package settings and add a trusted publisher:

- Provider: GitHub Actions
- Organization or user: the GitHub owner
- Repository: the GitHub repo name
- Workflow filename: `publish.yml`
- Environment name: leave blank unless you also add a matching GitHub
  environment to the workflow

After a successful trusted publish, set Publishing access to "Require two-factor
authentication and disallow tokens", then revoke the temporary automation token
and delete the `NPM_TOKEN` GitHub secret.

## Release

1. Update `package.json#version`.
2. Commit the change.
3. Create and push a matching tag:

   ```powershell
   git tag v0.1.1
   git push origin v0.1.1
   ```

The workflow verifies that `refs/tags/vX.Y.Z` matches `package.json#version`.
It also injects exact GitHub `repository`, `homepage`, and `bugs` metadata into
the publish-time `package.json`. It uses a GitHub-hosted runner, Node 24,
`id-token: write`, no npm publish token, and `npm publish --access public`.

## Provenance

Trusted publishing from GitHub Actions automatically publishes npm provenance
attestations for public packages from public repositories. The workflow also
sets `NPM_CONFIG_PROVENANCE=true` so provenance remains explicit.

Consumers can verify installed package attestations with:

```powershell
npm audit signatures
```

References:

- npm trusted publishing: https://docs.npmjs.com/trusted-publishers/
- npm provenance statements: https://docs.npmjs.com/generating-provenance-statements
- viewing/verifying provenance: https://docs.npmjs.com/viewing-package-provenance
