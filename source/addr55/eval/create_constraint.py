import os

def load_parameter(param_name):
    f_params = open('eval/dut_params.v', 'r')
    while f_params:
        line = f_params.readline()
        if (param_name in line):
            str_spl = line.split('=')
            param = str_spl[-1]
            val = str_spl[1]
            f_val = val.replace(";\n",'')
            f_val2 = f_val.replace("\"",'')
            f_val3 = f_val2.replace(" ",'')
            break
    f_params.close()
    return (f_val3)

def write_constraint():
    f_constraint = open('eval/constraint.pdc', 'w')
    
    use_oreg    = load_parameter("USE_OREG")
    
    f_constraint.write("set CLK_PERIOD 10\n")
    f_constraint.write("\n")
    
    
#    f_constraint.write("\n")
    
    if (use_oreg == "on"):
        f_constraint.write("create_clock -name {clk_i} -period $CLK_PERIOD [get_ports clk_i]\n")
        f_constraint.write("\n")
    

    f_constraint.close()


write_constraint()
