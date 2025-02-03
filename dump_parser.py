import sys
import re

def extract_addresses(dump_file):
    fail_address = None
    pass_address = None

    with open(dump_file, "r") as f:
        for line in f:
            if "<fail>:" in line:
                fail_address = int(line.split()[0], 16)
            elif "<pass>:" in line:
                pass_address = int(line.split()[0], 16)

    if fail_address is None or pass_address is None:
        print("Error: Could not find pass or fail addresses in dump file.")
        sys.exit(1)

    print(f"Extracted PASS: {hex(pass_address)}, FAIL: {hex(fail_address)}")
    return pass_address, fail_address

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python dump_parser.py <dump_file>")
        sys.exit(1)

    dump_file = sys.argv[1]
    pass_adr, fail_adr = extract_addresses(dump_file)

    with open("pass_fail_addr.txt", "w") as f:
        f.write(f"{hex(pass_adr)} {hex(fail_adr)}\n")
