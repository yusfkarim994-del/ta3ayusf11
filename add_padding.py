import os
import re

dir_path = r'c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\recovery_app\lib\screens'
targets = ['ListView', 'ListView.builder', 'GridView', 'GridView.builder', 'SingleChildScrollView', 'SliverList', 'SliverPadding']

for filename in os.listdir(dir_path):
    if not filename.endswith('.dart'): continue
    
    path = os.path.join(dir_path, filename)
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    modified = False
    for i, line in enumerate(lines):
        if any(t in line for t in targets) and ('child:' in line or 'return' in line or 'body:' in line or 'sliver:' in line):
            padding_found = False
            for j in range(i, min(i+10, len(lines))):
                if 'padding:' in lines[j] and 'EdgeInsets' in lines[j] and 'bottom:' not in lines[j]:
                    padding_found = True
                    lines[j] = re.sub(r'EdgeInsets\.all\(([^)]+)\)', 
                        lambda m: f'EdgeInsets.only(left: {m.group(1)}, right: {m.group(1)}, top: {m.group(1)}, bottom: 120)', lines[j])
                    
                    lines[j] = re.sub(r'EdgeInsets\.symmetric\s*\(\s*horizontal:\s*([^,]+)(?:,\s*vertical:\s*([^)]+))?\s*\)', 
                        lambda m: f'EdgeInsets.only(left: {m.group(1)}, right: {m.group(1)}, top: {m.group(2) if m.group(2) else "0"}, bottom: 120)', lines[j])
                    
                    lines[j] = re.sub(r'EdgeInsets\.symmetric\s*\(\s*vertical:\s*([^,)]+)\s*\)', 
                        lambda m: f'EdgeInsets.only(left: 0, right: 0, top: {m.group(1)}, bottom: 120)', lines[j])
                    
                    if 'EdgeInsets.only(' in lines[j] and 'bottom:' not in lines[j]:
                        lines[j] = lines[j].replace('EdgeInsets.only(', 'EdgeInsets.only(bottom: 120, ')
                        
                    modified = True
                    break
                
    if modified:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f'Padded structurally {filename}')
