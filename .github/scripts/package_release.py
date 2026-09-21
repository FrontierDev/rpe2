#!/usr/bin/env python3
"""Build and validate a deterministic RPEngine release archive."""

from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path, PurePosixPath

ADDON_ROOT = "RPEngine2"
TOC_NAME = "RPEngine2.toc"
RUNTIME_DIRECTORIES = ("api", "client", "core", "data", "server", "utils")
FIXED_ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


def parse_toc_version(contents: str) -> str:
    for raw_line in contents.splitlines():
        line = raw_line.strip()
        if not line.startswith("##"):
            continue
        metadata = line[2:].strip()
        if ":" not in metadata:
            continue
        name, value = metadata.split(":", 1)
        if name.strip().lower() == "version":
            version = value.strip()
            if version:
                return version
            break
    raise ValueError(f"{TOC_NAME} does not contain a usable ## Version field")


def toc_references(contents: str) -> set[PurePosixPath]:
    references: set[PurePosixPath] = set()
    for raw_line in contents.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        path = PurePosixPath(line.replace("\\", "/"))
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"Unsafe path in {TOC_NAME}: {line}")
        references.add(path)
    return references


def release_files(repository_root: Path, toc_contents: str) -> list[Path]:
    files: set[Path] = {repository_root / TOC_NAME}

    for directory_name in RUNTIME_DIRECTORIES:
        directory = repository_root / directory_name
        if not directory.is_dir():
            raise ValueError(f"Required runtime directory is missing: {directory_name}")
        for path in directory.rglob("*"):
            if path.is_file():
                files.add(path)

    for reference in toc_references(toc_contents):
        path = repository_root.joinpath(*reference.parts)
        if not path.is_file():
            raise ValueError(f"{TOC_NAME} references missing file: {reference}")
        files.add(path)

    resolved_root = repository_root.resolve()
    for path in files:
        if path.is_symlink():
            raise ValueError(f"Release input must not contain symlinks: {path}")
        try:
            path.resolve().relative_to(resolved_root)
        except ValueError as error:
            raise ValueError(f"Release input escapes repository root: {path}") from error

    return sorted(files, key=lambda path: path.relative_to(repository_root).as_posix())


def write_archive(repository_root: Path, files: list[Path], archive_path: Path) -> None:
    with zipfile.ZipFile(
        archive_path,
        mode="w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        for path in files:
            relative = path.relative_to(repository_root).as_posix()
            archive_name = f"{ADDON_ROOT}/{relative}"
            info = zipfile.ZipInfo(archive_name, FIXED_ZIP_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def validate_archive(archive_path: Path, expected_version: str) -> None:
    excluded_roots = {".git", ".github", ".docs", ".vscode", "docs", "tests"}
    excluded_files = {"TASK.MD", "RPEngine_Dev.code-workspace", "SOURCE-REPO.txt"}

    with zipfile.ZipFile(archive_path, mode="r") as archive:
        names = archive.namelist()
        if not names:
            raise ValueError("Release archive is empty")
        if len(names) != len(set(names)):
            raise ValueError("Release archive contains duplicate entries")

        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"Unsafe archive path: {name}")
            if not path.parts or path.parts[0] != ADDON_ROOT:
                raise ValueError(f"Archive entry is outside {ADDON_ROOT}/: {name}")
            relative_parts = path.parts[1:]
            if not relative_parts:
                continue
            if relative_parts[0] in excluded_roots:
                raise ValueError(f"Repository-only directory leaked into archive: {name}")
            if len(relative_parts) == 1 and relative_parts[0] in excluded_files:
                raise ValueError(f"Repository-only file leaked into archive: {name}")

        toc_archive_path = f"{ADDON_ROOT}/{TOC_NAME}"
        if toc_archive_path not in names:
            raise ValueError(f"Archive is missing {toc_archive_path}")
        packaged_toc = archive.read(toc_archive_path).decode("utf-8-sig")
        packaged_version = parse_toc_version(packaged_toc)
        if packaged_version != expected_version:
            raise ValueError(
                f"Packaged version {packaged_version!r} does not match expected version {expected_version!r}"
            )

        for reference in toc_references(packaged_toc):
            expected_path = f"{ADDON_ROOT}/{reference.as_posix()}"
            if expected_path not in names:
                raise ValueError(f"Archive is missing TOC-referenced file: {expected_path}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--output-dir", default="dist")
    parser.add_argument("--repository-root", default=".")
    args = parser.parse_args()

    repository_root = Path(args.repository_root).resolve()
    toc_path = repository_root / TOC_NAME
    if not toc_path.is_file():
        raise ValueError(f"Missing {TOC_NAME}")

    toc_contents = toc_path.read_text(encoding="utf-8-sig")
    toc_version = parse_toc_version(toc_contents)
    if toc_version != args.version:
        raise ValueError(
            f"Release version {args.version!r} does not match {TOC_NAME} version {toc_version!r}"
        )

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    archive_path = output_dir / f"{ADDON_ROOT}-{args.version}.zip"
    checksum_path = output_dir / f"{archive_path.name}.sha256"

    files = release_files(repository_root, toc_contents)
    write_archive(repository_root, files, archive_path)
    validate_archive(archive_path, args.version)

    checksum = sha256_file(archive_path)
    checksum_path.write_text(f"{checksum}  {archive_path.name}\n", encoding="ascii")

    print(f"Built {archive_path}")
    print(f"SHA-256 {checksum}")
    print(f"Packaged {len(files)} files for RPEngine {args.version}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"release packaging failed: {error}", file=sys.stderr)
        raise SystemExit(1)
