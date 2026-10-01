# AHB_SLAVE Design Workbench

**[Open the AHB_SLAVE Workbench](https://lin2513lp.github.io/AHB_SLAVE_WORKBENCH/AHB_SLAVE_WORKBENCH.html)**

AHB-Lite slave interface and register-map access for TPU_TOP. The workbench runs in a browser and requires no installation.

## Workbench contents

- Address and data phases, read/write control, and register-map interfaces.
- Single transfers, continuous reads/writes, and error-response scenarios.
- Protocol timing diagrams, simulation captures, and design notes.

## Source files

[`code/`](code/) contains the current source snapshot from the shared `AHB_SLAVE` project. Relative paths and file contents are preserved, including RTL, testbenches, Makefiles, file lists, and available helper scripts. The workbench's code viewer displays this same snapshot.

There are **6 project files** in this snapshot. [`source-manifest.json`](source-manifest.json) records the shared-directory mapping and SHA-256 checksums. Generated simulator databases, waveform dumps, editor temporary files, and license logs are excluded.

## Repository layout

| Path | Contents |
| --- | --- |
| [`AHB_SLAVE_WORKBENCH.html`](AHB_SLAVE_WORKBENCH.html) | Main design workbench |
| [`code/`](code/) | Shared-project source files and build entry points |
| [`source-manifest.json`](source-manifest.json) | Source inventory and checksums |
| [`index.html`](index.html) | English project introduction and workbench link |

## Using the project

Open the workbench through the link above to browse the report, code, and waveforms. For simulation, clone this repository, enter `code/`, and use its Makefile in a configured Linux EDA environment. The original tool paths and environment variables in the shared Makefile are preserved; configure these for your installation.

## Related workbenches

- [TPU_CRG](https://github.com/Lin2513lp/TPU_CRG_WORKBENCH)
- [AXI_TOP](https://github.com/Lin2513lp/AXI_TOP_WORKBENCH)
- [SA_TOP](https://github.com/Lin2513lp/sa-workbench)
- [PE_MP](https://github.com/Lin2513lp/pe-mp-workbench)
