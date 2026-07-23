# SOLAR — Off-Grid Solar Power Sizing Suite for DM42

A set of HP-42S/DM42 programs for sizing off-grid solar panels, batteries, and inverters. Each formula is a minimal stack-based RPN function. A guided `CHAIN` mode walks through all formulas with prompts and result display, including phantom load adjustment and autonomy day scaling.

## Quick Start

```
XEQ "SRSET"                    @ initialize defaults (run once)
400 ENTER 8 XEQ "ELOAD"       @ daily energy: 3200 Wh
XEQ "EBATT"                    @ inverter loss: 3764.7 Wh
XEQ "BCAP"                     @ battery capacity: 4705.9 Wh (91.9 Ah)
4.5 XEQ "PSOLR"               @ solar array: 1307.2 W
1440 XEQ "PINV"               @ inverter size: 1800 W
```

Or use the guided mode: `XEQ "SOLAR"` then press **MORE** > **CHAIN**.

## Programs

### Core Formulas (stack-based)

| Program | Formula | Stack In | Stack Out |
|---------|---------|----------|-----------|
| **ELOAD** | E = P × t | Y=Pavg(W), X=Trun(h) | X=Eload(Wh) |
| **EBATT** | E = Eload / η_inv | X=Eload(Wh) | X=Ebatt(Wh) |
| **BCAP** | C = Ebatt / DoD | X=Ebatt(Wh) | X=Ctot(Wh) |
| **PSOLR** | P = Ctot / (PSH × η_sol) | Y=Ctot(Wh), X=PSH(h) | X=Psolr(W) |
| **PINV** | P = Ppeak × 1.25 | X=Ppeak(W) | X=Pcont(W) |
| **DCYCL** | E = P × t × D | Z=P(W), Y=t(h), X=D | X=E(Wh) |
| **AUTON** | C = Ctot × Ndays | Y=Ctot(Wh), X=Ndays | X=Cauto(Wh) |

### Support Programs

| Program | Purpose |
|---------|---------|
| **SRSET** | Initialize/reset default parameters |
| **CHAIN** | Guided walkthrough of all formulas |
| **SOLAR** | Two-page master menu |

## Variables

### Parameters (defaults set by SRSET)

| Variable | Description | Default |
|----------|-------------|---------|
| `Ninv` | Inverter efficiency (η_inv) | 0.85 |
| `DoD` | Battery depth of discharge | 0.80 |
| `Vsys` | Battery system voltage (V) | 51.2 |
| `Nsol` | Solar collection efficiency (η_solar) | 0.80 |
| `Pidle` | Inverter/parasitic idle draw (W) | 20 |
| `Ndays` | Autonomy days for battery sizing | 1 |

Change a parameter anytime: `0.90 STO "Ninv"`. Run `XEQ "SRSET"` to reset all to defaults.

### Results (stored by each function)

| Variable | Description | Unit |
|----------|-------------|------|
| `Eload` | Daily energy consumption | Wh |
| `Ebatt` | Energy needed from battery | Wh |
| `Ctot` | Total battery capacity (single day) | Wh |
| `CAh` | Battery capacity | Ah |
| `Cauto` | Battery capacity with autonomy days | Wh |
| `Psolr` | Required solar array power | W |
| `Ppeak` | Peak load power | W |
| `Pcont` | Minimum inverter continuous rating | W |

### Flag 10

Tracks whether defaults have been initialized. Prevents `SRSET` from overwriting user-modified parameters on repeat `SOLAR`/`CHAIN` calls. Clear with `CF 10` to force re-initialization.

## Chaining

Results flow naturally through the RPN stack:

```
400 ENTER 8 XEQ "ELOAD"   @ X=3200
XEQ "EBATT"                @ X=3764.7 (Eload feeds in from X)
XEQ "BCAP"                 @ X=4705.9 (Ebatt feeds in; Ctot left in X for PSOLR)
4.5 XEQ "PSOLR"           @ typing 4.5 lifts Ctot to Y automatically
1440 XEQ "PINV"           @ independent — push your peak load
```

`BCAP` computes both Ctot and CAh but leaves **Ctot** in X so it chains directly into `PSOLR`. Recall CAh anytime with `RCL "CAh"`.

## Multi-Device Energy Budgeting (DCYCL)

`DCYCL` computes `P × t × D` and **accumulates** into `Eload` via `STO+`. Use it to build up daily energy from multiple devices with different duty cycles.

```
0 STO "Eload"                            @ clear accumulator
600 ENTER 8 ENTER 0.50 XEQ "DCYCL"      @ HVAC: 2400 Wh
85 ENTER 8 ENTER 1 XEQ "DCYCL"          @ laptop: 680 Wh
50 ENTER 8 ENTER 1 XEQ "DCYCL"          @ monitors: 400 Wh
30 ENTER 5 ENTER 1 XEQ "DCYCL"          @ LED lights: 150 Wh
100 ENTER 24 ENTER 0.35 XEQ "DCYCL"     @ mini-fridge: 840 Wh
RCL "Pidle" 24 * STO+ "Eload"           @ add phantom load: 480 Wh
RCL "Eload"                              @ total: 4950 Wh
XEQ "EBATT"                              @ continue the chain...
```

Each `DCYCL` call returns the device's energy in X and adds it to `Eload`. After all devices, recall `Eload` and chain into `EBATT` → `BCAP` → `PSOLR` → `PINV`.

## Autonomy Days (AUTON)

`AUTON` scales battery capacity for consecutive cloudy/rainy days. It computes `Ctot × Ndays` and stores the result in `Cauto`.

```
@ After BCAP:
2 XEQ "AUTON"              @ X = Ctot * 2 (2 days of autonomy)
```

This only affects battery sizing — `PSOLR` still sizes solar off single-day `Ctot` (steady-state daily recharge).

## CHAIN Mode

`XEQ "CHAIN"` runs all formulas in sequence with `INPUT` prompts and `VIEW`/`STOP` after each result. Press **R/S** to continue to the next step.

Steps:
1. `Pavg` — average load power (W)
2. `Trun` — daily run time (h)
3. **Eload** — daily energy, with `Pidle × 24` phantom load added automatically
4. **Ebatt** — adjusted for inverter efficiency
5. **Ctot** — battery capacity (Wh)
6. **CAh** — battery capacity (Ah)
7. `Ndays` — autonomy days (default 1, increase for cloudy day protection)
8. **Cauto** — battery capacity scaled for autonomy
9. `PSH` — peak sun hours for your location
10. **Psolr** — required solar array wattage
11. `Ppeak` — peak load power (defaults to Pavg, adjust upward for motor surge)
12. **Pcont** — minimum inverter continuous rating

## SOLAR Menu

`XEQ "SOLAR"` displays a two-page programmable menu:

```
Page 1:  ELOAD  EBATT  BCAP  PSOLR  PINV  MORE
Page 2:  DCYCL  AUTON  SRSET CHAIN        BACK
```

Set up your stack, then press a menu key to run that function. Press **MORE**/**BACK** to switch pages. Press **EXIT** to leave the menu.

## Loading onto DM42 / Free42

1. Convert `solar.hp42s` to binary:
   - **Online:** paste into the [SwissMicros encoder](https://technical.swissmicros.com/decoders/dm42/) and click Encode
   - **CLI:** use `txt2raw` from the [Free42 distribution](https://thomasokken.com/free42/)
2. **DM42:** connect via USB, copy the `.raw` file, import via file manager
3. **Free42 desktop:** File > Import Programs, select the `.raw` file

## Formulas Reference

### 1. Daily Energy Consumption — `ELOAD`

$$E_{\text{load}} = P_{\text{avg}} \times t$$

| Symbol | DM42 Variable | Description | Unit |
|--------|---------------|-------------|------|
| $E_{\text{load}}$ | `Eload` | Total daily energy requirement | Wh |
| $P_{\text{avg}}$ | `Pavg` | Average running power draw | W |
| $t$ | `Trun` | Total operating time per day | h |

### 1b. Device Energy with Duty Cycle — `DCYCL`

$$E_{\text{device}} = P_{\text{rated}} \times t_{\text{on}} \times D$$

Appliances with thermostats (heat pumps, mini-fridges) cycle on and off. The duty cycle $D$ captures the fraction of time the compressor actually runs (e.g., $0.50$ for a heat pump that cycles 50%).

| Symbol | Stack Register | Description |
|--------|---------------|-------------|
| $P_{\text{rated}}$ | Z | Rated power draw | W |
| $t_{\text{on}}$ | Y | Hours the device is switched on | h |
| $D$ | X | Duty cycle fraction ($0$–$1$) | — |

### 2. Inverter Efficiency Adjustment — `EBATT`

$$E_{\text{battery}} = \frac{E_{\text{load}}}{\eta_{\text{inv}}}$$

DC-to-AC inverters lose energy as heat during conversion (typically 10%–15% loss).

| Symbol | DM42 Variable | Description | Default |
|--------|---------------|-------------|---------|
| $E_{\text{battery}}$ | `Ebatt` | Actual energy required from battery bank | — |
| $\eta_{\text{inv}}$ | `Ninv` | Inverter efficiency ($0.85$ = 85%) | 0.85 |

### 3. Battery Capacity Sizing — `BCAP`

$$C_{\text{total}} = \frac{E_{\text{battery}}}{\text{DoD}}$$

$$C_{\text{Ah}} = \frac{C_{\text{total}}}{V_{\text{system}}}$$

To maximize battery lifespan (even with LiFePO4 cells), you shouldn't fully deplete the battery. The depth of discharge $\text{DoD}$ sets the usable fraction.

| Symbol | DM42 Variable | Description | Default |
|--------|---------------|-------------|---------|
| $C_{\text{total}}$ | `Ctot` | Required total battery capacity | — |
| $C_{\text{Ah}}$ | `CAh` | Battery capacity in amp-hours | — |
| $\text{DoD}$ | `DoD` | Depth of discharge limit ($0.80$ = 80%) | 0.80 |
| $V_{\text{system}}$ | `Vsys` | Nominal battery bank voltage | 51.2 |

### 3b. Autonomy Days — `AUTON`

$$C_{\text{autonomous}} = C_{\text{total}} \times N_{\text{days}}$$

Scales battery capacity for consecutive cloudy/rainy days when solar generation drops by 70%–90%.

| Symbol | DM42 Variable | Description | Default |
|--------|---------------|-------------|---------|
| $C_{\text{autonomous}}$ | `Cauto` | Battery capacity for multi-day autonomy | — |
| $N_{\text{days}}$ | `Ndays` | Desired days of off-grid autonomy | 1 |

### 4. Solar Array Sizing — `PSOLR`

$$P_{\text{solar}} = \frac{C_{\text{total}}}{\text{PSH} \times \eta_{\text{solar}}}$$

Calculates the minimum solar panel wattage to fully recharge the battery bank during daylight, accounting for real-world losses ($\eta_{\text{solar}}$: heat, dirty panels, wire resistance).

| Symbol | DM42 Variable | Description | Default |
|--------|---------------|-------------|---------|
| $P_{\text{solar}}$ | `Psolr` | Minimum total solar array rating | — |
| $\text{PSH}$ | `PSH` | Peak sun hours per day (location-specific) | — |
| $\eta_{\text{solar}}$ | `Nsol` | Solar collection efficiency | 0.80 |

### 5. Inverter Power Sizing — `PINV`

$$P_{\text{continuous}} \ge P_{\text{peak}} \times 1.25$$

The inverter must handle continuous load plus a 25% safety headroom. Motor startup surges (heat pumps, compressors) can draw $2\times$–$3\times$ their running power — size $P_{\text{peak}}$ accordingly.

| Symbol | DM42 Variable | Description |
|--------|---------------|-------------|
| $P_{\text{continuous}}$ | `Pcont` | Inverter continuous output rating | W |
| $P_{\text{peak}}$ | `Ppeak` | Peak simultaneous load | W |

### Phantom / Idle Draws

$$E_{\text{phantom}} = P_{\text{idle}} \times 24$$

Inverters and smart power stations consume roughly 15W–30W continuously just keeping AC outlets live. CHAIN adds $P_{\text{idle}} \times 24$ to $E_{\text{load}}$ automatically.

| Symbol | DM42 Variable | Description | Default |
|--------|---------------|-------------|---------|
| $P_{\text{idle}}$ | `Pidle` | Inverter/parasitic idle draw | 20 W |

For standalone use: `RCL "Pidle" 24 * STO+ "Eload"`
