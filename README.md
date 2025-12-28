# Windows-Tweaks-Hub

A curated hub of **Windows scripts, tweaks, and hacks** focused on improving productivity, privacy, and system setup.

<p align="left">
  <a href="https://www.rinkurapria.dev/" target="_blank" rel="noopener">
    <img alt="Portfolio" src="https://img.shields.io/badge/Portfolio-rinkurapria.dev-0A66C2?style=for-the-badge">
  </a>
  <a href="https://www.rinkurapria.dev/blog/" target="_blank" rel="noopener">
    <img alt="Blogs" src="https://img.shields.io/badge/Blogs-rinkurapria.dev%2Fblog-111827?style=for-the-badge">
  </a>
</p>

## What you’ll find here
- **PowerShell / CMD / Registry** tweaks (where applicable)
- **Setup scripts** for fresh installs and common tooling
- **Quality-of-life** improvements for Windows workflows
- Notes on **reverting** changes (when supported)

## Table of contents
- [Getting started](#getting-started)
- [Safety notes](#safety-notes)
- [Repository structure](#repository-structure)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)

## Getting started
> Recommended: test changes in a VM or a non-critical machine first.

General usage pattern:
1. Review the script/tweak first.
2. Create a restore point (or backup relevant keys/files).
3. Run with appropriate privileges (often **Administrator**).

## Safety notes
- Prefer **reversible** tweaks when possible.
- Be careful with:
  - registry edits
  - disabling services/telemetry components
  - policies that affect updates/security features
- If a tweak modifies registry values, document:
  - what keys are touched
  - expected impact
  - how to revert

## Repository structure
This repo will organize content like:
- `scripts/` — automation and setup scripts
- `tweaks/` — focused tweaks with documentation
- `hacks/` — advanced/experimental changes (extra caution)

> If these folders don’t exist yet, they’ll be added as the repo grows.

## Contributing
PRs are welcome:
- keep changes scoped and documented
- include revert instructions when possible
- avoid bundling unrelated tweaks together

## Disclaimer
All scripts and tweaks are provided **as-is**. You’re responsible for reviewing and understanding changes before applying them. Use at your own risk.

---
### Links
- Portfolio: https://www.rinkurapria.dev/
- Blogs: https://www.rinkurapria.dev/blog/