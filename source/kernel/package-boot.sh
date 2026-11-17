#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
import subprocess,shlex,struct,hashlib,json,zipfile
r=Path.home()/'android/lineage'; s=Path.home()/'android/merlinx-build'; p=s/'prebuilt-install'
old=(p/'official-boot.img').read_bytes(); rec=(p/'recovery.img').read_bytes()
def kernel(b):
 assert b[:8]==b'ANDROID!' and struct.unpack_from('<I',b,40)[0]==2
 page=struct.unpack_from('<I',b,36)[0]; n=struct.unpack_from('<I',b,8)[0]
 assert page==2048
 return b[page:page+n]
assert kernel(rec)==kernel(old),'Official recovery/boot kernel mismatch'
custom=s/'artifacts/merlinx-server-Image.gz'
assert hashlib.sha256(custom.read_bytes()).hexdigest()=='2f2e446a8e541fb22823e3e7e833400b9c1b03202664d1a3502864bc10a53520'
cfg=set((s/'artifacts/merlinx-server-kernel.config').read_text().splitlines())
req=[l for l in (r/'kernel/xiaomi/mt6768/arch/arm64/configs/vendor/merlin-server.config').read_text().splitlines() if l.startswith('CONFIG_')]
assert all(l in cfg for l in req)
args=shlex.split(subprocess.check_output(['python3',str(r/'system/tools/mkbootimg/unpack_bootimg.py'),'--boot_img',str(p/'official-boot.img'),'--out',str(p/'boot-unpacked'),'--format=mkbootimg'],text=True))
args[args.index('--kernel')+1]=str(custom)
out=p/'server-boot.img'
subprocess.run(['python3',str(r/'system/tools/mkbootimg/mkbootimg.py'),*args,'--output',str(out)],check=True)
subprocess.run(['python3',str(r/'external/avb/avbtool.py'),'add_hash_footer','--image',str(out),'--partition_name','boot','--partition_size','67108864','--algorithm','NONE','--salt','e142fbf0de31eb167c89dbef258c78d4ecd3ba80aabfa077b7d6193444cfa8ec','--prop','com.android.build.boot.os_version:17','--prop','com.android.build.boot.fingerprint:Redmi/lineage_merlinx/merlinx:17/CP2A.260605.016/826335cf90:userdebug/release-keys'],check=True)
(p/'boot.img').symlink_to('server-boot.img') if not (p/'boot.img').exists() else None
subprocess.run(['python3',str(r/'external/avb/avbtool.py'),'verify_image','--image',str(out)],check=True)
subprocess.run(['python3',str(r/'system/tools/mkbootimg/unpack_bootimg.py'),'--boot_img',str(out),'--out',str(p/'server-unpacked')],check=True,stdout=subprocess.DEVNULL)
assert kernel(out.read_bytes())==custom.read_bytes()
for f in ['ramdisk','dtb']:
 assert (p/'boot-unpacked'/f).read_bytes()==(p/'server-unpacked'/f).read_bytes(),f
assert len(out.read_bytes())==67108864
report={'official_kernel_revision':'6fbdf4e6800ab732f8f132cd3eca05b26e357255','custom_kernel_revision':'6fbdf4e6800ab732f8f132cd3eca05b26e357255','container_options':len(req),'ramdisk_dtb':'Preserved byte-for-byte from official boot','files':{f:hashlib.sha256((p/f).read_bytes()).hexdigest() for f in ['official-boot.img','recovery.img','server-boot.img']}}
(p/'validation.json').write_text(json.dumps(report,indent=2)+'\n'); print(json.dumps(report,indent=2))
PY
