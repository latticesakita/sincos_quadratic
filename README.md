
# High‑Precision SIN / SIN-COS Quadratic Interpolation Modules (LUT + DSP)

This repository contains high‑accuracy (2.48e-11 RMS) sine and cosine generator modules implemented in Verilog.  
The design uses a **36‑bit EBR-based lookup table** and a **fully cascaded 18×18 DSP block to be in form of 36×36** and keeping hardware usage extremely small.

---
## ✨ Features
- **47‑bit phase input**, representing `radian / (2π) * 2^47`
- **Up to 56‑bit output resolution** (default: 56‑bit Q2.54 format)
- **Four‑stage pipeline (clock latency = 4 clocks)** → **Fmax = 180 MHz**
- **CPNX version supports → **Fmax = ~100 MHz**
- 1024‑entry LUT (π/2 range):
  - **36‑bit y0**
  - **36‑bit dy**
  - **36‑bit ddy**
- High‑precision interpolation accuracy:
  - Max error: **7.55e-11**
  - RMS error: **2.48e-11**
  - Much Better than single‑precision floating‑point (≈1.2e‑7)
- COS output supported by phase shifting (`cos(x) = sin(x + π/2)`).

---
## 📁 Repository Structure
```
/project
  ├─ sincos_quadratic.rdf     # Radiant project file
  ├─ sincos_quadratic.pdc     # constraint file

/source
  ├─ sin_quadratic.v          # supports sin() only
  ├─ sincos_quadratic.v       # top module for sin()/cos()
  ├─ sin_lut_y0/              # Look Up Table for y0
  ├─ sin_lut_dy/
  ├─ sin_lut_ddy/
  ├─ mult36x36p72_cascaded.v  # DSP instance, fully cascaded
  ├─ mult36x36p72.v           # Not used, DSP instance, No cascaded connection.
  ├─ addr38                   # Not used, addr instance, used from mult36x36p72 module.
  ├─ addr55                   # Not used, addr instance, used from mult36x36p72 module.

/sim
  ├─ tb_sin_quadratic.v
  ├─ top_sincos_quadratic.v   # Used for Fmax estimation
  ├─ gpll/                    # PLL config used during Fmax estimation

/scripts
  ├─ check.bat                # check simulation result with comparing to ideal value
  ├─ verify_csv.py            # called from check.bat, script used to generate the numerical LUT base data
  ├─ sim_half_pi1.py          # Script used to generate the numerical LUT base data, and simulate in python
  ├─ rom_out/                 # Includes LUT .mem files (y0, dy and ddy)

```

---
## 🚀 Performance
| Pipeline | Latency | Max Frequency | Branch |
|---------|---------|----------------|--------|
| 4-stage | 4 clocks | **180 MHz** | `main` |
| 4-stage | 4 clocks | **100 MHz** | `cpnx` |

---
## 🧮 Architecture Overview
### SIN Calculation (`sin_quadratic`)
This is quadratic interpolation. y0 + term1 is the linear interpolation, term2 is trying to compensate the error in linear interpolation.

The module consists of:

#### Stage 0 — Preprocessing
- Extract quadrant from the upper 2 bits of the phase
- Convert phase into address + fractional part

#### Stage 1,2 — ROM Read with output register
- Read `y0 [35:0]` (EBR)
- Read `dy [35:0]` (EBR)
- Read `ddy[35:0]` (EBR)
- Quadrant and frac forwarded to next stage

#### Stage 1,2 — Pre-calculation of t*(1-t)
Set input and output register on DSP setting.

- t     = {1'b0,frac[16:0]}
- (1-t) = 18'h20000 - {1'b0,frac[16:0]} => {1'b1,frac[16:0]}
- tt = t*(1-t)

#### Stage 3,4 — Linear Interpolation
Set input and output register on DSP setting.

Interpolation formula:
```
term1 = y0 + dy * frac
```
Compensation value:
```
term2 = ddy * tt
```

#### Stage 5 — Output stage
- accumulate and output with sign consideration

### SIN + COS Wrapper (`sincos_quadratic`)
- Selects between SIN and COS by shifting the phase
- Instantiates `sin_quadratic`

---
## 🧪 Simulation
### Running the testbench
This will test sin_quadratic module, not sincos_quadratic module.
```
Run `../tb/tb.spf`
  (tb.spf doesn't simulate sincos_quadratic, top_sin_quadratic and gpll modules.)

This test bench will generate `sincos_out.csv`.

`./scripts/check.bat`
This compares output against golden reference data and report the accuracy.
```

---
## 🧭 FPGA Implementation Guide
### 1. Clocking Considerations
- Single synchronous clock domain
- DSP and EBR must share the same clock
- Use PLL clocks for high Fmax (`source/gpll`)

### 2. ROM Implementation (EBR)
- `lut_y0`	: 36‑bit entries
- `lut_dy`	: 36‑bit entries
- `lut_ddy`	: 36‑bit entries
- Depth: 1024
- `.mem` files under `scripts/rom_out/`

### 3. DSP Block Mapping
- Expression: `result = dy * frac + y0`
- Maps to four 18×18 DSP blocks
- Keep arithmetic intact for proper inference

### 4. Timing Closure Tips
- Keep stage boundaries intact
- Enable retiming, register balancing
- Optionally constrain DSP + EBR locality

### 5. Latency Alignment
- 5-stage version: **2 clocks latency**
- Align downstream pipelines accordingly or use valid_o to verify the output timing

### 6. Port Explanation
- mode_cos
  - Output mode select.
  - 0: sin, 1: cos

- phase_i (56bits)
  - phase input value.
  - ex1. pi/2   ==> 56'h40_0000_0000_0000
  - ex2. pi     ==> 56'h80_0000_0000_0000
  - ex3. 3*pi/2 ==> 56'hC0_0000_0000_0000
  - ex4. rad    ==> rad/pi*(1<<55)

- valid_i, valid_o
  -  data valid indicator

- result_o (56bits, Q2.54)
  - bit55  : signed
  - bit54  : integer
  - bit53:0: fractional


### 7. Integration Checklist
- Clock/reset stable
- Output width correct
- ROM correctly initialized
- Latency accounted for

### 8. Recommended FPGA Families
- Lattice Avant
- Lattice CertusPro

---
## 📄 License
This module incorporates content governed by the **Lattice Reference Design License Agreement**.

## Contributing
Issues and PRs are welcome.
