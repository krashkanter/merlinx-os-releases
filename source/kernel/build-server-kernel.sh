#!/usr/bin/env bash
set -euo pipefail
root="$HOME/android/lineage"
export PATH="$root/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin:$PATH"
cd "$root/kernel/xiaomi/mt6768"
out="$HOME/android/merlinx-build/kernel-clang"
mkdir -p "$out"
args=(O="$out" ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1)
clang --version | head -1
make "${args[@]}" vendor/mt6768_defconfig vendor/merlin.config vendor/merlin-server.config > "$HOME/android/merlinx-build/logs/kernel-clang-config.log" 2>&1
python3 - <<'PY'
from pathlib import Path
s=(Path.home()/'android/merlinx-build/kernel-clang/.config').read_text().splitlines()
r=Path('arch/arm64/configs/vendor/merlin-server.config').read_text().splitlines()
missing=[x for x in r if x.startswith('CONFIG_') and x not in s]
assert not missing,missing
print('All container options retained with the target Clang compiler.',flush=True)
PY
make -j4 "${args[@]}" Image.gz dtbs modules > "$HOME/android/merlinx-build/logs/kernel-compile.log" 2>&1
sha256sum "$out/arch/arm64/boot/Image.gz" > "$HOME/android/merlinx-build/artifacts/kernel-image.sha256"
echo 'Standalone kernel build complete.'