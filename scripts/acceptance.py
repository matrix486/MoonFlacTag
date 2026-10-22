"""Run every locally executable release gate. No external publishing actions."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    for script in ["verify.py", "verify_cli.py", "verify_media_matrix.py", "verify_product.py", "verify_workflow.py", "verify_compatibility.py", "measure_performance.py", "verify_cli_distribution.py", "verify_package.py"]:
        print(f"=== {script} ===", flush=True)
        subprocess.run([sys.executable, str(ROOT / "scripts" / script)], cwd=ROOT, check=True)
    print("PASS all local acceptance gates", flush=True)


if __name__ == "__main__":
    main()
