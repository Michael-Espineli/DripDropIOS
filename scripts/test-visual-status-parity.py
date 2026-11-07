#!/usr/bin/env python3
"""Check the actual native/web status mapping and shared control palette."""
from pathlib import Path
import json,re,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
native=(root/'DripDropIOS/DripDrop/Resources/ViewModifiers/ButtonViewModifiers.swift').read_text()
web=root/'drip-drop-ecommerce/src/utils/statusPresentation.js'
cases=['Draft','Unscheduled','Rejected','Unspecified','Estimate','Estimate Pending','In Progress','Scheduled','Accepted','Finished','Paid','Comped','Customer Resolved','Completed','Complete','Invoiced','Sent','Open','Waiting for Parts','Blocked','Canceled','Cancelled','Expired','waiting_for_parts','  IN-PROGRESS  ','','unknown server state']
node="const fs=require('fs');(async()=>{const m=await import('data:text/javascript;base64,'+fs.readFileSync(process.argv[1]).toString('base64'));console.log(JSON.stringify(JSON.parse(process.argv[2]).map(m.jobStatusTone)))})()"
expected=json.loads(subprocess.check_output(['node','-e',node,str(web),json.dumps(cases)],text=True))
a=native.index('    static func jobStatusTone(');brace=native.index('{',a);depth=1;i=brace+1
while depth:
 if native[i]=='{':depth+=1
 elif native[i]=='}':depth-=1
 i+=1
function=native[a:i]
swift='enum WorkspaceTone: String { case blue, emerald, amber, rose, slate, cyan, violet\n'+function+'\n}\n'
swift+='\n'.join('print(WorkspaceTone.jobStatusTone('+json.dumps(c)+').rawValue)' for c in cases)
with tempfile.TemporaryDirectory(prefix='dripdrop-style-parity-') as temp:
 source=Path(temp)/'main.swift';source.write_text(swift);binary=Path(temp)/'check'
 subprocess.run(['swiftc','-module-cache-path','/private/tmp/dripdrop-visual-module-cache',str(source),'-o',str(binary)],check=True)
 actual=subprocess.check_output([str(binary)],text=True).splitlines()
assert actual==expected,[(s,a,b)for s,a,b in zip(cases,actual,expected)if a!=b]
css=(root/'drip-drop-ecommerce/src/index.css').read_text()
palettes=re.findall(r'case \.(\w+): return \(\((0x[\da-f]+), (0x[\da-f]+), (0x[\da-f]+)\), \((0x[\da-f]+), (0x[\da-f]+), (0x[\da-f]+)\)\)',native)
for tone,*colors in palettes:
 for j,role in enumerate(['bg','border','text']):
  matches=re.findall(r'--workspace-'+tone+'-'+role+r':\s*(#[\da-f]+);',css)
  assert len(matches)==2,(tone,role,matches)
  assert [int(c[1:],16)for c in matches]==[int(colors[j],16),int(colors[j+3],16)],(tone,role)
print(f'{len(cases)} cross-platform status cases and {len(palettes)*6} light/dark palette values passed')
