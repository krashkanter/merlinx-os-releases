Two experimental server partition images for **Redmi Note 9 / merlinx (tested product merlin, MT6768)**, based on **LineageOS 24.0 nightly 2026-11-10 / Android 17**.

- `server-boot.img.gz`: source-built `4.19.325-cip136-st20-g6fbdf4e6800a` kernel with 48 container options, packaged with the original nightly ramdisk and DTB.
- `system_ext-services.img.gz`: matching nightly system_ext with two added Android init files for the existing server stack and DroidUtils daemon.
- `merlinx-server-kernel-source.tar.gz`: complete corresponding kernel source, custom configuration fragment, resolved configuration and original build script. Upstream licensing files are retained.
- `SHA256SUMS` and `SHA256SUMS.images`: checksums for downloads and decompressed images.

**Read the [installation, source and rollback notes](https://github.com/krashkanter/merlinx-os-releases/blob/lineage-24-server/README.md) before flashing.** Exact build identity and base-image checksum are in [PROVENANCE.json](https://github.com/krashkanter/merlinx-os-releases/blob/lineage-24-server/PROVENANCE.json). The older LineageOS 20 release remains separate.

Requirements: unlocked bootloader, the exact matching nightly, and the existing tested AVB configuration (vbmeta hashtree-disabled flag `1`). These images use unsigned AVB footers. The boot image is flashed to `boot` in bootloader fastboot; system_ext must be flashed to `system_ext` in **fastbootd**, with `is-userspace: yes`.

Verify downloads and decompression on Linux/WSL:

```sh
sha256sum -c SHA256SUMS
gzip -dk server-boot.img.gz system_ext-services.img.gz
sha256sum -c SHA256SUMS.images
```

**The system_ext image requires pre-provisioned `/data/local/server/quiet-hardware.sh`, `/data/local/server/start.sh` and `/data/local/sysutils/bin/sysutilsd`.** It does not install Debian, Docker, apps, credentials or server data. The existing backend, startup scripts and deployment templates are published separately in [Kela Server](https://github.com/krashkanter/kela-server). Create `/data/local/server/disable-autostart` to hold startup while repairing dependencies.

Android is globally Enforcing, but these root services run in LineageOS userdebug's **permissive su domain**. No confined server policy or Magisk installation is included. This is an experimental personally controlled userdebug setup.

Validation: exact installed image hashes; all requested kernel options; Wi-Fi Internet and Bluetooth STATE_ON; Docker ARM64/overlay2/networking; image filesystem/content/AVB checks and init parser validation; successful automatic startup across two boots. Hybrid Android cgroups retain resource-control limitations. Bluetooth peripherals and offline startup were not exhaustively tested.

Only the custom kernel was compiled from source. Boot and system_ext were repacked from the matching official nightly; the full custom ROM build was not completed. This release contains no complete ROM installer, device backup, modem/NVRAM images, personal data, or external boot menu. Preserve matching original partition images for rollback and do not format userdata.

Credits: the base ROM and device support are from LineageOS and its merlinx/MT6768 maintainers; the kernel retains the Linux/CIP, Xiaomi, MediaTek and other upstream contributors' work. Compilation uses Android/LLVM Clang r416183b; packaging uses AOSP mkbootimg, LineageOS/AOSP AVB and e2fsprogs. The local changes are the container configuration, kernel build/repack and two init integration files. [Full credits and pinned source links](https://github.com/krashkanter/merlinx-os-releases/blob/lineage-24-server/CREDITS.md).
