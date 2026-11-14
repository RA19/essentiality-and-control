"""Run the research algorithms, analyze their state dynamics and render figures.

Usage:
    python examples/build_showcase.py
    python examples/build_showcase.py --figures-only
    python examples/build_showcase.py --octave /path/to/octave-cli
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from grnlab.analysis import analyze
from grnlab.figures import render


def find_octave(explicit=None):
    candidates = [
        explicit,
        os.environ.get("OCTAVE_EXECUTABLE"),
        shutil.which("octave-cli"),
        shutil.which("octave"),
    ]
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidates += sorted(
            (Path(local) / "Programs/GNU Octave").glob("*/mingw64/bin/octave-cli.exe"),
            reverse=True,
        )
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(candidate)
    raise SystemExit(
        "Install GNU Octave and put octave-cli on PATH, or supply --octave."
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--octave", help="Path to octave-cli")
    parser.add_argument(
        "--figures-only", action="store_true", help="Use the bundled algorithm outputs"
    )
    parser.add_argument("--gpb-iterations", type=int, default=200)
    parser.add_argument("--uct-iterations", type=int, default=180)
    args = parser.parse_args()
    if args.gpb_iterations < 1 or args.uct_iterations < 0:
        parser.error(
            "GPB iterations must be positive; UCT iterations may be zero to skip UCT."
        )
    if not args.figures_only:
        executable = find_octave(args.octave)
        expression = (
            "addpath(fullfile(pwd,'examples')); run_essentiality(); run_control(fullfile(pwd,'results','demo'),%d,%d);"
            % (args.gpb_iterations, args.uct_iterations)
        )
        subprocess.run(
            [executable, "--quiet", "--no-gui", "--eval", expression],
            cwd=ROOT,
            check=True,
        )
    data = analyze(ROOT)
    render(data, ROOT)
    print("Results: results/demo/ | Figures: docs/figures/")


if __name__ == "__main__":
    main()
