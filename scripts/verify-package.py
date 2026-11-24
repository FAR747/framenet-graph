"""Check the installable ZIP before attaching it to a draft release (stdlib only)."""

import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile


def verify_archive(archive_path, version, source_root):
    runtime_directories = ("Core", "UI", "Libs", "Media")
    expected = {"FrameNetGraph.toc", "LICENSE"}
    for directory in runtime_directories:
        expected.update(
            path.relative_to(source_root).as_posix()
            for path in (source_root / directory).rglob("*")
            if path.is_file() and path.name != ".gitkeep"
        )

    with zipfile.ZipFile(archive_path) as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
        files = [entry.filename for entry in archive.infolist() if not entry.is_dir()]
        if len(files) != len(set(files)):
            raise ValueError("ZIP contains duplicate files")
        for name in archive.namelist():
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or "\\" in name or path.parts[0] != "FrameNetGraph":
                raise ValueError(f"Invalid addon path: {name}")
        contents = {name.removeprefix("FrameNetGraph/") for name in files}
        missing = expected - contents
        extra = contents - expected - {"CHANGELOG.md"}
        if missing or extra:
            raise ValueError(f"Archive manifest mismatch: missing={sorted(missing)}, extra={sorted(extra)}")

        toc = archive.read("FrameNetGraph/FrameNetGraph.toc").decode("utf-8-sig")
        packaged_version = re.search(r"^## Version:\s*(\S+)", toc, re.MULTILINE)
        if not packaged_version or packaged_version[1] not in (version, version.removeprefix("v")):
            raise ValueError("TOC version does not match the release tag")
        for line in toc.splitlines():
            entry = line.strip().replace("\\", "/")
            if entry and not entry.startswith("#") and entry not in contents:
                raise ValueError(f"Missing TOC dependency: {entry}")

        # Binary assets must survive packaging unchanged, including their alpha channels.
        for relative_path in expected:
            if relative_path.endswith(".tga"):
                original = (source_root / relative_path).read_bytes()
                packaged = archive.read("FrameNetGraph/" + relative_path)
                if hashlib.sha256(original).digest() != hashlib.sha256(packaged).digest():
                    raise ValueError(f"Changed runtime texture: {relative_path}")


if __name__ == "__main__":
    release_dir, version = sys.argv[1:]
    archives = list(Path(release_dir).glob("*.zip"))
    if len(archives) != 1:
        raise SystemExit(f"Expected one addon ZIP, found {len(archives)}")
    verify_archive(archives[0], version, Path(__file__).resolve().parent.parent)
    print(f"Verified {archives[0]}")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            output.write(f"archive={archives[0].resolve().as_posix()}\n")
