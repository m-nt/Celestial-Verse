import random
from typing import List
import numpy as np
from web3 import Web3

MAX_CELESTIAL = 16
CELESTIAL_TYPES = {1: 10, 2: 15, 3: 16}
WHITE_LIST = ["0xcF706944e280f965A628fF85fe79012209709544"]
LEAF_NODES = {}


def test():
    arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
    n = 5
    page = 1
    rang = page * n
    res = []
    ln = rang + n
    if ln > len(arr):
        ln = len(arr)
    for i in range(rang, ln):
        res.append(arr[i])
    print(res)


def get_random_nft_tokenIds(qty: int, exclude: list) -> tuple:
    tokenListAll = np.arange(1, MAX_CELESTIAL)
    excluded = np.array(exclude)
    tokenList = np.setdiff1d(tokenListAll, excluded)
    tokenIds = random.choices(tokenList, k=qty)
    types = return_types_from_tokenIds(tokenIds)
    return (tokenIds, types)


def return_types_from_tokenIds(tokenIds: list) -> list:
    types = []
    for i in tokenIds:
        if i <= CELESTIAL_TYPES[1]:
            types.append(1)
        elif i <= CELESTIAL_TYPES[2]:
            types.append(2)
        else:
            types.append(3)
    return types
