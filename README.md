# dm42fn — DM42 / HP-42S Function Library

A collection of HP-42S/DM42 program suites organized by domain. Each subdirectory contains a self-contained `.hp42s` program file and its own README with formulas, variable reference, and usage instructions.

## Function Suites

| Directory | Programs | Description |
|-----------|----------|-------------|
| [solar/](solar/) | 14 | Off-grid solar power sizing — energy budgeting, battery capacity, solar array sizing, inverter headroom, plus hardware engineering checks |

## Loading Programs

Each suite produces a single `.hp42s` text file. To load onto a DM42 or Free42:

1. Convert to binary `.raw` via the [SwissMicros online encoder](https://technical.swissmicros.com/decoders/dm42/) or `txt2raw` from [Free42](https://thomasokken.com/free42/)
2. **DM42:** connect via USB, copy `.raw` file, import via file manager
3. **Free42 desktop:** File > Import Programs
