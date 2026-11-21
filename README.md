# merlinx OS releases

Unofficial LineageOS builds and server images for Redmi Note 9 (`merlinx`).

| Release | Base | Files and documentation |
| --- | --- | --- |
| [LineageOS 24 server images — base 2026-11-17](https://github.com/krashkanter/merlinx-os-releases/releases/tag/lineage-24.0-20261117-server) | Android 17; exact LineageOS nightly **2026-11-17** | Experimental custom boot and system_ext images, complete kernel source, checksums and credits. [Installation and source notes](https://github.com/krashkanter/merlinx-os-releases/tree/lineage-24.0-20261117-server). |
| [LineageOS 24 server images — base 2026-11-10](https://github.com/krashkanter/merlinx-os-releases/releases/tag/lineage-24-server-20261117) (tag `lineage-24-server-20261117`, published 2026-11-17) | Android 17; exact LineageOS nightly **2026-11-10** | Same kernel; boot and system_ext images for the older nightly. [Installation and source notes](https://github.com/krashkanter/merlinx-os-releases/tree/lineage-24-server-20261117). |
| [LineageOS 20](https://github.com/krashkanter/merlinx-os-releases/releases/tag/lineage-20) | Android 13 | Older separate ROM and recovery release. |

LineageOS 24 server images must match the installed nightly exactly; pick the row for your nightly. LineageOS 20 and LineageOS 24 releases are incompatible. Read the selected release's instructions before flashing. The LineageOS 24 files are partition add-ons to the matching nightly, not a complete ROM installer.

The server backend and deployment templates are in [Kela Server](https://github.com/krashkanter/kela-server). The Android managers are [Kela](https://github.com/krashkanter/kela) and [DroidUtils](https://github.com/krashkanter/droidutils).

See the LineageOS 24 [credits and pinned upstream source links](https://github.com/krashkanter/merlinx-os-releases/blob/lineage-24.0-20261117-server/CREDITS.md). These unofficial releases do not imply upstream endorsement.
