# merlinx OS releases

Unofficial images for the Redmi Note 9 (`merlinx`, tested product `merlin`, MediaTek MT6768).

This branch contains the sources, configuration and provenance for **merlinx LineageOS 24 server images — 2026-11-17**. Download the images from the `lineage-24-server-20261117` GitHub release.

The older LineageOS 20 release remains separate and is incompatible with these images.

See [CREDITS.md](CREDITS.md) for the upstream projects, exact source revisions, toolchain and local changes.

## Contents

| Release asset | Purpose |
| --- | --- |
| `server-boot.img.gz` | Boot image with the source-built container-enabled kernel; official ramdisk and DTB preserved. |
| `system_ext-services.img.gz` | Matching system_ext image with native Android init startup services. |
| `merlinx-server-kernel-source.tar.gz` | Complete kernel source at the exact upstream commit, plus the custom configuration fragment, resolved build configuration and build script. |
| `SHA256SUMS` | SHA-256 checksums of downloaded assets. |
| `SHA256SUMS.images` | SHA-256 checksums of decompressed partition images. |

Base: **`lineage-24.0-20261110-nightly-merlinx-signed.zip`**, Android 17. Kernel: **`4.19.325-cip136-st20-g6fbdf4e6800a`**. Exact hashes and build identity are recorded in [PROVENANCE.json](PROVENANCE.json).

These are two partition images for an existing installation of that base. The complete custom ROM build was not finished. The system_ext image was repacked from the installed nightly; the custom kernel was compiled from source and repacked into its official boot image.

## Requirements and flashing

- Unlocked bootloader and the exact matching LineageOS 24 nightly already installed. Do not flash these over MIUI or LineageOS 20.
- Current Android platform-tools and access to recovery and fastbootd.
- Preserve the matching original boot and system_ext images before flashing. This release does not contain a device backup or personal data.
- The tested device already had vbmeta hashtree verification disabled (flags `1`) and a linear system_ext mapping. The custom AVB footers use algorithm `NONE`; they are not trusted OEM signatures. Do not use these instructions on a locked or verification-enforcing installation.

Verify and decompress on Linux/WSL:

```sh
sha256sum -c SHA256SUMS
gzip -dk server-boot.img.gz system_ext-services.img.gz
sha256sum -c SHA256SUMS.images
```

For the kernel image, enter bootloader fastboot and confirm the target:

```sh
adb reboot bootloader
fastboot getvar product
fastboot flash boot server-boot.img
fastboot reboot
```

The expected tested product is `merlin`. Flash `system_ext` only after provisioning the runtime dependencies described below. It must be flashed in **userspace fastboot (fastbootd)**:

```sh
adb reboot fastboot
fastboot getvar is-userspace
# Continue only when is-userspace is yes.
fastboot flash system_ext system_ext-services.img
fastboot reboot
```

Do not erase userdata, flash super, or modify modem/NVRAM/calibration partitions as part of this installation. These steps do not install Debian, Docker, apps or the server data directory.

## Native startup dependencies

The system_ext image adds exactly `/etc/init/phone-services.rc` and `/bin/phone-services`. It preserves the existing 3,635 filesystem entries. Source files are in [source/phone-init](source/phone-init).

After `sys.boot_completed=1`, the wrapper expects these **already provisioned** executables/scripts:

| Init service | Required path | Behavior |
| --- | --- | --- |
| `phone-hardware` | `/data/local/server/quiet-hardware.sh` | Runs the locally configured hardware preset once. |
| `phone-stack` | `/data/local/server/start.sh` | Starts the existing server stack and monitors dockerd; retries after 30 seconds if it exits. |
| `phone-sysutils` | `/data/local/sysutils/bin/sysutilsd` | Starts the DroidUtils daemon without its `-boot` mode. |

The configured server uses an ARM64 Debian chroot at `/data/local/debian`; its setup and credentials are not included. The daemon source is published at https://github.com/krashkanter/droidutils. The retained `sysutils` runtime paths are intentional.

Create `/data/local/server/disable-autostart` from recovery/rooted ADB to hold all three startup wrappers while repairing their dependencies. Logs go to `/data/local/server/boot-logs/`. Delete the marker to allow startup. On both tested boots Android's named wlan0 routing table appeared after the first startup attempt; the automatic retry recovered after about 30 seconds. Offline startup was not tested.

Android remains globally **Enforcing**, but these root services explicitly run in LineageOS userdebug's existing **permissive `su` domain**. No new confined SELinux policy was added. This configuration is intended for a personally controlled userdebug server, not a production user build. Magisk is not required.

## Validation and limits

- Installed custom boot image and all 48 requested kernel options were verified. Wi-Fi Internet access and Bluetooth `STATE_ON` passed; Bluetooth peripheral compatibility was not exhaustively tested.
- The system_ext image passed filesystem, content-preservation, unsigned AVB and Android init parser checks. Startup passed the initial boot and a second normal reboot without manual startup commands.
- Docker ARM64 containers, overlay2 storage, bridge networking and outbound DNS/HTTPS worked in the provisioned Debian chroot. Android's hybrid cgroups still limit some resource controls.
- Hardware presets live under `/data`, outside these images. Fingerprint service was subsequently re-enabled after reconnecting the reader; physical enrollment/authentication was not confirmed. Removed cameras enumerated zero devices without an observed restart loop. Those later data-side changes are not packaged here.
- No partition layout changes or PC-style external boot menu are provided.

Validation records are in [validation](validation). Device identifiers, network addresses, tokens, account data and server state are omitted.

## Kernel source and rebuilding

Upstream: https://github.com/LineageOS/android_kernel_xiaomi_mt6768 at `6fbdf4e6800ab732f8f132cd3eca05b26e357255`. The sole local addition to that tree is [merlin-server.config](source/kernel/merlin-server.config). The kernel source archive includes the upstream licensing files; their original terms apply. It does not relicense the base ROM or vendor components.

Compiler: Android Clang 12.0.5 (`r416183b`, build `7284624`), from `LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b` at `54220fd601050b350b2af7adc913089ebf0e7aed`. The recorded official base manifest is [source/official-build-manifest.xml](source/official-build-manifest.xml); it describes the base build and does not establish that a complete custom ROM was built.

The original build script expects a Lineage source checkout under `~/android/lineage`, kernel source under `kernel/xiaomi/mt6768`, the compiler at `prebuilts/clang/kernel/linux-x86/clang-r416183b`, and GNU aarch64/arm cross tools on PATH. Install the supplied configuration fragment in the kernel's `arch/arm64/configs/vendor/` directory, then run:

```sh
bash source/kernel/build-server-kernel.sh
```

The resolved configuration is [merlinx-server-kernel.config](source/kernel/merlinx-server-kernel.config). The build uses `vendor/mt6768_defconfig`, `vendor/merlin.config` and `vendor/merlin-server.config`.

`source/kernel/package-boot.sh` records the packaging procedure used for the published boot image. It expects the compiled `merlinx-server-Image.gz` and resolved configuration under `~/android/merlinx-build/artifacts`, matching original `official-boot.img` and `recovery.img` under `~/android/merlinx-build/prebuilt-install`, and the Lineage mkbootimg/AVB tools. It checks the exact kernel payload hash and preserves the official ramdisk and DTB.

`source/phone-init/build-image.py` records the system_ext repack procedure, with machine-specific paths replaced by required environment variables:

```sh
IMAGES_DIR=/path/to/images WORK_DIR=/path/to/new-work-dir \
LINEAGE_ROOT=/path/to/lineage python3 source/phone-init/build-image.py
```

Place the matching unmodified `system_ext-before-services.img` in `IMAGES_DIR`. The script requires Python 3, e2fsprogs, the Lineage AVB tool, and sufficient permissions for debugfs extraction; use a fresh work directory. `phone-services.mk` provides integration for future source builds, restricted to userdebug/eng. These archived recipes do not claim a bit-for-bit reproducible full ROM build.

## Rollback

Enter fastbootd and flash the original matching system_ext image to `system_ext`, then flash the original matching boot image to `boot` in bootloader fastboot. Do not format data. Restoring only boot will not remove the native startup services from system_ext.
