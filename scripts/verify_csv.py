import csv
import math

# -------------------------------------------------
# Parameters (MUST match RTL)
# -------------------------------------------------
PHASE_BITS = 47

OUT_BITS  = 56
OUT_Q     = 54
OUT_SCALE = 1 << OUT_Q

# -------------------------------------------------
# Fixed-point helpers
# -------------------------------------------------
def sign_extend(v, bits):
    if v & (1 << (bits - 1)):
        v -= 1 << bits
    return v

def from_q(v, scale, bits):
    v = sign_extend(v, bits)
    return v / scale

# -------------------------------------------------
# CSV verification
# -------------------------------------------------
def verify_csv(fname):
    max_err = 0.0
    sum_err2 = 0.0
    n = 0
    err_num = 0

    with open(fname, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            phase = int(row["phase"], 16)
            y_q   = int(row["y_out"], 16)

            # reference
            x = (phase / (1 << PHASE_BITS)) * 2.0 * math.pi
            y_ref = math.sin(x)

            # RTL output
            y_fpga = from_q(y_q, OUT_SCALE, OUT_BITS)

            err = y_fpga - y_ref
            max_err = max(max_err, abs(err))
            sum_err2 += err * err
            if (err_num < 10): #& (abs(err) > 1e-3):
                y_q_ref = int(y_ref * OUT_SCALE)
                print(f"n={n:d}, y_fpga = {y_fpga:.6e}, y_ref = {y_ref:.6e}, phase={phase:x}, y_q={y_q:x}, y_q_ref={y_q_ref:x}")
                err_num += 1
            n += 1

    rms_err = math.sqrt(sum_err2 / n) if n > 0 else 0.0

    print(f"samples  : {n}")
    print(f"Max error: {max_err:.3e}")
    print(f"RMS error: {rms_err:.3e}")

# -------------------------------------------------
# Main
# -------------------------------------------------
if __name__ == "__main__":
    verify_csv("../tb/sincos_out.csv")

