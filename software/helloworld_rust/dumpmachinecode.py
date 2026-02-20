#! /usr/bin/python3

with open("hello.bin", "rb") as fp:
    i = 0
    while True:
        data = fp.read(4)
        if data:
            a0 = data[0].to_bytes(1, "little").hex()
            try:
                a1 = data[1].to_bytes(1, "little").hex()
            except IndexError:
                a1 = int(0).to_bytes(1, "little").hex()
            try:
                a2 = data[2].to_bytes(1, "little").hex()
            except IndexError:
                a2 = int(0).to_bytes(1, "little").hex()
            try:
                a3 = data[3].to_bytes(1, "little").hex()
            except IndexError:
                a3 = int(0).to_bytes(1, "little").hex()
            print(f"{i} => x\"{a3}{a2}{a1}{a0}\",")
            i = i + 1
        else:
            print("Done")
            break
