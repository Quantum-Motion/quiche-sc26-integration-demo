# Fe(SH)<sub>4</sub><sup>−</sup> spin state energetics using QUICHE and CUDA-Q

An end-to-end quantum chemistry pipeline: ORCA computes the active-space integrals, QUICHE sets up quantum phase estimation (QPE) from a target error budget, and CUDA-Q runs the circuits on a CPU or an NVIDIA GPU. The target is the spin ladder (doublet, quartet, sextet) of Fe(SH)<sub>4</sub><sup>−</sup> in a CAS(5e,5o) active space. For the background, see the [blog post](blogpost/README.md).

## Repository structure

```
├── setup-demo.sh             # Creates the virtual environment and Jupyter kernel
├── pyproject.toml            # The demo's dependencies, including QUICHE from GitHub
├── integration-demo/
│   ├── FeSH4_demo.ipynb      # The demo notebook
│   ├── visualisation.py      # Plotly routines used in the analysis part of the notebook
│   ├── statePrep/            # Turns the DMRG circuits (JSON) into CUDA-Q kernels
│   ├── FeSH4/                # Geometry; ORCA writes its calculations next to it
│   └── output/               # Pre-calculated results, so the notebook runs in minutes
├── img/                      # Figures for the notebook and the blog post
└── blogpost/README.md        # Accompanying blog post
```

## Requirements

- Linux or macOS, with git and a C++ compiler (QUICHE is built from source). On macOS also `brew install libomp`.
- Python 3.12 or 3.13, including its C headers (`python3.12-dev` / `python3.12-devel` on Linux).
- [ORCA](https://www.faccts.de/orca/) 6.1 or 7.0, installed separately.
- Optional: an NVIDIA GPU. Without one, CUDA-Q falls back to its CPU simulator.

## Installation

```bash
git clone https://github.com/Quantum-Motion/quiche-sc26-integration-demo.git
cd quiche-sc26-integration-demo
bash setup-demo.sh
```

The script:

1. finds a suitable Python and creates the virtual environment `~/.venvs/quiche-cudaq-integration-demo`;
2. installs the demo with `pip install -e .`, which pulls in everything in `pyproject.toml`: QUICHE from its [`feature/integration-demo`](https://github.com/Quantum-Motion/quiche/tree/feature/integration-demo) branch (with CUDA-Q and CUDA-Q Algorithms), the ORCA Python interface, Open MPI 4.1.8, pandas, Plotly and Jupyter;
3. checks that everything the notebook imports is there;
4. registers the environment as the Jupyter kernel `quiche-cudaq-integration-demo`.

The first run takes several minutes; re-running it reuses the environment. A log is written to `~/quiche-cudaq-integration-demo-setup.log`. Options are listed at the top of `setup-demo.sh`; the most useful is `UPDATE_QUICHE=1 bash setup-demo.sh`, which rebuilds QUICHE from the latest commit of its branch.

## Running the demo

1. Set `orca_dir` in the first code cell of the notebook to your ORCA installation.
2. Start JupyterLab with `bash setup-demo.sh run` (or activate the environment and run `jupyter lab` from this directory), open `FeSH4_demo.ipynb` and run all cells.

To run the notebook without a browser, use `bash setup-demo.sh test`, which writes the executed copy to `FeSH4_demo.executed.ipynb`.

The notebook only calculates what is missing. On a fresh clone, ORCA runs the short ROHF calculation; the CASSCF integrals, DMRG circuits and QPE results are loaded from `output/`. Delete files from `output/` to recompute those steps. Recomputing the GPU QPE runs up to 14 phase qubits takes several hours on a single NVIDIA T4.