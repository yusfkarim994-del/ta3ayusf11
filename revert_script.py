
import os
import re

dir_path = r'c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\recovery_app\lib\screens'

pattern1 = re.compile(r'padding:\s*const\s*EdgeInsets\.only\(\s*left:\s*([^,]+),\s*right:\s*\1,\s*top:\s*\1,\s*bottom:\s*120\s*\)')
pattern2 = re.compile(r'padding:\s*const\s*EdgeInsets\.only\(\s*left:\s*([^,]+),\s*right:\s*\1,\s*top:\s*([^,]+),\s*bottom:\s*120\s*\)')

for filename in os.listdir(dir_path):
    if not filename.endswith('.dart'): continue
    path = os.path.join(dir_path, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    orig = content
    content = pattern1.sub(lambda m: f'padding: const EdgeInsets.all({m.group(1)})', content)
    
    def repl_sym(m):
        horiz = m.group(1)
        vert = m.group(2)
        if horiz.strip() == '0' and vert.strip() != '0':
            return f'padding: const EdgeInsets.symmetric(vertical: {vert})'
        elif vert.strip() == '0' and horiz.strip() != '0':
            return f'padding: const EdgeInsets.symmetric(horizontal: {horiz})'
        else:
            return f'padding: const EdgeInsets.symmetric(horizontal: {horiz}, vertical: {vert})'
            
    content = pattern2.sub(repl_sym, content)
    
    if orig != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Reverted {filename}')

