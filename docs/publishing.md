# Publishing

The npm package `desktop-icon-mcp` is published from
`https://github.com/ei-grad/desktop-icon-mcp` with npm trusted publishing and
provenance attestations. The release workflow is
`.github/workflows/publish.yml`.

## Release

1. Update `package.json#version`.
2. Commit the change.
3. Create and push a matching tag:

   ```powershell
   git tag v0.1.1
   git push origin main
   git push origin v0.1.1
   ```

The workflow verifies that `refs/tags/vX.Y.Z` matches `package.json#version`.
It also injects exact GitHub `repository`, `homepage`, and `bugs` metadata into
the publish-time `package.json`. It uses a GitHub-hosted Windows runner, Node
24, `id-token: write`, no npm publish token, and `npm publish --access public`.

## npm Settings

Trusted publisher settings on npmjs.com:

- Provider: GitHub Actions
- Organization or user: `ei-grad`
- Repository: `desktop-icon-mcp`
- Workflow filename: `publish.yml`
- Environment name: blank, unless the workflow later adds a matching GitHub
  environment

No npm publish token is required for regular releases. Keep `NPM_TOKEN` absent
from GitHub Actions secrets.

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
