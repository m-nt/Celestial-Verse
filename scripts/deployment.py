from brownie import accounts, network, Celestial, Soul, CelestialStake
from scripts.helpful_scripts import get_account, OPENSEA_FORMAT
from scripts.tools import get_random_nft_tokenIds
import sys
from web3 import Web3

BASE_URL = "https://celestialverse.mypinata.cloud/ipfs/QmV3PH99teT4Bc4DUmFr99dAuQyPtZKjhMcspareekEBAQ/"
EXCLUDED_TOKENIDS = [2, 15, 13, 12, 14]
TOKEN_ID = 5549
TYPE = 1
MERKLE_ROOT = "6b50d7218ac3a581f1fc43724263133a8c680898623932ed77371835e003b764"

# merkleProof = [
#         Web3.toBytes(hexstr="0x898db34234499576bfdb62d701de2cf2bb63b2d4d8d2c618387df8d85546c302"),
#         Web3.toBytes(hexstr="0x9cc93cab42201f4d89860a8100518db2646e21a10b94d8bbcbc6476ec46b7e51"),
#         Web3.toBytes(hexstr="0xafe1d9ec8fcda72fc5b7ee2af40f4e2d9a7be36b7904b21b3d6b59d1be2fafd5")
#     ]
merkleProof = [
    "0x898db34234499576bfdb62d701de2cf2bb63b2d4d8d2c618387df8d85546c302",
    "0x9cc93cab42201f4d89860a8100518db2646e21a10b94d8bbcbc6476ec46b7e51",
    "0x1c8937f83bc53cd8dcc95a2f24e3498feb4cbd1a44d9e5b6508b41e54b70d650",
    "0xafe1d9ec8fcda72fc5b7ee2af40f4e2d9a7be36b7904b21b3d6b59d1be2fafd5",
]
# Deploying all the contracts


def test():
    print(
        Web3.toBytes(
            hexstr="0x898db34234499576bfdb62d701de2cf2bb63b2d4d8d2c618387df8d85546c302"
        )
    )


def setBaseURI(name):
    account = get_account(id=name)
    nft = Celestial[-1]
    nft_tx = nft.setBaseURI(BASE_URL, {"from": account})
    print(nft_tx)


def deploy(account):
    account = get_account(id=account)
    soul = deploy_soul(account)
    nft = deploy_nft(account)
    stake = deploy_stake(account)
    addcontroller(account)
    setApproval(account)
    setMerkleRoot(account)


def deploy_nft(account):
    # account = get_account(id="mamad")
    soul = Soul[-1]
    celestial = Celestial.deploy(BASE_URL, soul, {"from": account})
    print(f"nft deployed at {celestial.address}")
    return celestial


def deploy_soul(account):
    # account = get_account(id="mamad")
    _soul = Soul.deploy({"from": account})
    print(f"Soul token deployed at: {_soul.address}")
    return _soul


def deploy_stake(account):
    # account = get_account(id="mamad")
    nft = Celestial[-1]
    soul = Soul[-1]
    _stake = CelestialStake.deploy(nft, soul, {"from": account})
    print(f"Soul token deployed at: {_stake.address}")
    return _stake


def latestContracts():
    nft = Celestial[-1].address if len(Celestial) > 0 else None
    soul = Soul[-1].address if len(Soul) > 0 else None
    stake = CelestialStake[-1].address if len(CelestialStake) > 0 else None
    print(f"nft: {nft}\nsoul: {soul}\nstake: {stake}")


# Public functions for nft:
def mintCelestialWithAVAX(name):
    account = get_account(id=name)
    celestial = Celestial[-1]
    count = 1
    # tokenId, celestialType = get_random_nft_tokenIds(count, EXCLUDED_TOKENIDS)
    tokenId = [TOKEN_ID]
    celestialType = [TYPE]
    celestial_tx = celestial.mintCelestialWithAVAX(
        count,
        tokenId,
        celestialType,
        {"from": account, "value": Web3.toWei(1.5 * count, "ether")},
    )
    celestial_tx.wait(1)
    for i in tokenId:
        print(f"checkout the nft at: {OPENSEA_FORMAT.format(celestial.address,i)}")


def mintCelestialWithSoul(name):
    account = get_account(id=name)
    celestial = Celestial[-1]
    # tokenId, celestialType = get_random_nft_tokenIds(1, EXCLUDED_TOKENIDS)
    tokenId = [TOKEN_ID]
    celestialType = [TYPE]
    celestial_tx = celestial.mintCelestialWithSoul(
        1, tokenId, celestialType, {"from": account}
    )
    celestial_tx.wait(1)
    for i in tokenId:
        print(f"checkout the nft at: {OPENSEA_FORMAT.format(celestial.address,i)}")


# Its not working yet
def mintWhitelist():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    # tokenId, celestialType = get_random_nft_tokenIds(1, EXCLUDED_TOKENIDS)
    tokenId = [TOKEN_ID]
    celestialType = [TYPE]
    celestial_tx = celestial.mintCelestialWhitelist(
        merkleProof,
        1,
        tokenId,
        celestialType,
        {"from": account, "value": Web3.toWei(1.3 * len(tokenId), "ether")},
    )
    celestial_tx.wait(1)
    for i in tokenId:
        print(f"checkout the nft at: {OPENSEA_FORMAT.format(celestial.address,i)}")


def getTokenURI():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    tokenId = TOKEN_ID
    celestial_tx = celestial.tokenURI(
        tokenId, {"from": account}
    )  # Frist arg is the tokenId
    print(celestial_tx)


def getTotalNft():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    celestial_tx = celestial.totalSupply({"from": account})
    print(f"total supply of nft: {celestial_tx}")


def setApprove():
    account = get_account(id="mamad")
    # account1 = get_account(id="mamad1")
    celestial = Celestial[-1]
    stake = CelestialStake[-1]
    celestial_tx = celestial.approve(stake.address, 3, {"from": account})
    celestial_tx.wait(1)
    print(f"address:{account} has been approved!")


def setApproval(account):
    # account = get_account(id="mamad1")
    celestial = Celestial[-1]
    stake = CelestialStake[-1]
    celestial_tx = celestial.setStake(stake.address, {"from": account})
    celestial_tx.wait(1)
    print(f"address:{stake.address} has been added to nft!")


def setApprovalStake():
    account = get_account(id="cvboss")
    celestial = Celestial[-1]
    stake = CelestialStake[-1]
    celestial_tx = celestial.setStake(stake.address, {"from": account})
    celestial_tx.wait(1)
    print(f"address:{stake.address} has been added to nft!")


def isApproved():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    stake = CelestialStake[-1]
    celestial_tx = celestial.isApprovedForAll(account, stake.address, {"from": account})
    print(celestial_tx)


# isApprovedForAll
# Owner only functions for nft:

# Its not working yet
def setMerkleRoot():
    account = get_account(id="mamad")
    celestial = Celestial[-1]
    celestial_tx = celestial.setMerkleRoot("bytes32 _merkleRoot", {"from": account})
    celestial_tx.wait(1)
    print(f"Merkle root has been set!")


# Public functions for stake
def stake():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    tokenId = TOKEN_ID
    stake_tx = stake.stake(tokenId, {"from": account})
    stake_tx.wait(1)
    print(f"TokenId: {tokenId} has been staked!")


def claimReward():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    tokenId = TOKEN_ID
    stake_tx = stake.claim(tokenId, {"from": account})
    stake_tx.wait(1)
    print(f"claimig reward")


def unstake():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    tokenId = TOKEN_ID
    stake_tx = stake.unstake(tokenId, {"from": account})
    stake_tx.wait(1)
    print(f"unstaked the token")


def earnInfo():
    account = get_account(id="mamad1")
    tokenId = [TOKEN_ID]
    stake = CelestialStake[-1]
    stake_tx = stake.earningInfo(tokenId, {"from": account})
    print(stake_tx)


def startearning():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    tokenId = TOKEN_ID
    stake_tx = stake.startEarning(tokenId, {"from": account})


def claim():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    tokenId = TOKEN_ID
    stake_tx = stake.claim(tokenId, {"from": account})


def addcontroller(account):
    # account = get_account(id="mamad")
    soul = Soul[-1]
    stake = CelestialStake[-1]
    soul_tx = soul.addController(stake.address, {"from": account})
    soul_tx.wait(1)
    soul_tx2 = soul.addController(account, {"from": account})
    soul_tx.wait(1)
    print("controller added")


def getCelestialsOfOwner():
    # CelestialsOfOwner
    account = get_account(id="acc2")
    celestial = Celestial[-1]
    celestial_tx = celestial.CelestialsOfOwner(account, {"from": account})
    print(celestial_tx)


def getCelestialsOfOwnerbached():
    # CelestialsOfOwner
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    celestial_tx = celestial.bachedCelestialsOfOwner(account, 0, {"from": account})
    print(celestial_tx)


def tokenOfOwnerByIdx():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    celestial_tx = celestial.tokenOfOwnerByIndex(account, 5, {"from": account})
    print(celestial_tx)


def balanceOfOwner():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    celestial_tx = celestial.balanceOf(account, {"from": account})
    print(celestial_tx)


# bachedCelestialsOfOwner
# Owner only functions for stake:

# Public functions for soul
def giveSoul():
    account = get_account(id="cvboss")
    # account1 = get_account(id="mamad1")
    lp_manager = get_account(id="LPmanager")
    soul = Soul[-1]
    s_tx = soul.mint(lp_manager, Web3.toWei(5000000, "ether"), {"from": account})


def addController():
    account = get_account(id="cvboss")
    soul = Soul[-1]
    s_tx = soul.addController(account, {"from": account})


def GetStakedTokenIds():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    stake_tx = stake.tokenOfOwner(account, {"from": account})
    print(stake_tx)


def GetStakedTokenIdsPage():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    stake_tx = stake.tokenOfOwnerBached(account, 0, {"from": account})
    print(stake_tx)


def GetTotalType():
    account = get_account(id="mamad1")
    celestial = Celestial[-1]
    celestial_tx = celestial.DemonsMinted({"from": account})
    print(celestial_tx)


def Withdraw():
    account = get_account(id="cvboss")
    celestial = Celestial[-1]
    celestial_tx = celestial.withdrawAVAX(Web3.toWei(3, "ether"), {"from": account})
    celestial_tx.wait(1)
    print(celestial_tx)


# setEnableEarning
def setEnableEarning():
    account = get_account(id="mamad")
    stake = CelestialStake[-1]
    stake_tx = stake.setEnableEarning(True, {"from": account})
    print(stake_tx)


def GetCooldown():
    account = get_account(id="mamad1")
    stake = CelestialStake[-1]
    stake_tx = stake.getCooldown(150, {"from": account})
    print(stake_tx)


def SoulBalanceOf():
    account = get_account(id="mamad1")
    soul = Soul[-1]
    soul_tx = soul.totalSupply({"from": account})
    print(soul_tx)


def setMerkleRoot(account):
    # account = get_account(id="mamad")
    cel = Celestial[-1]
    cel_tx = cel.setMerkleRoot(Web3.toBytes(hexstr=MERKLE_ROOT), {"from": account})
    print(cel_tx)


def setMerkleRootManual(name):
    account = get_account(id=name)
    cel = Celestial[-1]
    cel_tx = cel.setMerkleRoot(Web3.toBytes(hexstr=MERKLE_ROOT), {"from": account})
    print(cel_tx)


def ConvertMerkleToByte():
    return "".join(MERKLE_ROOT).decode("utf-8")


# Owner only functions for soul:
