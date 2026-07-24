# TENON — Woodworking Joinery Calculator Suite for DM42

A set of HP-42S/DM42 programs for dimensioning frame-and-panel joinery and woodshop calculations. Default parameters are based on the Ogee 91-501 rail-and-stile router bit set (7/16" groove depth, 1/4" slot thickness).

## Quick Start

```
XEQ "TNSET"                    @ initialize defaults (run once)
15 ENTER 24 XEQ "RPANL"       @ Tw=15, Th=24
  -> Rcut=11.375               @ XEQ "IMP" -> Z=11, Y=3, X=8
  R/S -> PnlW=11.375           @ (same as Rcut)
  R/S -> PnlH=20.375           @ XEQ "IMP" -> Z=20, Y=3, X=8
```

Decimal to fraction:

```
11.375 XEQ "IMP"               @ -> Z=11, Y=3, X=8  (11 3/8")
XEQ "METRC"                    @ -> X=11.375         (back to decimal)
```

Or use the menu: `XEQ "TENON"` then press a menu key.

## Programs

### Joinery

| Program | Description | Inputs | Outputs |
|---------|-------------|--------|---------|
| **RPANL** | Raised panel door dimensions | Y=Tw, X=Th | Rcut, PnlW, PnlH (VIEW/STOP) |

### Unit Conversion (stack-based)

| Program | Description | Stack In | Stack Out |
|---------|-------------|----------|-----------|
| **IMP** | Decimal to imperial fraction (power-of-2 denom, max 64) | X=decimal | Z=whole, Y=numer, X=denom |
| **METRC** | Imperial fraction to decimal | Z=whole, Y=numer, X=denom | X=decimal |

### Support Programs

| Program | Purpose |
|---------|---------|
| **TNSET** | Initialize/reset default parameters |
| **TENON** | Master menu |

## Variables

### Parameters (defaults set by TNSET)

| Variable | Description | Default |
|----------|-------------|---------|
| `Sw` | Stile face width | 2.25" (2-1/4") |
| `Rw` | Rail face width | 2.25" (2-1/4") |
| `Pw` | Profile / groove depth | 0.4375" (7/16") |

Change a parameter anytime: `2.5 STO "Sw"`. Run `XEQ "TNSET"` to reset all to defaults.

### Results (stored by RPANL)

| Variable | Description | Unit |
|----------|-------------|------|
| `Rcut` | Rail cut length (length of each rail piece) | in |
| `PnlW` | Panel raw stock width (groove-to-groove horizontal span) | in |
| `PnlH` | Panel raw stock height (groove-to-groove vertical span) | in |

### Flag 09

Tracks whether defaults have been initialized. Prevents `TNSET` from overwriting user-modified parameters on repeat `TENON`/`RPANL` calls. Clear with `CF 09` to force re-initialization.

## TENON Menu

`XEQ "TENON"` displays a programmable menu:

```
Page 1:  IMP  METRC  RPANL  ·  TNSET  ·
```

Set up your stack, then press a menu key to run that function. Press **EXIT** to leave the menu.

## Loading onto DM42 / Free42

1. Convert `tenon.hp42s` to binary:
   - **Online:** paste into the [SwissMicros encoder](https://technical.swissmicros.com/decoders/dm42/) and click Encode
   - **CLI:** use `txt2raw` from the [Free42 distribution](https://thomasokken.com/free42/)
2. **DM42:** connect via USB, copy the `.raw` file, import via file manager
3. **Free42 desktop:** File > Import Programs, select the `.raw` file

## Formulas Reference

### Raised Panel Door Dimensions — `RPANL`

A raised panel door consists of a frame (two vertical stiles and two horizontal rails) surrounding a floating panel. The stiles run the full height of the door; the rails fit between them with tongues that extend into grooves cut by the rail-and-stile router bit set.

#### Rail Cut Length

$$R_{cut} = T_w - 2 S_w + 2 P_w$$

The rail's physical length: total door width minus both stile widths, plus two tongue extensions that seat into the stile grooves.

| Symbol | Variable | Description |
|--------|----------|-------------|
| $T\_w$ | `Tw` | Total door width |
| $S\_w$ | `Sw` | Stile face width (default 2-1/4") |
| $P\_w$ | `Pw` | Groove depth / tongue length (default 7/16") |
| $R\_{cut}$ | `Rcut` | Rail cut length |

#### Panel Raw Stock

$$W_{panel} = T_w - 2 S_w + 2 P_w$$

$$H_{panel} = T_h - 2 R_w + 2 P_w$$

The panel raw stock spans from groove bottom to groove bottom in each direction. The width uses stile width $S\_w$ (panel sits between stiles); the height uses rail width $R\_w$ (panel sits between rails).

| Symbol | Variable | Description |
|--------|----------|-------------|
| $T\_h$ | `Th` | Total door height |
| $R\_w$ | `Rw` | Rail face width (default 2-1/4") |
| $W\_{panel}$ | `PnlW` | Panel raw stock width (= $R\_{cut}$) |
| $H\_{panel}$ | `PnlH` | Panel raw stock height |

#### Stile Cut Length

Stiles run the full door height: stile length $= T\_h$. No computation needed.

> **Example:** A 15" x 24" cabinet door with default 2-1/4" stiles/rails and 7/16" Ogee profile:
>
> ```
> 15 ENTER 24 XEQ "RPANL"
>   -> Rcut=11.375               @ XEQ "IMP" -> 11 3/8"
>   R/S -> PnlW=11.375
>   R/S -> PnlH=20.375           @ XEQ "IMP" -> 20 3/8"
> ```
>
> Cut list:
> - **2 stiles:** 2-1/4" x 24"
> - **2 rails:** 2-1/4" x 11-3/8"
> - **1 panel:** 11-3/8" x 20-3/8"

### Decimal to Imperial Fraction — `IMP`

Converts a decimal value to whole number + fraction with the smallest power-of-2 denominator (2, 4, 8, 16, 32, or 64). If no exact match exists, falls back to the nearest 64th.

Results are left on the stack: Z=whole, Y=numerator, X=denominator.

> **Examples:**
>
> ```
> 11.375 XEQ "IMP"       @ Z=11, Y=3, X=8    (11 3/8")
> 2.4375 XEQ "IMP"       @ Z=2,  Y=7, X=16   (2 7/16")
> 8.5 XEQ "IMP"          @ Z=8,  Y=1, X=2    (8 1/2")
> 5 XEQ "IMP"            @ Z=5,  Y=0, X=1    (5")
> ```
>
> Chain with RPANL:
>
> ```
> XEQ "RPANL"             @ Tw=15, Th=24 -> Rcut=11.375
> RCL "Rcut" XEQ "IMP"   @ Z=11, Y=3, X=8    (11 3/8")
> ```

### Imperial Fraction to Decimal — `METRC`

Converts a fraction on the stack back to a decimal value. The inverse of `IMP`.

$$X_{result} = Z + \frac{Y}{X}$$

> **Examples:**
>
> ```
> 11 ENTER 3 ENTER 8 XEQ "METRC"    @ X=11.375
> 2 ENTER 7 ENTER 16 XEQ "METRC"    @ X=2.4375
> ```
>
> Round-trip: `11.375 XEQ "IMP" XEQ "METRC"` → `X=11.375`
