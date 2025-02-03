import sys

def check_pass_fail(pass_fail_file, fetch_log_file):
    # PASS ve FAIL adreslerini oku
    with open(pass_fail_file, "r") as f:
        pass_adr, fail_adr = [int(x, 16) for x in f.readline().strip().split()]

    # Fetch edilen PC'leri oku
    with open(fetch_log_file, "r") as f:
        executed_pcs = {int(line.strip(), 16) for line in f.readlines()}

    if pass_adr in executed_pcs:
        print("✅ TEST PASSED")
        sys.exit(0)
    elif fail_adr in executed_pcs:
        print("❌ TEST FAILED")
        sys.exit(1)
    else:
        print("⚠️ ERROR: Neither PASS nor FAIL address was executed.")
        sys.exit(2)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python check_pass_fail.py <pass_fail_file> <fetch_log_file>")
        sys.exit(1)

    check_pass_fail(sys.argv[1], sys.argv[2])
