# QUICHE + CUDA-Q: A fully integrated end-to-end quantum chemistry pipeline
---  

<p align="center">
  <img src="../img/pipeline_diagram.png" width="700"><br>
  <em>End-to-end integration of different software stacks using QUICHE and CUDA-Q</em>
</p>

Quantum Motion and NVIDIA are working together to provide a fully integrated quantum chemistry pipeline for resource estimation and simulation for quantum computing applications. In parallel, [QUICHE](https://quantummotion.com/quiche-project-uk-germany-collaboration-bringing-chemistry-software-into-the-quantum-computing-era/) is a joint project between Quantum Motion, [FACCTs](https://www.faccts.de/) and [Riverlane](https://www.riverlane.com/), which aims to integrate quantum computing into standard quantum chemistry workflows including the industry-standard ORCA library. We have now added CUDA-Q as a new prototype backend to QUICHE, continuing our work towards building an end-to-end pipeline for quantum chemistry. The [CUDA-Q Algorithms](https://nvidia.github.io/cudaq-algorithms/) layer provides high-level abstractions for QUICHE to interact with, allowing easy dispatch to high performance simulators in the CUDA-Q ecosystem as well as resource estimation functionality. In [our latest demo](https://github.com/Quantum-Motion/quiche-sc26-integration-demo/blob/main/integration-demo/FeSH4_demo.ipynb), we show off these new simulation capabilities by starting from an ORCA calculation, setting up the quantum algorithm using QUICHE and CUDA-Q and finally running the simulation on an NVIDIA backend. 

### One pipeline, different software stacks

A quantum algorithm for chemistry is only useful if a chemist can load a molecule onto a quantum computer and get an answer back out. In practice, that means stitching together tools that were never designed to interact with one another. We want to build a single pipeline that integrates different software stacks into a single toolbox, playing to the strengths of each of the individual components.

- [ORCA](https://www.faccts.de/orca/) is an industry-standard quantum chemistry package. We use it to run the classical calculations and to export the active-space integrals as a standard FCIDUMP file.
- [QUICHE](https://github.com/Quantum-Motion/quiche) is the glue. It reads the FCIDUMP, and lets the user specify the algorithm at a high level: which Hamiltonian, which flavour of quantum phase estimation (QPE), which simulation method, and, crucially, a target energy error.
- [CUDA-Q](https://nvidia.github.io/cuda-quantum/latest/using/quick_start.html) and [CUDA-Q Algorithms](https://nvidia.github.io/cudaq-algorithms/) make up NVIDIA's open-source platform for hybrid quantum-classical programming. CUDA-Q Algorithms builds the qubit Hamiltonians, and the QPE circuits that QUICHE generates are run as CUDA-Q kernels, on NVIDIA's high-performance backend.  

The result is that, from the user's perspective, the workflow is a short Python notebook: ORCA in, energies out, with no hand-written circuits or manual conversion steps in between. The same QUICHE specification that drives the simulation is also the starting point for resource estimation, meaning that, in the era of fault-tolerant quantum computing (FTQC), our pipeline stays virtually unchanged.  
  
### Spin state energetics of iron-sulfur systems  

<p align="center">
  <img src="../img/Fe(SH)4-.png" alt="Fe(SH)4- structure" width="400"><br>
  <em>Chemical structure of Fe(SH)<sub>4</sub><sup>&minus;</sup></em>
</p>

To showcase the capability of this new integration, we set up a small chemistry example that, when scaled up, can be industrially relevant. The identity of the ground spin state is crucial for understanding reactivity, electrochemistry and photochemistry. Furthermore, the energy differences between the ground spin state and states of other multiplicity are needed to predict, for example, spectroscopy. Iron-sulfur systems are an especially delicate target for these so-called spin state energetics, as the different spin states have been reported to be within sub-milliHartree of each other for certain clusters. Different methods, as well as the inclusion or omission of dynamic correlation effects, can also result in different orderings of the spin ladder. As the target system, we choose Fe(SH)<sub>4</sub><sup>&minus;</sup> in a minimal active space of 5 electron in 5 orbitals. It functions as an example of an Fe-S cluster, but has its own chemical relevance as it is a minimal model of the iron site of rubredoxin, the simplest natural iron–sulfur protein. We purposefully choose a small system and active space. It lets us check every QPE result against an exact reference from complete active space self-consistent field (CASSCF) calculations, and it means the pipeline can be run end to end on a single GPU.

### Try it yourself

This pipeline will allow us to push the limits of what chemical problems we can tackle, ranging from larger, more complex simulations up to resource estimates for systems that are no longer classically simulable. The full demo is available [here](../FeSH4_demo.ipynb).

If you would like to know more about our ongoing work on quantum chemistry and fault tolerant quantum computing, check out our blog posts on [fault tolerant compilation](https://quantummotion.com/automating-fault-tolerant-compilation-for-quantum-motions-silicon-spin-architectures-using-nvidia-cuda-q-logical/), [quantum chemistry state preparation](https://quantummotion.com/state-preparation-for-quantum-chemistry-with-quantum-motion-and-nvidia-cuda-q/), and our earlier [QUICHE project announcement](https://quantummotion.com/quiche-project-uk-germany-collaboration-bringing-chemistry-software-into-the-quantum-computing-era/).

### About the authors

<ins>[Xeno De Vriendt](https://www.linkedin.com/in/xeno-de-vriendt/)</ins> is an Applications Scientist at Quantum Motion. Xeno obtained a PhD in Chemistry from Ghent University for research on (classical) quantum chemical method development, after which he worked as a post-doctoral researcher in the quantum computing team at BASF Ludwigshafen. At Quantum Motion, Xeno is working on identifying use cases for quantum computing and algorithm development, both with a focus on chemistry.

<ins>[Zohim Chandani](https://www.linkedin.com/in/zohim-chandani/)</ins> is a Quantum Algorithms and Applications Engineer at NVIDIA. His work spans scaling up quantum algorithms, use of AI across the quantum stack and the utility of quantum-GPU supercomputing.

<ins>[Thomas R. Bromley](https://www.linkedin.com/in/thomas-r-bromley-a53a28130/)</ins> is the Applications Lead at Quantum Motion, working to identify quantum computing use cases and develop the underlying quantum algorithms. Tom has over a decade of experience in quantum computing and leads a team of researchers and software developers to build applications that complement Quantum Motion's silicon spin quantum dot hardware.