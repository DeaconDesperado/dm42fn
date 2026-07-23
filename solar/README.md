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

### Energy Sizing (stack-based)

| Program | Formula | Stack In | Stack Out |
|---------|---------|----------|-----------|
| **ELOAD** | $E_{\text{load}} = P_{\text{avg}} \times t$ | Y=Pavg(W), X=Trun(h) | X=Eload(Wh) |
| **EBATT** | $E_{\text{battery}} = E_{\text{load}} / \eta_{\text{inv}}$ | X=Eload(Wh) | X=Ebatt(Wh) |
| **BCAP** | $C_{\text{total}} = E_{\text{battery}} / \text{DoD}$ | X=Ebatt(Wh) | X=Ctot(Wh) |
| **PSOLR** | $P_{\text{solar}} = C_{\text{total}} / (\text{PSH} \times \eta_{\text{solar}})$ | Y=Ctot(Wh), X=PSH(h) | X=Psolr(W) |
| **PINV** | $P_{\text{continuous}} = P_{\text{peak}} \times 1.25$ | X=Ppeak(W) | X=Pcont(W) |
| **DCYCL** | $E = P_{\text{rated}} \times t \times D$ | Z=P(W), Y=t(h), X=D | X=E(Wh) |
| **AUTON** | $C_{\text{auto}} = C_{\text{total}} \times N_{\text{days}}$ | Y=Ctot(Wh), X=Ndays | X=Cauto(Wh) |

### Hardware Engineering (stack-based)

| Program | Formula | Stack In | Stack Out |
|---------|---------|----------|-----------|
| **VCOLD** | $V_{\text{oc\_cold}} = V_{\text{oc\_stc}} \times [1 + (T_{\text{min}} - 25) \times \frac{\gamma}{100}]$ | Z=Voc(V), Y=Tmin(°C), X=γ(%/°C) | X=Vcold(V) |
| **CMPPT** | $I_{\text{mppt}} = \frac{P_{\text{solar}}}{V_{\text{batt\_min}}} \times 1.25$ | Y=Psolar(W), X=Vbmin(V) | X=Imppt(A) |
| **VDROP** | $\%V_{\text{drop}} = \frac{2 \times L \times I \times R}{1000 \times V_{\text{sys}}} \times 100$ | Z=L(ft), Y=I(A), X=R(Ω/kft) | X=VdPct(%) |
| **CRATE** | $P_{\text{max}} = C_{\text{Ah}} \times \text{C-Rate} \times V_{\text{sys}}$ | Y=CAh(Ah), X=Crate | X=Pmax(W) |

### Support Programs

| Program | Purpose |
|---------|---------|
| **SRSET** | Initialize/reset default parameters |
| **CHAIN** | Guided walkthrough of sizing formulas |
| **SOLAR** | Three-page master menu |

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
| `Crate` | Battery max continuous C-Rate | 0.5 |
| `Vbmin` | Minimum empty battery voltage (V) | 40 |

Change a parameter anytime: `0.90 STO "Ninv"`. Run `XEQ "SRSET"` to reset all to defaults.

### Results (stored by each function)

| Variable | Symbol | Description | Unit |
|----------|--------|-------------|------|
| `Eload` | $E_{\text{load}}$ | Daily energy consumption | Wh |
| `Ebatt` | $E_{\text{battery}}$ | Energy needed from battery | Wh |
| `Ctot` | $C_{\text{total}}$ | Total battery capacity (single day) | Wh |
| `CAh` | $C_{\text{Ah}}$ | Battery capacity | Ah |
| `Cauto` | $C_{\text{autonomous}}$ | Battery capacity with autonomy days | Wh |
| `Psolr` | $P_{\text{solar}}$ | Required solar array power | W |
| `Ppeak` | $P_{\text{peak}}$ | Peak load power | W |
| `Pcont` | $P_{\text{continuous}}$ | Minimum inverter continuous rating | W |
| `Vcold` | $V_{\text{oc\_cold}}$ | Cold-weather max open-circuit voltage | V |
| `Imppt` | $I_{\text{mppt}}$ | MPPT controller output current rating | A |
| `Vd` | $V_{\text{drop}}$ | Absolute wire voltage drop | V |
| `VdPct` | $\%V_{\text{drop}}$ | Wire voltage drop as percentage | % |
| `Imax` | $I_{\text{max}}$ | Max battery continuous discharge current | A |
| `Pmax` | $P_{\text{max}}$ | Max battery continuous discharge power | W |

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
3. **Eload** — daily energy, with $P_{\text{idle}} \times 24$ phantom load added automatically
4. **Ebatt** — adjusted for inverter efficiency
5. **Ctot** — battery capacity (Wh)
6. **CAh** — battery capacity (Ah)
7. `Crate` — battery C-Rate (default 0.5, from BMS datasheet)
8. **Pmax** — max continuous discharge power (W)
9. **Imax** — max continuous discharge current (A)
10. `Ndays` — autonomy days (default 1, increase for cloudy day protection)
11. **Cauto** — battery capacity scaled for autonomy
12. `PSH` — peak sun hours for your location
13. **Psolr** — required solar array wattage
14. `Vbmin` — minimum empty battery voltage (default 40V)
15. **Imppt** — MPPT controller current rating needed (A)
16. `Ppeak` — peak load power (defaults to Pavg, adjust upward for motor surge)
17. **Pcont** — minimum inverter continuous rating

## SOLAR Menu

`XEQ "SOLAR"` displays a three-page programmable menu:

```
Page 1:  ELOAD  EBATT  BCAP   PSOLR  PINV   MORE
Page 2:  DCYCL  AUTON  VCOLD  CMPPT  VDROP  MORE
Page 3:  CRATE  SRSET  CHAIN                 MORE
```

Set up your stack, then press a menu key to run that function. Press **MORE** to cycle through pages (wraps around). Press **EXIT** to leave the menu.

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

---

### 6. Temperature-Adjusted Solar Panel Voltage — `VCOLD`

$$V_{\text{oc\_cold}} = V_{\text{oc\_stc}} \times \left[ 1 + \left( T_{\text{min}} - 25 \right) \times \frac{\gamma_{V_{\text{oc}}}}{100} \right]$$

Solar panel open-circuit voltage ($V_{\text{oc}}$) rises in cold weather. A series string of panels can spike voltage high enough to destroy an MPPT charge controller. Use this to verify your string voltage stays within the controller's max input voltage rating.

| Symbol | Stack Register | Description |
|--------|---------------|-------------|
| $V_{\text{oc\_stc}}$ | Z | Open-circuit voltage at STC ($25°\text{C}$), from panel datasheet | V |
| $T_{\text{min}}$ | Y | Record low temperature for your location | °C |
| $\gamma_{V_{\text{oc}}}$ | X | Temperature coefficient of $V_{\text{oc}}$ (negative, e.g., $-0.28$) | %/°C |
| $V_{\text{oc\_cold}}$ | `Vcold` | Maximum cold-weather open-circuit voltage | V |

> **Example:** A panel with $V_{\text{oc}} = 40\text{V}$, coefficient $-0.28\%/°\text{C}$, at $-10°\text{C}$:
>
> ```
> 40 ENTER -10 ENTER 0.28 +/- XEQ "VCOLD"   @ X = 43.92 V
> ```
>
> For 3 panels in series: `3 *` → $131.76\text{V}$ (check against controller max input)

### 7. MPPT Controller Amperage — `CMPPT`

$$I_{\text{mppt}} = \frac{P_{\text{solar\_array}}}{V_{\text{batt\_min}}} \times 1.25$$

MPPT controllers step down high solar panel voltage to battery charging voltage. Size the controller's ampere rating based on maximum output current with the $1.25$ NEC safety factor.

| Symbol | Stack Register / Variable | Description |
|--------|--------------------------|-------------|
| $P_{\text{solar\_array}}$ | Y | Total array wattage (use `Psolr` from sizing) | W |
| $V_{\text{batt\_min}}$ | X / `Vbmin` | Minimum empty battery voltage | V | Default: 40 |
| $I_{\text{mppt}}$ | `Imppt` | Required MPPT controller current rating | A |

> **Example:** $1307\text{W}$ array, $44\text{V}$ minimum battery voltage:
>
> ```
> RCL "Psolr" ENTER 44 XEQ "CMPPT"          @ X = 37.1 A (need ≥40A controller)
> ```

### 8. Wire Voltage Drop — `VDROP`

$$V_{\text{drop}} = \frac{2 \times L \times I \times R}{1000}$$

$$\%V_{\text{drop}} = \frac{V_{\text{drop}}}{V_{\text{system}}} \times 100$$

Long wire runs between solar arrays or batteries waste energy as heat. NEC code requires keeping voltage drop under $3\%$.

| Symbol | Stack Register / Variable | Description |
|--------|--------------------------|-------------|
| $L$ | Z | One-way wire distance | ft |
| $I$ | Y | Current through the wire | A |
| $R$ | X | Wire resistance (e.g., 10 AWG $\approx 1.24$, 4 AWG $\approx 0.31$) | Ω/kft |
| $V_{\text{system}}$ | `Vsys` | System voltage (read from named variable) | V |
| $V_{\text{drop}}$ | `Vd` | Absolute voltage drop | V |
| $\%V_{\text{drop}}$ | `VdPct` | Percentage voltage drop (NEC limit: $< 3\%$) | % |

> **Example:** $50\text{ft}$ run, $25\text{A}$, 10 AWG wire ($1.24\,\Omega/\text{kft}$):
>
> ```
> 50 ENTER 25 ENTER 1.24 XEQ "VDROP"        @ X = 6.05% — too high, need thicker wire
> RCL "Vd"                                    @ X = 3.10 V absolute drop
> ```

### 9. Battery C-Rate Discharge Limit — `CRATE`

$$I_{\text{max}} = C_{\text{Ah}} \times \text{C-Rate}$$

$$P_{\text{max}} = I_{\text{max}} \times V_{\text{system}}$$

A battery's C-Rate dictates how fast it can be discharged without tripping its BMS. A $100\text{Ah}$ battery rated at $0.5\text{C}$ can only output $50\text{A}$ ($2560\text{W}$ at $51.2\text{V}$).

| Symbol | Stack Register / Variable | Description |
|--------|--------------------------|-------------|
| $C_{\text{Ah}}$ | Y | Battery capacity (use `CAh` from sizing) | Ah |
| $\text{C-Rate}$ | X / `Crate` | Max continuous discharge rate from BMS spec | — | Default: 0.5 |
| $V_{\text{system}}$ | `Vsys` | System voltage (read from named variable) | V |
| $I_{\text{max}}$ | `Imax` | Max continuous discharge current | A |
| $P_{\text{max}}$ | `Pmax` | Max continuous discharge power | W |

> **Example:** $92\text{Ah}$ battery, $1\text{C}$ rating, $51.2\text{V}$ system:
>
> ```
> RCL "CAh" ENTER 1 XEQ "CRATE"             @ X = 4706 W max continuous
> RCL "Imax"                                  @ X = 91.9 A max current
> ```
