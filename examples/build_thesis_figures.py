"""Rebuild the two historical result figures from results/thesis/*.csv."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from grnlab.thesis import render_thesis_results

if __name__ == "__main__":
    render_thesis_results(ROOT)
    print("Rebuilt the essentiality and control result figures from the thesis tables.")
