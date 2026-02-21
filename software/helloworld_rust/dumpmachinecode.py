#! /usr/bin/python3

DEPTH = 1024
WIDTH = 32


def words_from_bin(path):
    words = []
    with open(path, "rb") as fp:
        while True:
            data = fp.read(4)
            if not data:
                break
            data = data.ljust(4, b"\x00")
            words.append(data[::-1].hex().upper())
    return words


def emit_mif(words):
    print(f"WIDTH={WIDTH};")
    print(f"DEPTH={DEPTH};")
    print("")
    print("ADDRESS_RADIX=UNS;")
    print("DATA_RADIX=HEX;")
    print("")
    print("CONTENT BEGIN")
    for i in range(DEPTH):
        val = words[i] if i < len(words) else "00000000"
        print(f"  {i} : {val};")
    print("END;")


if __name__ == "__main__":
    emit_mif(words_from_bin("hello.bin"))
