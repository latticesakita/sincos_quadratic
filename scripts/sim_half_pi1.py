import math
import random
import argparse

# --- (parameters & helpers are identical) ---

# -------------------------------------------------
# Parameters
# -------------------------------------------------
GRID = 1024
ADDR_BITS = 10
FRAC_BITS = 35          # phase[45:0] -> addr+frac

PHASE_BITS = 47

LUT_BITS = 36
LUT_Q = 34
LUT_SCALE = 1 << LUT_Q
LUT_MASK = (1 << LUT_BITS) - 1

OUT_BITS = 56
OUT_Q = 52
OUT_SCALE = 1 << OUT_Q
OUT_MASK = (1 << OUT_BITS) - 1

# -------------------------------------------------
# Fixed-point helpers
# -------------------------------------------------
def to_q(x, scale, bits):
    v = int(round(x * scale))
    if v < 0:
        v += 1 << bits
    return v & ((1 << bits) - 1)

def from_q(v, scale, bits):
    if v & (1 << (bits - 1)):
        v -= 1 << bits
    return v / scale

def sign_extend(v, bits):
    if v & (1 << (bits - 1)):
        v -= 1 << bits
    return v

def write_hex(fname, data, bits):
    w = (bits + 3) // 4
    with open(fname, "w") as f:
        for v in data:
            f.write(f"{v:0{w}X}\n")
# -------------------------------------------------
# Build LUTs (float only here)
# -------------------------------------------------
dx = (math.pi / 2) / GRID

sin_i   = [math.sin(i * dx) for i in range(GRID + 1)]
sin_mid = [math.sin((i + 0.5) * dx) for i in range(GRID)]

y0_lut = [
    to_q(sin_i[i], LUT_SCALE, LUT_BITS)
    for i in range(GRID)
]

dy_lut = [
    to_q(sin_i[i+1] - sin_i[i], LUT_SCALE, LUT_BITS)
    for i in range(GRID)
]

ddy_lut = [
    to_q(4 * (sin_i[i+1] - 2*sin_mid[i] + sin_i[i]),
         LUT_SCALE, LUT_BITS)
    for i in range(GRID)
]

# -------------------------------------------------
# FPGA-like sin (quadratic mid-point, FIXED ONLY)
# -------------------------------------------------
def sin_fpga_quad_mid_fixed(phase):
    quad = (phase >> (PHASE_BITS - 2)) & 0x3
    neg = quad >> 1

    p = phase & ((1 << (PHASE_BITS - 2)) - 1)

    addr = p >> FRAC_BITS
    frac = p & ((1 << FRAC_BITS) - 1)

    if quad & 1:
        addr = GRID - 1 - addr
        frac = (1 << FRAC_BITS) - frac

    y0  = sign_extend(y0_lut[addr], LUT_BITS)
    dy  = sign_extend(dy_lut[addr], LUT_BITS)
    ddy = sign_extend(ddy_lut[addr], LUT_BITS)

    # ---------------------------
    # fixed-point interpolation
    # ---------------------------
    t = frac                                # Q0.36
    t_m1 = frac - (1 << FRAC_BITS)          # Q1.36
    # if quad & 1:
    #     print(f"phase={phase:x} quad={quad:x} addr={addr:x} frac={frac:09x} t_m1={t_m1:09x}")
        

    # term1: dy * t
    term1 = dy * t                          # Q4.68

    # ---- optimized term2 ----
    tt = (t * t_m1) >> FRAC_BITS            # Q1.36  ← 36bit有効部
    term2 = ddy * tt                        # Q5.68

    # ---------------------------
    # accumulate (to Q4.52)
    # ---------------------------
    y = (y0 << (OUT_Q - LUT_Q)) & OUT_MASK
    y += (term1 >> FRAC_BITS) << (OUT_Q - LUT_Q)
    y += (term2 >> (FRAC_BITS + 1)) << (OUT_Q - LUT_Q)

    if neg:
        y = (-y) & OUT_MASK

    return y

# -------------------------------------------------
# Test
# -------------------------------------------------
def test(n=200_000):
    max_err = 0.0
    sum_err2 = 0.0

    for _ in range(n):
        phase = random.getrandbits(PHASE_BITS)

        x = (phase / (1 << PHASE_BITS)) * 2 * math.pi
        y_ref = math.sin(x)

        y_q = sin_fpga_quad_mid_fixed(phase)
        y_fpga = from_q(y_q, OUT_SCALE, OUT_BITS)

        err = abs(y_fpga - y_ref)
        max_err = max(max_err, err)
        sum_err2 += err * err

    print(f"Max error : {max_err:.3e}")
    print(f"RMS error : {math.sqrt(sum_err2/n):.3e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--hex", action="store_true",
                        help="output LUT hex files")
    args = parser.parse_args()

    if args.hex:
        write_hex("lut_y0.hex",  y0_lut,  LUT_BITS)
        write_hex("lut_dy.hex",  dy_lut,  LUT_BITS)
        write_hex("lut_ddy.hex", ddy_lut, LUT_BITS)

    test()
