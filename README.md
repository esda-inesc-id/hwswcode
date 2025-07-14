# Hardware/Software Codesign Repository

This repository contains the materials for the Hardware/Software Codesign
course. The course focuses on optimizing software and developing hardware
accelerators for embedded systems, using the Xilinx Vitis platform, which
includes Vitis HLS for hardware accelerator design, Vitis for software
application development, and Vivado for hardware integration. This repository
covers the following topics:
- HLS-based design and simulation
- IP export for Vivado integration
- Application development using the exported hardware platform
- Automated build flow using a Makefile

---

## Requirements

- **Vitis 2024.1** or compatible version, including 
- **Vitis HLS 2024.1**
- **Vivado 2024.1** (for IP integration and bitstream export)
- A supported Zynq board (e.g., Zybo Z7)


In the exercises directory, you will find a few example projects, such as `iir`,
which demonstrate the flow of HLS design, IP export, and application
development. The flow can be run using the Vitis GUI, using the provided lab
guide in labs/HWSW_Lab_Guide.pdf, or using the provided Makefile. For any of
these steps, you must first set up the environment by sourcing the Vitis
environment:

```bash
source /opt/Xilinx/Vitis/2024.2/settings64.sh
````

---

## Project Structure

```
.
├── Makefile             # Top-level automation for HLS, IP, and app
├── scripts/             # Contains all Tcl scripts used by Vitis/Vivado
├── exercises/iir/       # Parameter directory (PDIR), includes `init.mk` and Vivado project
├── hls_project/         # Generated HLS project directory
├── platform/            # Vitis platform directory (auto-generated)
├── app/                 # Application project directory (auto-generated)
└── *.tcl, *.cpp         # Design source and testbench files
```

---

## Makefile Targets

| Target          | Description                                          |
| --------------- | ---------------------------------------------------- |
| `make csim`     | Run C simulation in Vitis HLS                        |
| `make csynth`   | Run C synthesis (generates HLS report)               |
| `make cosim`    | Run C/RTL co-simulation                              |
| `make impl`     | Run HLS implementation phase                         |
| `make ip`       | Export the IP as a `.zip` file                       |
| `make app`      | Build the Vitis application and download to hardware |
| `make run`      | Run the full application on hardware (implies `app`) |
| `make clean`    | Clean all build artifacts                            |
| `make clean-sw` | Clean only software/app-related artifacts            |

---

## Bitstream Generation (Vivado)

After HLS export, the Vivado flow must be run manually once to generate the XSA file:

```bash
make $(XSA)
```

This command internally runs `scripts/uphw.tcl` and `scripts/ldhw.tcl` to build and export the platform.

---

## Serial Output

After flashing and running the app, you can monitor the board's output via `picocom`:

```bash
picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf
```

---

## Debugging

To run the application with debug support:

```bash
make run DEBUG=1
```

---

## Notes

* The `PDIR` variable points to your Vivado project location. By default: `exercises/iir`.
* All scripts are parameterized through `init.mk`.
* If you want to step through HLS simulation in GDB:

  ```
  gdb ./hls_project/solution1/csim/build/csim.exe
  ```

---


Here's the updated section for the `README.md` to include instructions and explanation for the **manual Vivado project setup**, which complements your Makefile-based flow:


---

## Vivado Project Setup (Manual Step)

The Vivado block design must be created **manually** before using this Makefile flow.

### Instructions:

1. **Open Vivado (2024.1)** and create a new project:

   * Project name: `project_1` (this name is mandatory for the Makefile to work)
   * Location: inside the project directory, for example, the `exercises/iir/` directory

2. **In the Block Design**, proceed as indicated in the HWSW_Lab_Guide.pdf or the Vivado documentation:

   * **Add a Zynq Processing System (PS)**.
   * **Add your exported HLS IP** (from `make ip`).
   * **Connect the HLS IP to the PS**
   * You can use a **DMA IP from the Xilinx IP catalog** to drive the data stream:
   * Use **`M_AXI_GP0`** from the PS to connect to the HLS IP's **AXI4-Lite control interface**.
   * Use **`S_AXI_HP`** interfaces (e.g., `S_AXI_HP0`) for **data transfer**.
   * Either insert a **DMA** between the PS and the HLS IP
   * Or configure your HLS IP with an AXI interfaces to **directly connect** to the HP ports

3. After **Validate the design** and **Generate Block Design**, save it and exit Vivado.

---

### Important Naming and File Constraints

To integrate smoothly with the Makefile:

* The **Vivado project must be named `project_1`**
* Keep only the following:

  * `project_1.xpr`
  * The `project_1.srcs/` directory (contains the block design)
* All **other generated files and directories** will be **deleted** when you run:

```bash
make clean
```

After setting up the Vivado project, you can proceed with the Makefile flow as described in the previous sections. The Makefile will handle the HLS design, IP export, and application development, allowing you to focus on optimizing your hardware/software codesign projects.
