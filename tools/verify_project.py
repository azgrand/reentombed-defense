"""Run all milestone checks with Godot, treating runtime errors as failures."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
args = parser.parse_args()

def run(command, editor=False):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240)
    print(result.stdout)
    errors = [line for line in result.stdout.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
    if editor:
        errors = [line for line in errors if '_sock == -1' not in line and 'ERR_CANT_CREATE' not in line]
    if result.returncode or errors:
        raise SystemExit(f'Check failed: {command}; exit {result.returncode}; errors {errors}')

run([sys.executable, 'tools/check_project.py'])
run([args.godot, '--headless', '--path', '.', '--editor', '--import', '--quit'], editor=True)
for script in [ROOT / 'tests/run_tests.gd', *sorted((ROOT / 'tests').glob('test_*.gd'))]:
    run([args.godot, '--headless', '--path', '.', '--script', str(script.relative_to(ROOT))])
run([args.godot, '--headless', '--path', '.', '--quit-after', '120'])
print('All project checks passed.')
