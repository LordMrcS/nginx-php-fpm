# Project update policy

- Always use upstream releases for Nginx, PHP and Composer. Do not substitute
  distribution packages for these components.
- Use the latest released Nginx mainline and stable Composer on every branch.
  Keep PHP on the branch's existing minor line (8.2, 8.3, 8.4 or 8.5), using
  its latest stable patch release, never a release candidate. Verify artifacts
  are available. PHP 8.1 is retired.
- Keep versions explicit, verify source checksums, and update README.md together
  with the build. Historical branch rows must not claim unbuilt upgrades.
- Build with fresh upstream layers and run tests/smoke.sh against the result.
- Preserve existing configuration mount paths where possible; document migrations.
