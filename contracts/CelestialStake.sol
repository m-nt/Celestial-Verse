//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Celestial.sol";
import "./Soul.sol";

contract CelestialStake is Ownable, Pausable, IERC721Receiver {
    uint256 public totalStaked;
    uint256 public totalAngleStaked;
    uint256 public totalDemonStaked;
    uint256 public totalNephilimStaked;
    bool public EnableEarning;

    // struct to store nft holder information
    struct StakedCelestail {
        uint256 tokenId;
        uint256 timestamp;
        uint256 cooldown;
        address owner;
    }
    struct CelestialInfo {
        uint256 tokenId;
        uint256 celestialType;
    }
    // staking Events
    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnStaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    // Point NFT contract and token
    Celestial celestialNFT;
    Soul soul;

    // Reference tokenId to StakedCelestial
    mapping(uint256 => StakedCelestail) public vault;

    // Costructor

    constructor(Celestial _celestialNFT, Soul _soul) {
        celestialNFT = _celestialNFT;
        soul = _soul;
        EnableEarning = true;
    }
    function setEnableEarning(bool earning) external onlyOwner {

        EnableEarning = earning;
    }

    // Stake
    function stake(uint256 tokenId) external whenNotPaused {
        require(
            celestialNFT.ownerOf(tokenId) == msg.sender,
            "You don't own this token"
        );
        require(vault[tokenId].tokenId == 0, "this token already staked");
        // Transfer the nft to this contract
        celestialNFT.transferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(msg.sender, tokenId, block.timestamp);

        uint256 celestialType = celestialNFT.getType(tokenId);
        if (celestialType == 1) {
            totalAngleStaked++;
        } else if (celestialType == 2) {
            totalDemonStaked++;
        } else {
            totalNephilimStaked++;
        }

        // Add the nft to the vault
        vault[tokenId] = StakedCelestail({
            owner: msg.sender,
            tokenId: tokenId,
            timestamp: uint256(block.timestamp),
            cooldown: uint256(block.timestamp)
        });
    }

    function startEarning(uint256 tokenId) external whenNotPaused {
        StakedCelestail memory staked = vault[tokenId];
        require(staked.owner == msg.sender, "You are not the owner");
        require(block.timestamp > staked.cooldown, "You are in cooldown");
        require(EnableEarning,"Maintenance");
        vault[tokenId] = StakedCelestail({
            owner: msg.sender,
            tokenId: tokenId,
            timestamp: uint256(block.timestamp),
            cooldown: uint256(block.timestamp + 1 days)
        });
    }

    // Unstake and claim internal functions
    function _unstake(address owner, uint256 tokenId) internal {
        StakedCelestail memory staked = vault[tokenId];
        require(staked.owner == msg.sender, "You are not the owner");
        uint256 celestialType = celestialNFT.getType(tokenId);
        uint256 unstakeCost;
        if (celestialType == 1) {
            unstakeCost = 1000 ether;
            require(soul.balanceOf(owner) >= unstakeCost, "You don't have enough Soul");
            soul.burnFrom(owner,unstakeCost);
        }

        if (celestialType == 1) {
            totalAngleStaked--;
        } else if (celestialType == 2) {
            totalDemonStaked--;
        } else {
            totalNephilimStaked--;
        }

        delete vault[tokenId];
        emit NFTUnStaked(owner, tokenId, block.timestamp);
        celestialNFT.transferFrom(address(this), owner, tokenId);
    }

    function _claim(
        address owner,
        uint256 tokenId,
        bool _unstaked
    ) internal {
        uint256 earned = 0;
        StakedCelestail memory staked = vault[tokenId];
        require(staked.owner == owner, "You are not the owner");
        uint256 stakedAt = staked.timestamp;
        uint256 cooldown = staked.cooldown;
        uint256 celestialType = celestialNFT.getType(tokenId);
        uint256 earnCost;
        if (celestialType == 1) {
            earnCost = 800;
        } else if(celestialType == 2) {
            earnCost = 1250;
        }else{
            earnCost = 2100;
        }
        // Calculate the token that earned by this nft
        if (
            block.timestamp > stakedAt && block.timestamp < cooldown - 1 minutes
        ) {
            earned = (earnCost*10**18 * (block.timestamp - stakedAt)) / 1 days; // 10**18 = ether
        }
        if (earned > 0) {
            //earned = earned / 800;
            soul.mint(owner, earned);
            vault[tokenId] = StakedCelestail({
                owner: owner,
                tokenId: tokenId,
                timestamp: uint256(block.timestamp),
                cooldown: cooldown
            });
        }
        if (_unstaked) {
            _unstake(owner, tokenId);
        }
        emit Claimed(owner, earned);
    }

    //Unstake and claim public functions

    function claim(uint256 tokenId) external {
        _claim(msg.sender, tokenId, false);
    }

    function claimForAddress(address account, uint256 tokenId) external {
        _claim(account, tokenId, false);
    }

    function unstake(uint256 tokenId) external {
        _claim(msg.sender, tokenId, true);
    }

    // Staking Information
    function getCooldown(uint256 tokenId) external view returns (uint256) {
        StakedCelestail memory staked = vault[tokenId];
        return staked.cooldown;
    }

    function earningInfo(uint256[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 earned = 0;
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            uint256 celestialType = celestialNFT.getType(tokenId);
            uint256 earnCost;
            if (celestialType == 1) {
                earnCost = 800;
            } else if(celestialType == 2) {
                earnCost = 1250;
            }else{
                earnCost = 2100;
            }
            StakedCelestail memory staked = vault[tokenId];
            uint256 stakedAt = staked.timestamp;
            uint256 cooldown = staked.cooldown;
            // this is the Reward Price Calculation
            if (
                block.timestamp > stakedAt &&
                block.timestamp < cooldown - 1 minutes
            ) {
                earned += (earnCost *10**18 * (block.timestamp - stakedAt)) / 1 days;
            }
        }
        return earned;
    }

    function getUnstakedCelestials() external view returns (uint256) {
        uint256 supply = celestialNFT.totalSupply();
        return supply - totalStaked;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = celestialNFT.totalSupply();
        for (uint256 i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    // Total Staked per Owener with tokenIds
    function tokenOfOwner(address account)
        public
        view
        returns (CelestialInfo[] memory ownerTokens)
    {

        uint256[] memory temp = celestialNFT.GetTokenIdsOfOwner(address(this));
        uint256 index = 0;
        uint256[] memory Ids = new uint256[](temp.length);
        for (uint256 i = 0; i < temp.length; i++) {
            if(vault[temp[i]].owner == account){
                Ids[index] = i;
                index++;
            }
        }
        CelestialInfo[] memory info = new CelestialInfo[](index);
        for (uint256 i = 0; i < index; i++) {
                uint256 tokenId = temp[Ids[i]];
                uint256 celestialType = celestialNFT.getType(tokenId);
                info[i] = CelestialInfo({
                    tokenId:tokenId,
                    celestialType:celestialType
                });
        }

        // uint256 supply = celestialNFT.totalSupply();
        // uint256[] memory tmp = new uint256[](supply);
        // uint256 index = 0;
        // for (uint256 i = 0; i <= supply; i++) {
        //     if (vault[i].owner == account) {
        //         tmp[index] = vault[i].tokenId;
        //         index++;
        //     }
        // }
        // CelestialInfo[] memory info = new CelestialInfo[](index);
        // for (uint256 i = 0; i < index; i++) {
        //     uint256 tokenId = tmp[i]; // tokenOfOwnerByIndex comes from IERC721Enumerable
        //     uint256 celestialType = celestialNFT.getType(tokenId);
        //     info[i] = CelestialInfo({
        //         tokenId: tokenId,
        //         celestialType: celestialType
        //     });
        // }
        return info;
    }

    function tokenOfOwnerBached(address _owner, uint256 _page) 
        public 
        view 
        returns(CelestialInfo[] memory) 
    {
        uint256[] memory temp = celestialNFT.GetTokenIdsOfOwner(address(this));
        uint256 index = 0;
        uint256[] memory Ids = new uint256[](temp.length);
        for (uint256 i = 0; i < temp.length; i++) {
            if(vault[temp[i]].owner == _owner){
                Ids[index] = i;
                index++;
            }
        }
        CelestialInfo[] memory info = new CelestialInfo[](index);
        for (uint256 i = 0; i < index; i++) {
                uint256 tokenId = temp[Ids[i]];
                uint256 celestialType = celestialNFT.getType(tokenId);
                info[i] = CelestialInfo({
                    tokenId:tokenId,
                    celestialType:celestialType
                });
        }
        CelestialInfo[] memory celestials = new CelestialInfo[](5);
        uint256 StartPoint = _page * 5;
        uint256 EndPoint = StartPoint + 5;

        if (EndPoint > info.length) {
            EndPoint = info.length;
        }
        for (uint256 i = StartPoint; i < EndPoint; i++) {
            uint256 tokenId = info[i].tokenId; // tokenOfOwnerByIndex comes from IERC721Enumerable
            uint256 celestialType = info[i].celestialType;
            celestials[i] = CelestialInfo({
                tokenId: tokenId,
                celestialType: celestialType
            });
        }
        return celestials;

    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directoies");
        return IERC721Receiver.onERC721Received.selector;
    }
}
