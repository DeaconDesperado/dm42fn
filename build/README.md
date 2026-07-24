# BUILD — Building Construction Calculator for DM42

A set of HP-42S/DM42 programs for rafter sizing, birdsmouth layout, and cut angles. Supports both gable (two-sided) and shed (single-pitch) roof framing. Default parameters assume standard 2x dimensional lumber.

## Quick Start

```
XEQ "BUILD"                       @ show menu, press RAFTP:
  Width=48  R/S                   @ building width (inches)
  Pitch=5   R/S                   @ 5/12 pitch
    -> Llen=25.1875               @ rafter line length (R/S)
    -> Pcut=22.6199               @ plumb cut angle (R/S)
    -> Run=23.25                  @ horizontal run (R/S)
    -> Rise=9.6875                @ vertical rise

XEQ "BIRD"                        @ birdsmouth cut sheet
    -> Llen=25.1875               @ mark from ridge cut (R/S)
    -> Pcut=22.6199               @ miter saw angle (R/S)
    -> Seat=4.0                   @ seat cut length (R/S)
    -> Notch=1.5385               @ depth into rafter (R/S)
  Ohang=6   R/S                   @ overhang along rafter
    -> Tlen=31.1875               @ total rafter length

RCL "Llen" XEQ "IMP"             @ Z=25, Y=3, X=16  (25 3/16")
```

Stack-based (no prompts):

```
23.25 ENTER 9.6875 XEQ "RAFTL"   @ -> X=25.1875 (Llen)
RCL "Pcut"                       @ -> 22.6199
```

## Programs

### Rafter Functions

| Program | Description | Inputs | Outputs |
|---------|-------------|--------|---------|
| **RAFTP** | Rafter from pitch ratio | INPUT Width, Pitch | Llen, Pcut, Run, Rise (VIEW/STOP) |
| **RAFTD** | Rafter from degrees | INPUT Width, Deg | Llen, Pcut, Run, Rise (VIEW/STOP) |
| **RAFTL** | Rafter from run and rise | Y=Run, X=Rise | X=Llen (stores Pcut) |

### Cut Layout

| Program | Description | Inputs | Outputs |
|---------|-------------|--------|---------|
| **BIRD** | Birdsmouth cut sheet | Gable: INPUT Ohang; Shed: INPUT OhLow, OhHi | Llen, Pcut, Seat, Notch, Tlen (VIEW/STOP) |

### Unit Conversion (stack-based)

| Program | Description | Stack In | Stack Out |
|---------|-------------|----------|-----------|
| **IMP** | Decimal to imperial fraction (power-of-2 denom, max 64) | X=decimal | Z=whole, Y=numer, X=denom |
| **METRC** | Imperial fraction to decimal | Z=whole, Y=numer, X=denom | X=decimal |

### Support Programs

| Program | Purpose |
|---------|---------|
| **BSET** | Initialize/reset default parameters |
| **SHED** | Toggle shed/gable mode (sets Rb=0 for shed, Rb=1.5 for gable) |
| **BUILD** | Master menu |

## Variables

### Parameters (defaults set by BSET)

| Variable | Description | Default |
|----------|-------------|---------|
| `Rb` | Ridge beam width (gable) or ledger thickness (shed) | 1.5" gable / 0" shed |
| `Wall` | Wall plate width (for birdsmouth seat cut) | 4.0" (3.5" stud + 0.5" sheathing) |
| `Ohang` | Overhang past birdsmouth, gable mode (along rafter) | 0" |
| `OhLow` | Overhang past low wall, shed mode (along rafter) | 0" |
| `OhHi` | Overhang past high wall, shed mode (along rafter) | 0" |

Change a parameter anytime: `5.5 STO "Rb"`. Run `XEQ "BSET"` to reset all to defaults.

### Results (stored by rafter functions)

| Variable | Description | Unit |
|----------|-------------|------|
| `Run` | Horizontal run | in |
| `Rise` | Vertical rise | in |
| `Llen` | Line length (ridge to birdsmouth, or between birdsmouth points in shed) | in |
| `Pcut` | Plumb cut angle | degrees |
| `Seat` | Seat cut length (= Wall) | in |
| `Notch` | Birdsmouth depth perpendicular to rafter | in |
| `Tlen` | Total rafter length (Llen + overhang) | in |

### Flags

| Flag | Purpose | Default |
|------|---------|---------|
| 07 | Defaults initialized | Set by BSET |
| 08 | Shed mode (freestanding single-pitch, Rb=0) | Clear (gable) |

## BUILD Menu

`XEQ "BUILD"` displays a two-page programmable menu:

```
Page 1:  RAFTP  RAFTD  RAFTL  BIRD  BSET  MORE→
Page 2:  IMP    METRC  SHED    ·     ·   ←MORE
```

Set up your stack (for RAFTL, IMP, METRC), then press a menu key. Press **EXIT** to leave.

## Loading onto DM42 / Free42

1. Convert `build.hp42s` to binary:
   - **Online:** paste into the [SwissMicros encoder](https://technical.swissmicros.com/decoders/dm42/) and click Encode
   - **CLI:** use `txt2raw` from the [Free42 distribution](https://thomasokken.com/free42/)
2. **DM42:** connect via USB, copy the `.raw` file, import via file manager
3. **Free42 desktop:** File > Import Programs, select the `.raw` file

## Formulas Reference

### Rafter Line Length — `RAFTP`, `RAFTD`, `RAFTL`

A common rafter forms the hypotenuse of a right triangle defined by the horizontal run and vertical rise.

#### From pitch ratio (`RAFTP`)

Roof pitch is expressed as inches of rise per 12 inches of run (e.g., 5/12 means 5" rise per 12" of horizontal run).

$$Run = \frac{Width - R_b}{2}$$

$$Rise = Run \times \frac{Pitch}{12}$$

$$L_{len} = \sqrt{Run^{2} + Rise^{2}}$$

| Symbol | Variable | Description |
|--------|----------|-------------|
| $Width$ | `Width` | Building width (outside-to-outside) |
| $R\_b$ | `Rb` | Ridge beam width (default 1.5") |
| $Pitch$ | `Pitch` | Unit rise per 12" run |
| $Run$ | `Run` | Horizontal run |
| $Rise$ | `Rise` | Vertical rise (ridge height above wall plate) |
| $L\_{len}$ | `Llen` | Line length (rafter length, ridge to birdsmouth) |

For shed (single-pitch) roofs, `XEQ "SHED"` sets flag 08 and clears Rb to 0 (freestanding — no ridge beam). The full width is used as run:

$$Run_{shed} = Width$$

For a **ledger-attached** shed (rafter bolts into the side of a taller structure via a ledger board), set Rb to the ledger board thickness after toggling to shed mode:

```
XEQ "SHED"                        @ sets Rb=0
1.5 STO "Rb"                     @ ledger board = 2x (1.5" actual)
```

#### From degrees (`RAFTD`)

When the roof angle is known in degrees from horizontal:

$$Rise = Run \times \tan(Deg)$$

$$L_{len} = \frac{Run}{\cos(Deg)}$$

#### From direct measurements (`RAFTL`)

When run and rise are already known, push them onto the stack:

```
Run ENTER Rise XEQ "RAFTL"   @ -> X=Llen
```

### Plumb Cut Angle — `Pcut`

The plumb cut angle is the miter saw setting for cutting the rafter at the ridge and at the birdsmouth. It equals the roof pitch angle from horizontal:

$$P_{cut} = \arctan\!\left(\frac{Rise}{Run}\right) = \arctan\!\left(\frac{Pitch}{12}\right)$$

Set the miter saw to $P\_{cut}$ degrees to make the ridge plumb cut. The same angle applies at the birdsmouth plumb cut.

Where two rafters meet at a ridge beam, each gets a plumb cut at $P\_{cut}$. If rafters butt directly without a ridge beam, the included angle between the two rafter faces is:

$$\theta_{apex} = 180° - 2 \times P_{cut}$$

> **Example:** 5/12 pitch → $P\_{cut}$ = 22.62°, apex included angle = 134.76°

### Birdsmouth Cut — `BIRD`

The birdsmouth is a notch where the rafter sits on the wall plate, consisting of a horizontal **seat cut** and a vertical **plumb cut**.

#### Location

**Gable:** mark the birdsmouth at distance $L\_{len}$ from the ridge plumb cut, measured along the rafter.

**Shed:** birdsmouth cuts at both ends of the rafter. $L\_{len}$ is the distance between the two birdsmouth points. The geometry (seat, notch, angle) is the same at both ends.

#### Seat cut

The seat cut length equals the wall plate width:

$$Seat = Wall$$

Default 4.0" = 3.5" stud (2x4 framing) + 0.5" sheathing.

#### Notch depth

The depth of the birdsmouth measured perpendicular to the rafter's bottom edge:

$$Notch = Wall \times \sin(P_{cut})$$

**Rule of thumb:** notch depth should not exceed 1/3 of the rafter lumber width. For a 2x6 rafter (5.5" actual), maximum notch ≈ 1.83".

| Pitch | $P\_{cut}$ | Notch (Wall=4") | OK for 2x6? | OK for 2x4? |
|-------|-----------|-----------------|-------------|-------------|
| 4/12 | 18.43° | 1.26" | yes (< 1.83") | no (> 1.17") |
| 5/12 | 22.62° | 1.54" | yes | no |
| 6/12 | 26.57° | 1.79" | yes (borderline) | no |
| 8/12 | 33.69° | 2.22" | no (> 1.83") | no |

Adjust `Wall` if the notch depth exceeds 1/3 of your rafter width:

```
3.5 STO "Wall"   @ narrower seat for steeper pitches
```

#### Overhang

Overhang is measured along the rafter past the birdsmouth point(s). To convert a horizontal eave projection to along-rafter distance:

$$Ohang = \frac{horizontal}{\cos(P_{cut})}$$

**Gable mode** — one overhang past the single birdsmouth:

$$T_{len} = L_{len} + Ohang$$

**Shed mode** — overhang at both ends (low wall and high wall):

$$T_{len} = OhLow + L_{len} + OhHi$$

> **Gable example:** 48" building, 5/12 pitch, 6" overhang along rafter:
>
> ```
> XEQ "RAFTP"                    @ Width=48, Pitch=5
>   -> Llen=25.1875  (25 3/16")
>   -> Pcut=22.6199°
>   R/S R/S
> XEQ "BIRD"
>   -> Llen=25.1875               @ mark here from ridge
>   -> Pcut=22.6199               @ miter saw angle
>   -> Seat=4.0                   @ seat cut length
>   -> Notch=1.5385               @ OK for 2x6 (< 1.83")
>   Ohang=6
>   -> Tlen=31.1875  (31 3/16")   @ total rafter cutting length
> ```
>
> Cut list per rafter pair:
> - **Ridge plumb cut** at miter saw angle 22.62°
> - **Birdsmouth** at 25 3/16" from ridge cut (seat=4", notch=1 9/16")
> - **Tail cut** at 31 3/16" from ridge cut (same angle as plumb cut)

> **Shed example:** 96" wide chicken coop, 4/12 pitch, 12" low-side eave, 6" high-side eave:
>
> ```
> XEQ "SHED"                     @ sets Rb=0, shed mode
> XEQ "RAFTP"                    @ Width=96, Pitch=4
>   -> Llen=101.1929
>   -> Pcut=18.4349°
>   R/S R/S
> XEQ "BIRD"
>   -> Llen=101.1929              @ between birdsmouth points
>   -> Pcut=18.4349               @ miter saw angle (both ends)
>   -> Seat=4.0                   @ seat cut (both ends)
>   -> Notch=1.2649
>   OhLow=12  OhHi=6
>   -> Tlen=119.1929              @ total board length
> ```
>
> Cut list:
> - **Birdsmouth at both ends** (same angle, seat, and notch)
> - **Low-side tail cut** 12" past low birdsmouth
> - **High-side tail cut** 6" past high birdsmouth
> - No ridge plumb cut — rafter spans wall to wall
