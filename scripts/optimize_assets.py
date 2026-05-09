#!/usr/bin/env python3
"""
Asset optimization script for FamilyHub.
Converts PNG/JPEG assets to WebP and generates optimization report.

Requires: cwebp (libwebp) installed and on PATH.
Install on Windows: https://developers.google.com/speed/webp/docs/precompiled

Usage:
    python scripts/optimize_assets.py
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def find_bin(name: str) -> str | None:
    """Find executable on PATH."""
    for path in os.environ.get("PATH", "").split(os.pathsep):
        exe = Path(path) / (name + ".exe" if sys.platform == "win32" else name)
        if exe.exists():
            return str(exe)
    return None


def get_file_size(path: Path) -> int:
    return path.stat().st_size


def format_size(size: int) -> str:
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


def convert_to_webp(input_path: Path, output_path: Path, quality: int = 85) -> bool:
    """Convert image to WebP using cwebp."""
    cwebp = find_bin("cwebp")
    if cwebp is None:
        print("ERROR: cwebp not found. Install libwebp: https://developers.google.com/speed/webp/docs/precompiled")
        return False

    cmd = [cwebp, "-q", str(quality), str(input_path), "-o", str(output_path)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        return result.returncode == 0
    except Exception as e:
        print(f"ERROR converting {input_path}: {e}")
        return False


def main():
    assets_dir = Path("assets")
    if not assets_dir.exists():
        print(f"ERROR: {assets_dir} not found")
        sys.exit(1)

    # Supported image extensions
    extensions = {".png", ".jpg", ".jpeg"}

    # Find all image files
    images = []
    for ext in extensions:
        images.extend(assets_dir.rglob(f"*{ext}"))

    if not images:
        print("No images found in assets/")
        sys.exit(0)

    print(f"Found {len(images)} image(s) in assets/\n")

    report = {
        "total_images": len(images),
        "converted": 0,
        "skipped": 0,
        "errors": 0,
        "original_size": 0,
        "optimized_size": 0,
        "details": [],
    }

    for img in sorted(images):
        original_size = get_file_size(img)
        report["original_size"] += original_size

        webp_path = img.with_suffix(".webp")

        # Skip if WebP already exists and is newer
        if webp_path.exists() and webp_path.stat().st_mtime >= img.stat().st_mtime:
            webp_size = get_file_size(webp_path)
            report["optimized_size"] += webp_size
            report["skipped"] += 1
            print(f"  SKIP {img} (webp already exists)")
            report["details"].append({
                "file": str(img),
                "action": "skipped",
                "original": original_size,
                "optimized": webp_size,
            })
            continue

        if convert_to_webp(img, webp_path):
            webp_size = get_file_size(webp_path)
            report["optimized_size"] += webp_size
            report["converted"] += 1
            saved = original_size - webp_size
            pct = (saved / original_size * 100) if original_size > 0 else 0
            print(f"  OK   {img} -> {format_size(saved)} saved ({pct:.1f}%)")
            report["details"].append({
                "file": str(img),
                "action": "converted",
                "original": original_size,
                "optimized": webp_size,
            })
        else:
            report["errors"] += 1
            report["optimized_size"] += original_size
            print(f"  ERR  {img}")
            report["details"].append({
                "file": str(img),
                "action": "error",
                "original": original_size,
                "optimized": original_size,
            })

    total_saved = report["original_size"] - report["optimized_size"]
    total_pct = (total_saved / report["original_size"] * 100) if report["original_size"] > 0 else 0

    print(f"\n{'='*50}")
    print(f"Total images:    {report['total_images']}")
    print(f"Converted:       {report['converted']}")
    print(f"Skipped:         {report['skipped']}")
    print(f"Errors:          {report['errors']}")
    print(f"Original size:   {format_size(report['original_size'])}")
    print(f"Optimized size:  {format_size(report['optimized_size'])}")
    print(f"Space saved:     {format_size(total_saved)} ({total_pct:.1f}%)")
    print(f"{'='*50}")

    # Save report
    report_path = Path("output/asset_optimization_report.json")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"\nReport saved to: {report_path}")


if __name__ == "__main__":
    main()
