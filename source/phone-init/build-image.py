"""Build a system_ext image with two init integration files; preserve existing files."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

base = Path(os.environ['IMAGES_DIR'])
init_sources = Path(__file__).resolve().parent
work = Path(os.environ['WORK_DIR'])
work.mkdir(parents=True, exist_ok=True)
avb = Path(os.environ['LINEAGE_ROOT']) / 'external/avb/avbtool.py'
original = base / 'system_ext-before-services.img'
image = work / 'system_ext.img'
shutil.copyfile(original, image)

def run(*args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, **kwargs)

def debug(command):
    result = subprocess.run(['debugfs', '-w', '-R', command, str(image)],
                            check=True, text=True, capture_output=True)
    # debugfs can return zero even when a command fails.
    if any(word in result.stderr for word in ('not found', 'not enough', 'Usage:', 'File exists')):
        raise RuntimeError(result.stderr)
    print(result.stdout + result.stderr)

run('python3', avb, 'erase_footer', '--image', image)
context = work / 'system-file-context'
context.write_bytes(b'u:object_r:system_file:s0\0')
added = {'/etc/init/phone-services.rc': ('phone-services.rc', '0100644'),
         '/bin/phone-services': ('phone-services', '0100755')}
for target, (source, mode) in added.items():
    debug(f'write {init_sources / source} {target}')
    debug(f'set_inode_field {target} mode {mode}')
    debug(f'ea_set -f {context} {target} security.selinux')
    debug(f'stat {target}')
    debug(f'ea_list {target}')

run('e2fsck', '-fn', image)

# Verify every existing file, directory and symlink remains unchanged.
def manifest(img, destination):
    destination.mkdir(exist_ok=True)
    log = destination.parent / (destination.name + '-rdump.log')
    with log.open('w') as output:
        run('debugfs', '-R', f'rdump / {destination}', img,
            stdout=output, stderr=subprocess.STDOUT)
    rows = {}
    for parent, dirs, files in os.walk(destination, followlinks=False):
        for name in dirs + files:
            path = Path(parent) / name
            relative = str(path.relative_to(destination))
            if path.is_symlink():
                rows[relative] = ['symlink', os.readlink(path)]
            elif path.is_file():
                rows[relative] = ['file', hashlib.sha256(path.read_bytes()).hexdigest()]
            else:
                rows[relative] = ['directory']
    return rows

before = manifest(original, work / 'original-files')
after = manifest(image, work / 'modified-files')
assert all(after.get(name) == value for name, value in before.items()), 'Existing file changed'
assert set(after) - set(before) == {name.lstrip('/') for name in added}, 'Unexpected new files'

run('python3', avb, 'add_hashtree_footer', '--image', image,
    '--partition_name', 'system_ext', '--partition_size', original.stat().st_size,
    '--hash_algorithm', 'sha1', '--algorithm', 'NONE', '--do_not_generate_fec',
    '--salt', '7b4db5e03c9f60f1328193792c871828c5ed437148d30a50d1bbd8689609178e',
    '--prop', 'com.android.build.system_ext.os_version:17',
    '--prop', 'com.android.build.system_ext.fingerprint:Redmi/lineage_merlinx/merlinx:17/CP2A.260605.016/826335cf90:userdebug/release-keys',
    '--prop', 'com.android.build.system_ext.security_patch:2026-11-01')
run('python3', avb, 'verify_image', '--image', image)
assert image.stat().st_size == original.stat().st_size
dest = base / 'system_ext-services.img'
shutil.copyfile(image, dest)
result = {'original_sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
          'modified_sha256': hashlib.sha256(dest.read_bytes()).hexdigest(),
          'partition_size': dest.stat().st_size,
          'original_entries_preserved': len(before), 'added': list(added),
          'policy': 'Existing Lineage userdebug init->su rule; su is permissive',
          'avb': 'Unsigned footer verified; existing vbmeta hashtree-disabled flag 1 required'}
(base / 'phone-init-validation.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
