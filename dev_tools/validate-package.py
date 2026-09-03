#!/usr/bin/env python3
import sys, zipfile
from pathlib import PurePosixPath

path = sys.argv[1] if len(sys.argv) > 1 else ''
if not path:
    raise SystemExit('usage: validate-package.py <zip>')
required = {
    'module.prop','action.sh','service.sh','bin/module-control','bin/webui-server-arm64',
    'tools/webui/launch.sh','tools/control/pixel-control.sh','tools/zram/page-cluster-control.sh','tools/zram/fstab.zram.100p',
    'webroot/index.html','webroot/embedded-host-bootstrap.js','webroot/mobile-input-viewport.js','webroot/app.js','webroot/app.css',
    'webroot/race-guard.js','webroot/race-guard.css','webroot/observability.js','webroot/observability.css',
    'webroot/v03.js','webroot/v04.js',
    'common/repo.json','webui.lock','webui-third-party/Supercharger_Pixel_9_Series.LICENSE',
}
runtime_names = {'config.env','manager-status.env','manager-status.txt','health.log','server.log','server.pid','server.ready.json','bootstrap.token','status.env','events.log'}
blocked_prefixes = ('.git/','.github/','dev_tools/','docs/','tests/','test/','server/','dist/','release/','release-notes/')
exec_paths = {'action.sh','service.sh','customize.sh','bin/module-control','bin/webui-server-arm64','tools/webui/launch.sh','tools/control/pixel-control.sh','tools/zram/page-cluster-control.sh'}
with zipfile.ZipFile(path) as z:
    infos = z.infolist(); names = {i.filename.rstrip('/') for i in infos}
    missing = sorted(required - names)
    if missing: raise SystemExit('FAIL package_required_missing=' + ','.join(missing))
    if 'system/vendor/etc/fstab.zram.100p' in names:
        raise SystemExit('FAIL package_generated_zram_fstab=system/vendor/etc/fstab.zram.100p')
    for info in infos:
        name = info.filename.rstrip('/')
        if not name: continue
        if name.startswith(blocked_prefixes): raise SystemExit(f'FAIL package_blocked_path={name}')
        if PurePosixPath(name).name in runtime_names and not name.startswith('webui-third-party/'):
            raise SystemExit(f'FAIL package_runtime_state={name}')
        if name.startswith('system/vendor/etc/thermal_info_config'):
            raise SystemExit(f'FAIL package_active_thermal_overlay={name}')
        mode = (info.external_attr >> 16) & 0o777
        if name in exec_paths and mode and not (mode & 0o111):
            raise SystemExit(f'FAIL package_exec_mode={name}:{oct(mode)}')
print('RESULT: PIXEL_THERMAL_PACKAGE_HYGIENE_PASS')
