import numpy as np
from quaos.core.prime_Functions_Andrew import *
from quaos.core.prime_Functions_quditV2 import *
from quaos.core.pauli import *


def main():
    # Example usage
    dim = 3
    P = string_to_pauli("x1z0 x0z1 x0z0", dims=dim, phases=[0, 0, 0])
    P2 = string_to_pauli("x1z1 x1z0 x0z0", dims=dim, phases=[1, 0, 0])

    d = diagonalize(P)
    d.print()


if __name__ == "__main__":
    main()
