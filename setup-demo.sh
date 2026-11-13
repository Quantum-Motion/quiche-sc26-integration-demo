#!/usr/bin/env bash

# Sets up the virtual environment "quiche-cudaq-integration-demo" for the QUICHE +
# CUDA-Q demo (FeSH4_demo.ipynb): QUICHE from its feature/integration-demo branch on
# GitHub (with its CUDA-Q extra), and the demo with everything it needs
# (pyproject.toml: the ORCA Python interface, Open MPI, Plotly, Jupyter, ...),
# registered as a Jupyter kernel. It can be run from any directory, and from any
# shell (bash, zsh, ...): it always runs under bash, and doesn't use any functions or
# aliases from your shell configuration.
#
# Run it with:  bash setup-demo.sh   (or ./setup-demo.sh)
#
# Options (environment variables):
#   PYTHON_BIN=/path/to/python bash setup-demo.sh  # interpreter to build the venv from (default: searched for, see below)
#   VENV_HOME=/path/to/venvs bash setup-demo.sh    # where the venv is created (default: ~/.venvs)
#   KERNEL_NAME=my-kernel bash setup-demo.sh       # Jupyter kernel name (default: quiche-cudaq-integration-demo, like the venv)
#   UPDATE_QUICHE=1 bash setup-demo.sh             # rebuild QUICHE from the latest commit of the branch
#   bash setup-demo.sh run                         # start JupyterLab in the demo directory afterwards
#   bash setup-demo.sh test                        # run the notebook from beginning to end afterwards
#                                                  # (into FeSH4_demo.executed.ipynb; the original is untouched)

# Started with zsh or sh instead of bash (e.g. `zsh setup-demo.sh`)? Stop, with a
# hint. Written in plain sh syntax, so that any shell can read it.
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Run this script with bash: bash setup-demo.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# Sourcing it would apply `set -e` and `exit` to your own shell, which closes the
# terminal on the first error.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "Don't source this script; run it with: bash ${BASH_SOURCE[0]}" >&2
    return 1
fi

# Works with bash 3.2 too, the version macOS ships as /bin/bash.
set -Eeuo pipefail

env_name="quiche-cudaq-integration-demo"

# Keep a copy of all output, and say where it failed, so an error is never lost.
script_name="$(basename "$0")"
log="$HOME/$env_name-setup.log"
exec > >(tee "$log") 2>&1
on_error='echo "$script_name failed at line $LINENO: $BASH_COMMAND (full log: $log)" >&2'
trap "$on_error" ERR

PYTHON_BIN="${PYTHON_BIN:-}"
VENV_HOME="${VENV_HOME:-$HOME/.venvs}"
KERNEL_NAME="${KERNEL_NAME:-$env_name}"
UPDATE_QUICHE="${UPDATE_QUICHE:-0}"
action="${1:-}"

case "$action" in
    ""|run|test) ;;
    *) echo "Unknown argument '$action' (expected nothing, 'run' or 'test')." >&2; exit 1 ;;
esac

venv_dir="$VENV_HOME/$env_name"
demo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$demo_dir/pyproject.toml" ] || [ ! -f "$demo_dir/FeSH4_demo.ipynb" ]; then
    echo "Error: $demo_dir doesn't look like the demo directory (no pyproject.toml or FeSH4_demo.ipynb)." >&2
    exit 1
fi

# QUICHE is installed from GitHub and built from source: pip needs git to fetch it,
# and a C++ compiler to build its extension. (CMake is fetched from PyPI if missing.)
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is needed to install QUICHE from GitHub, but it isn't on PATH." >&2
    exit 1
fi
if ! command -v "${CXX:-c++}" >/dev/null 2>&1 && ! command -v g++ >/dev/null 2>&1 \
    && ! command -v clang++ >/dev/null 2>&1; then
    echo "Error: a C++ compiler is needed to build QUICHE, but none was found (c++, g++, clang++)." >&2
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "Install one with: xcode-select --install" >&2
    fi
    exit 1
fi

# Find a Python to build the venv from. It must be:
#  - Python 3.12 or 3.13: QUICHE needs 3.12+, and CUDA-Q 0.15, the version
#    cudaq-algorithms 0.1.0 supports, has no wheels for Python 3.14 yet;
#  - complete: QUICHE compiles a C++ extension against the Python C headers
#    (Python.h), which some system Pythons leave out (on RHEL they are in the
#    separate python3.X-devel package, on Debian/Ubuntu in python3.X-dev), and the
#    venv needs venv and ensurepip.
python_problem() {
    # Print why the Python "$1" can't be used, or nothing if it can.
    "$1" - 2>/dev/null <<'PYEOF' || echo "does not run"
import importlib.util, os, sys, sysconfig
major, minor = sys.version_info[:2]
if not (3, 12) <= (major, minor) <= (3, 13):
    print(f"Python {major}.{minor} (need 3.12 or 3.13 for QUICHE and CUDA-Q)")
elif not os.path.exists(os.path.join(sysconfig.get_paths()["include"], "Python.h")):
    print(f"Python {major}.{minor} without its C headers (Python.h)")
elif not (importlib.util.find_spec("venv") and importlib.util.find_spec("ensurepip")):
    print(f"Python {major}.{minor} without the venv/ensurepip modules")
PYEOF
}

# Candidates: PYTHON_BIN if set; otherwise the Pythons on PATH (including an
# active conda environment), then those of conda environments, pyenv and uv.
candidates=()
if [ -n "$PYTHON_BIN" ]; then
    candidates=("$PYTHON_BIN")
else
    for name in python3.13 python3.12 python3 python; do
        if command -v "$name" >/dev/null 2>&1; then
            candidates+=("$(command -v "$name")")
        fi
    done
    conda_base="$(conda info --base 2>/dev/null || true)"
    for path in "$HOME"/.conda-envs/*/bin/python3 "$HOME"/.conda/envs/*/bin/python3 \
        "${conda_base:-/nonexistent}"/envs/*/bin/python3 \
        "${conda_base:-/nonexistent}"/bin/python3 "$HOME"/.pyenv/versions/*/bin/python3 \
        "$HOME"/.local/share/uv/python/*/bin/python3; do
        if [ -x "$path" ]; then
            candidates+=("$path")
        fi
    done
fi

python_bin=""
for candidate in ${candidates[@]+"${candidates[@]}"}; do
    problem="$(python_problem "$candidate")"
    if [ -z "$problem" ]; then
        python_bin="$candidate"
        break
    fi
    echo "Skipping $candidate: $problem"
done

if [ -z "$python_bin" ]; then
    echo "Error: no suitable Python found (see the skipped interpreters above)." >&2
    echo "Without admin rights, conda can provide a complete Python 3.12:" >&2
    echo "    conda create -y -p ~/.conda-envs/py312 python=3.12" >&2
    echo "after which running this script again finds it." >&2
    exit 1
fi
echo "Using $python_bin ($("$python_bin" --version 2>&1))"

# A venv from an earlier run may have been built on an incomplete Python.
if [ -x "$venv_dir/bin/python" ]; then
    problem="$(python_problem "$venv_dir/bin/python")"
    if [ -n "$problem" ]; then
        echo "Error: the existing venv $venv_dir was built on a $problem." >&2
        echo "Remove it and run this script again: rm -rf $venv_dir" >&2
        exit 1
    fi
fi

# QUICHE compiles QuEST with OpenMP. On macOS Apple clang has no OpenMP of its
# own, so point CMake at Homebrew's libomp.
if [ "$(uname -s)" = "Darwin" ] && [ -z "${OpenMP_ROOT:-}" ]; then
    libomp="$(brew --prefix libomp 2>/dev/null || true)"
    if [ -z "$libomp" ] || [ ! -d "$libomp" ]; then
        echo "Error: QUICHE needs OpenMP to build on macOS. Install it with: brew install libomp" >&2
        exit 1
    fi
    export OpenMP_ROOT="$libomp"
fi

set -x

# Create the venv if it doesn't exist yet; re-running this script reuses it.
if [ ! -d "$venv_dir" ]; then
    mkdir -p "$VENV_HOME"
    "$python_bin" -m venv "$venv_dir"
fi

# venv's activate script can trip over `set -u` (e.g. an unset PS1 in a
# non-interactive shell), so relax it just for the activation.
set +u
source "$venv_dir/bin/activate"
set -u

# Make sure everything below really goes into the venv.
if [ "$(python -c 'import os, sys; print(os.path.realpath(sys.prefix))')" != "$(cd "$venv_dir" && pwd -P)" ]; then
    echo "Error: the venv $venv_dir is not active after activating it." >&2
    exit 1
fi

python --version
python -m pip install --upgrade pip

# pip doesn't rebuild a package installed from a git branch when the branch moves on
# ("Requirement already satisfied"), so with UPDATE_QUICHE=1 QUICHE is rebuilt from the
# branch's latest commit first. The requirement is read from pyproject.toml, so the
# branch is only named in one place.
if [ "$UPDATE_QUICHE" = "1" ]; then
    quiche_req="$(python - "$demo_dir/pyproject.toml" <<'PYEOF'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    deps = tomllib.load(f)["project"]["dependencies"]
print(next(d for d in deps if d.replace(" ", "").startswith("pyquiche")))
PYEOF
)"
    python -m pip install --force-reinstall --no-deps "$quiche_req"
fi

# The demo, editable, with all its dependencies (pyproject.toml), including QUICHE
# from its GitHub branch with the CUDA-Q extra (cudaq, cudaq-algorithms).
python -m pip install -e "$demo_dir"

# Check that everything the notebook imports is there, before calling it a success.
python - <<'PYEOF'
import cudaq, cudaq_algorithms, opi, pandas, plotly, nbformat, kaleido
import quiche, quiche.io.fcidump, quiche.cudaq, quiche.dispatch
from quiche.cudaq import measured_circuit_kernel, sample_post_processor, textbook_qpe_circuit
from quiche.dispatch import QPESpec
import statePrep.cudaq_circuit_loading, visualisation
print(cudaq.__version__)
print("All demo imports work.")
PYEOF

# Kaleido (static PNGs of the figures, so they show on GitHub) draws them with Chrome.
# Use the installed Chrome if Kaleido finds one; otherwise download Chrome for Testing
# into the venv (no admin rights needed), then check again that a figure renders.
render_test='import plotly.graph_objects as go; go.Figure(go.Scatter(y=[1, 2])).to_image(format="png")'
if ! python -c "$render_test" >/dev/null 2>&1; then
    echo "No Chrome that Kaleido can use; downloading one into the venv."
    python -c "import kaleido; kaleido.get_chrome_sync()"
    if ! python -c "$render_test"; then
        echo "Error: Kaleido still can't render a figure with Chrome." >&2
        if [ "$(uname -s)" = "Linux" ]; then
            echo "Chrome may be missing system libraries (e.g. libnss3, libatk-bridge2.0-0," >&2
            echo "libgbm1, libasound2); install them with your package manager." >&2
        fi
        exit 1
    fi
fi
echo "Kaleido can render static figures."

# Register the venv as a Jupyter kernel for the current user (replaces an existing
# kernel of the same name, e.g. one from an older venv).
python -m ipykernel install --user --name "$KERNEL_NAME" --display-name "Python ($env_name)"

set +x
echo "The venv $venv_dir is ready, with Jupyter, and registered as the Jupyter kernel '$KERNEL_NAME'."
echo "Activate it with: source $venv_dir/bin/activate"
echo "ORCA itself is not installed by this script; set its path in the first code cell of the notebook."

cd "$demo_dir"
if [ "$action" = "run" ]; then
    jupyter lab
elif [ "$action" = "test" ]; then
    set -x
    jupyter nbconvert --to notebook --execute FeSH4_demo.ipynb \
        --ExecutePreprocessor.kernel_name="$KERNEL_NAME" --ExecutePreprocessor.timeout=-1 \
        --output FeSH4_demo.executed.ipynb
fi
