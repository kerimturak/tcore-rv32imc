#!/usr/bin/env python3
"""
get_static_hex.py
-----------------

Bu betik, bir binary dosyayı okuyup, her bloktaki (örneğin 16 baytlık) veriyi ters çevirerek hex formatında çıktı üretir.

Kullanım:
    python3 get_static_hex.py -b <block_bayt> <binary_dosya>
    
Örnek:
    python3 get_static_hex.py -b 16 test.elf.bin > test.elf.hex
"""

import sys
import argparse

def main():
    parser = argparse.ArgumentParser(
        description="Binary dosyayı blok bazında ters çevirip hex çıktısı üretir."
    )
    parser.add_argument("-b", "--block-size", type=int, required=True,
                        help="Blok boyutu (bayt cinsinden)")
    parser.add_argument("binfile", help="Girdi binary dosyası")
    args = parser.parse_args()

    bs = args.block_size
    try:
        with open(args.binfile, "rb") as f:
            data = f.read()
    except Exception as e:
        sys.exit(f"Dosya açılamadı: {e}")

    # Blok blok işle: Her bloktaki tüm baytları ters çevir.
    out_lines = []
    for i in range(0, len(data), bs):
        block = data[i:i+bs]
        reversed_block = block[::-1]
        # Ters çevrilmiş bloğu hex string olarak üret
        hex_str = reversed_block.hex()
        out_lines.append(hex_str)

    # Her bloğu ayrı satıra yazdırabilirsiniz veya tüm bloğu ardışık olarak da yazabilirsiniz.
    # Aşağıda her bloğu ayrı satıra yazdıran örnek verilmiştir.
    print("\n".join(out_lines))

if __name__ == "__main__":
    main()
