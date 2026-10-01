"""One command: import club (if the FUT Web App is open), solve, check live prices, build the page.

  python sbc.py sbcs/england-v-spain.json [--exclude "Name,Name"] [--budget 180]

Read-only end to end: never buys, lists, moves or submits anything.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def run(*args, env=None):
    print(">", " ".join(args), flush=True)
    return subprocess.call([sys.executable, "-u", *args], cwd=HERE, env=env)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    env = dict(os.environ, PYTHONIOENCODING="utf-8", OPENBLAS_NUM_THREADS="1", OMP_NUM_THREADS="1")
    if run("club_snapshot.py", env=env) != 0:
        print("club import skipped (web app not open); using the last club.json")
    extra = ["--club", "club.json"] if os.path.exists(os.path.join(HERE, "club.json")) else []
    if run("optimize.py", *sys.argv[1:], *extra, env=env) != 0:
        raise SystemExit("solve failed")
    run("report.py", env=env)
    name = os.path.splitext(os.path.basename(sys.argv[1]))[0]
    import shutil
    for src, dst in (("sbc-report.html", f"report-{name}.html"), ("result.json", f"result-{name}.json")):
        shutil.copyfile(os.path.join(HERE, src), os.path.join(HERE, dst))
    print("open:", os.path.join(HERE, f"report-{name}.html"))


if __name__ == "__main__":
    main()
