
import sys
girdi_dosyasi = "./tcore/sw/a.hex"

cikti_dosyasi = "coremark_baremetal.mem"

def main():
    # Dosyanın içeriğini okunur.
    with open(girdi_dosyasi, "r") as f:
        lines = f.readlines()

    # Her satır 32 bitlik hex sayı olarak ayrıştırılır.
    hex_numbers = [line.strip().replace(" ", "") for line in lines]

    # Hex sayılar 4'erli olarak gruplanır.
    groups = [hex_numbers[i:i + 4] for i in range(0, len(hex_numbers), 4)]

    # Son grupta 128 bitlik satırı dolduramayacak kadar hex sayı varsa sıfır ile doldurulur.
    for group in groups:
        if len(group) < 4:
            group += ["00000000" for _ in range(4 - len(group))]

    # Gruplanmış hex sayılar 128 bitlik hex sayılar olarak birleştirilir.
    new_lines = ["".join(group[::-1]) for group in groups]

    # Yeni hex dosyası oluşturulur.
    with open(cikti_dosyasi, "w") as f:
        f.write("\n".join(new_lines))

if __name__ == "__main__":
    main()