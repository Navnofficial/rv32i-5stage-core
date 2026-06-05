words = open('../memfile.hex').read().split()
with open('current.bin', 'wb') as f:
    for w in words:
        if w.startswith('@'):
            continue
        val = int(w, 16)
        f.write(val.to_bytes(4, 'little'))
