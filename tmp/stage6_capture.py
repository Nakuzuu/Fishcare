from pathlib import Path
import subprocess, sys, re, xml.etree.ElementTree as ET
adb = 'C:/Users/basti/AppData/Local/Android/sdk/platform-tools/adb.exe'
out = Path(__file__).resolve().parent.parent/'output/regression-stage6'
out.mkdir(parents=True, exist_ok=True)
label = sys.argv[1]
assert label.replace('-', '').isalnum()
def call(*args):
    return subprocess.run([adb, '-d', *args], capture_output=True, check=True).stdout
def foreground():
    windows = call('shell', 'dumpsys', 'window').decode(errors='replace')
    focus = next((line for line in windows.splitlines() if 'mCurrentFocus=' in line), '')
    match = re.search(r'\bu0 ([A-Za-z0-9_.]+)/', focus)
    package = match.group(1) if match else None
    if package not in ('id.ac.fishcare.m0', 'id.ac.fishcare.m0.tests', 'com.google.android.documentsui', 'com.android.documentsui'):
        raise SystemExit('Capture stopped: foreground is outside the authorized test apps.')
    return package
expected = foreground()
call('shell', 'uiautomator', 'dump', '/sdcard/fishcare-stage6-window.xml')
data = call('shell', 'cat', '/sdcard/fishcare-stage6-window.xml')
if foreground() != expected:
    raise SystemExit('Capture stopped: app changed while waiting for UI.')
picture = call('exec-out', 'screencap', '-p')
if foreground() != expected:
    raise SystemExit('Capture stopped: app changed during screenshot.')
(out/(label+'.png')).write_bytes(picture)
(out/(label+'.xml')).write_bytes(data)
for node in ET.fromstring(data).iter('node'):
    if node.get('text') or node.get('content-desc'):
        print(node.get('class'), repr(node.get('text')), repr(node.get('content-desc')), node.get('bounds'), node.get('resource-id'))
