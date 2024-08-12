import base64
from Roblox import *

def build() -> str:
    with open('initialization/Input.lua', 'r', encoding='utf-8') as f:
        script = f.read()
        bytecode = Bytecode.Compile(script)[0]
    return bytecode
script_bytecode = build()
print(f"in > {len(script_bytecode)}")
encoded = base64.b64encode(script_bytecode).decode()
print(f"out > {len(encoded)}")
with open('initialization/Output.txt', 'w', encoding='utf-8') as f:
    f.write(encoded)