# Draft releases

The `Build draft release` workflow is manually dispatched. It builds one ZIP for
Retail and Forever using BigWigs Packager and attaches it to a GitHub draft release.
It never publishes the release or uploads to CurseForge or Wago.

## First setup

Commit and push `.github/workflows/release.yml`, `.pkgmeta`, the release scripts,
and the remaining project files. The workflow must exist on the repository's default
branch before GitHub shows its **Run workflow** button. No additional secret is
required; the workflow uses GitHub's built-in token with `contents: write` permission.

## Build a version

1. Open **Actions > Build draft release > Run workflow**.
2. Select the branch or tag containing the code to release.
3. Enter a version such as `v0.1.0` or `v0.2.0-beta.1` and start the workflow.
4. Follow the draft link in the run summary and download its addon ZIP.
5. Test installation from the ZIP in the target clients, edit the release notes,
   and select **Publish release** when ready. Mark beta versions as prereleases.

The version must start with `v` and contain three numeric components, optionally
followed by a suffix. If its tag already exists, it must point to the selected
commit. Otherwise the workflow creates an annotated tag only inside the runner
so the packager can resolve `@project-version@`. GitHub's release creation handles
the release tag for the selected commit; no tag is pushed from the runner.

The packaged TOC gets its version from the packaging tag. A source checkout keeps
the literal `@project-version@` placeholder until packaged.

## Re-running

Re-running the same version and commit replaces the ZIP and `checksum.txt` in the existing draft.
The draft's target must match the selected commit. An existing published release
or a mismatched tag/draft causes a failure; use a new version for changed code.
The workflow serializes runs for the same version and does not cancel an upload
when another run is queued.

## Archive checks

The ZIP has one top-level folder, `FrameNetGraph`, containing the TOC, original
license, `Core/`, `UI/`, `Libs/`, and `Media/`. The packager may also add `CHANGELOG.md`.
Embedded library notices and the runtime icon are retained. Screenshots, SVG/PNG
artwork sources, `.env`, editor settings, development scripts, and tests are excluded.

Before creating/updating a draft, `scripts/verify-package.py` checks ZIP integrity,
the full runtime manifest, TOC dependencies and version, and binary texture hashes.
No remote release is modified if this check fails. `scripts/draft-release.py` checks
the existing release state again before uploading. A remote permission or upload
failure can leave a draft that needs to be retried.

After successful verification, `scripts/verify-package.py` creates `.release/checksum.txt`
containing the ZIP's SHA-256 and filename in `sha256sum` format. The checksum is printed
in the workflow log, included in the run summary, and attached alongside the ZIP in the
draft release. It is not placed inside the addon archive.

To verify a download, save both assets in the same directory and run:

```sh
sha256sum -c checksum.txt
```

On PowerShell, use `Get-FileHash .\FrameNetGraph-v0.1.0.zip -Algorithm SHA256` and compare
the result with the hash in `checksum.txt` (substitute the actual ZIP filename).

Local validation cannot replace the first actual Actions run and installation of
its ZIP. Do not publish until those checks pass.
