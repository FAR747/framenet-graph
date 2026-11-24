"""Create or update a draft; never publish or replace assets on a public release."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys


def run(*arguments):
    return subprocess.check_output(arguments, text=True).strip()


def main(version, archive, checksum):
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[a-zA-Z0-9]+(?:[.-][a-zA-Z0-9]+)*)?", version):
        raise ValueError("Invalid release version")
    repository = os.environ["GITHUB_REPOSITORY"]
    commit = run("git", "rev-parse", "HEAD")
    pages = json.loads(run("gh", "api", "--paginate", "--slurp", f"repos/{repository}/releases?per_page=100"))
    matches = [release for page in pages for release in page if release["tag_name"] == version]
    if matches:
        release = matches[0]
        if not release["draft"]:
            raise ValueError("This release is already published; choose a new version")
        if release["target_commitish"] != commit:
            raise ValueError("The existing draft targets another commit; choose a new version")
        run("gh", "release", "upload", version, archive, checksum, "--repo", repository, "--clobber")
        url = release["html_url"]
    else:
        notes = Path(os.environ["RUNNER_TEMP"]) / "framenet-release-notes.md"
        notes.write_text(
            f"FrameNet Graph {version}\n\n"
            "Supports WoW Retail and Forever.\n\n"
            "Download the addon ZIP and extract `FrameNetGraph` into your client's "
            "`Interface/AddOns` directory.\n\n"
            f"Built from commit `{commit}`.\n\n"
            "Before publishing, test installation from this ZIP and edit these release notes.\n",
            encoding="utf-8",
        )
        url = run("gh", "release", "create", version, archive, checksum, "--repo", repository,
                  "--draft", "--target", commit, "--title", f"FrameNet Graph {version}",
                  "--notes-file", str(notes))
    print(f"Draft release: {url}")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
            summary.write(f"### Draft ready\n\n[{version}]({url})\n\nDownload and test the ZIP before publishing.\n")
            summary.write(f"\nSHA-256 (`checksum.txt`):\n\n```text\n{Path(checksum).read_text(encoding='utf-8')}```\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
