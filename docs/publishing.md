# Publishing

This package is intended to be published to npm from GitHub Actions using npm
trusted publishing with OIDC. The release workflow is
`.github/workflows/publish.yml`.

## One-Time Bootstrap

npm trusted publishing is configured from an existing package's npmjs.com
settings, so a brand-new package must be created first. For the first publish,
use a temporary manual or token-based publish, then switch the package to
trusted publishing and revoke the token.

Before the first publish:

1. Push this repository to GitHub as a public repository.
2. Set `package.json.repository.url` to the exact GitHub repository URL:

   ```json
   {
     "repository": {
       "type": "git",
       "url": "git+https://github.com/OWNER/REPO.git"
     }
   }
   ```

3. Confirm the npm package name is available or rename `package.json#name`.
4. Publish once:

   ```powershell
   npm publish --access public
   ```

If you want provenance on the very first version too, do that first publish
from GitHub Actions with a temporary `NPM_TOKEN` and `npm publish --provenance
--access public`, then remove that temporary workflow/token. The permanent
workflow in this repo does not use `NPM_TOKEN`.

## Enable Trusted Publishing

On npmjs.com, open the package settings and add a trusted publisher:

- Provider: GitHub Actions
- Organization or user: the GitHub owner
- Repository: the GitHub repo name
- Workflow filename: `publish.yml`
- Environment name: leave blank unless you also add a matching GitHub
  environment to the workflow

After a successful trusted publish, set Publishing access to "Require two-factor
authentication and disallow tokens", then revoke any temporary automation token.

## Release

1. Update `package.json#version`.
2. Commit the change.
3. Create and push a matching tag:

   ```powershell
   git tag v0.1.1
   git push origin v0.1.1
   ```

The workflow verifies that `refs/tags/vX.Y.Z` matches `package.json#version`.
It uses a GitHub-hosted runner, Node 24, `id-token: write`, no npm publish
token, and `npm publish --access public`.

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
