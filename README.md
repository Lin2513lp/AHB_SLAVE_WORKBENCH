> 源码范围：仅本模块 RTL、内部子模块及独立 TB；其他模块源码请进入对应工作台。`code/` 不收录联调包装、构建脚本、Makefile 或说明文件。

# AHB_SLAVE Design Workbench

**[Open the AHB_SLAVE Workbench](https://lin2513lp.github.io/AHB_SLAVE_WORKBENCH/AHB_SLAVE_WORKBENCH.html)**

AHB-Lite slave interface and register-map access for TPU_TOP. The workbench runs in a browser and requires no installation.

## Workbench contents

- Address and data phases, read/write control, and register-map interfaces.
- Single transfers, continuous reads/writes, and error-response scenarios.
- Protocol timing diagrams, simulation captures, and design notes.

## Source files

[`code/`](code/) contains only this module’s RTL, internal submodules and standalone HDL testbenches. There are **5 RTL/TB files**. Other modules are available from their respective workbenches. [`source-manifest.json`](source-manifest.json) lists the retained source hashes.


## Repository layout

| Path | Contents |
| --- | --- |
| [`AHB_SLAVE_WORKBENCH.html`](AHB_SLAVE_WORKBENCH.html) | Main design workbench |
| [`code/`](code/) | This module’s RTL and independent HDL testbenches |
| [`source-manifest.json`](source-manifest.json) | Source inventory and checksums |
| [`index.html`](index.html) | English project introduction and workbench link |

## Using the project

Open the workbench to browse the design report, waveforms and this module’s RTL/TB. Run simulation in the original local project environment.

## Related workbenches

- [TPU_CRG](https://github.com/Lin2513lp/TPU_CRG_WORKBENCH)
- [AXI_TOP](https://github.com/Lin2513lp/AXI_TOP_WORKBENCH)
- [SA_TOP](https://github.com/Lin2513lp/sa-workbench)
- [PE_MP](https://github.com/Lin2513lp/pe-mp-workbench)
