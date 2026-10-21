# Project update policy

- Always use upstream releases for Nginx, PHP and Composer. Do not substitute
  Alpine distribution packages for these components.
- Use the latest released Nginx mainline, stable PHP (no release candidates),
  and stable Composer when updating. Verify published artifacts are available.
- Keep versions explicit, verify source checksums, and update README.md together
  with the build. Historical branch rows must not claim unbuilt upgrades.
- Build with fresh upstream layers and run tests/smoke.sh against the result.
- Preserve existing configuration mount paths where possible; document migrations.
