from decimal import Decimal, getcontext

# high precision
getcontext().prec = 100

TWO = Decimal(2)

def compute_y(k):
    power = TWO ** (k - 60)         # 2^(k-60)
    val = (TWO ** 256) * (-power).exp()
    return int(val)

# example
print(hex(compute_y(62)))

for i in range(0, 64):
    print(f"if ((x & (1 << {i})) != 0)")
    print("{")
    print(f"(, result) = FullMathLibrary.mul512("
                f"result,"
                f" {hex(compute_y(i))}"
            f");")
    print("}")
    # print(f"y({i}) = {hex(compute_y(i))}")


