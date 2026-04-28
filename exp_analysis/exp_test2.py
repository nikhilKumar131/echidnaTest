from decimal import Decimal, getcontext

# high precision (important!)
getcontext().prec = 100

def exp_decay(x: int) -> int:
    TWO = Decimal(2)
    
    x_dec = Decimal(x)
    
    result = (TWO ** 256) * (-x_dec / (TWO ** 60)).exp()
    
    return int(result)


print(exp_decay(0))               # ≈ 2^256
print(exp_decay(1 << 60))        # ≈ 2^256 * e^-1
print(exp_decay(2 << 60))        # ≈ 2^256 * e^-2
print(exp_decay(1 << 63))        # ≈ 2^256 * e^-8