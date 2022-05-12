//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Soul.sol";

contract Celestial is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct CelestialInfo {
        uint256 tokenId;
        uint256 celestialType;
    }
    // CONSTANTS
    uint256 public constant CELESTIAL_PRICE_AVAX = 1.5 ether; // 1.5 in production
    uint256 public constant CELESTIAL_PRICE_WHITELIST = 1.3 ether; // 1.3 in roduction
    //uint256 public constant WHITELIST_CELESTIAL = 1000;
    uint256 public constant CELESTIAL_PER_SOUL_MINT_LEVEL = 5000;
    //uint256 public constant MAXIMUM_MINTS_PER_WHITELIST_ADDRESS = 4;
    uint256 public constant NUM_GEN0_CELESTIAL = 10_000;
    uint256 public constant NUM_GEN1_CELESTIAL = 15_000;
    uint256 public constant ANGEL_TYPE = 1;
    uint256 public constant DEMON_TYPE = 2;
    uint256 public constant NEPHILIM_TYPE = 3;

    // SOUL mint price tracking
    uint256 public currentSOULMintCost = 20_000 * 1e18;

    // external contracts
    Soul public soul;
    address public celestialverseAddress;
    address public Stake;

    // metadata URI
    string public BASE_URI;

    // whitelist
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    // mint tracking
    uint256 public CelestialsMintedWithAVAX;
    uint256 public CelestialsMintedWithSOUL;
    uint256 public CelestialsMintedWhitelist;
    uint256 public CelestialsMinted = 0;

    uint256 public AngelsMinted;
    uint256 public DemonsMinted;
    uint256 public NephilimsMinted;
    // mint control timestamps
    //uint256 public startTimeWhitelist;
    uint256 public startTimeAVAX;
    uint256 public startTimeSOUL;

    // Celestial type definitions (ANGEL OR DEMON OR NEPHILIM)
    mapping(uint256 => uint256) public tokenTypes; // maps tokenId to its type

    // EVENTS

    event onCelestialCreated(uint256 tokenId);
    event onCelestialRevealed(uint256 tokenId, uint256 celestialType);

    constructor(string memory _BASE_URI, Soul _soul)
        ERC721("Celestial Verse Game", "CELESTIAL-VERSE-GAME")
    {
        CelestialsMinted = 0;
        BASE_URI = _BASE_URI;
        soul = _soul;
    }

    function setStake(address _stake) external onlyOwner{
        Stake = _stake;
    }

    function setStartTimeAVAX(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeAVAX = _startTime;
    }

    function setStartTimeSOUL(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeSOUL = _startTime;
    }

    // metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string calldata _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
    }

    function getType(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return tokenTypes[_tokenId];
    }

    //function mintingStartedWhitelist() public view returns (bool) {
    //    return startTimeWhitelist != 0 && block.timestamp >= startTimeWhitelist;
    //}

    function mintingStartedAVAX() public view returns (bool) {
        return startTimeAVAX != 0 && block.timestamp >= startTimeAVAX;
    }

    function mintingStartedSOUL() public view returns (bool) {
        return startTimeSOUL != 0 && block.timestamp >= startTimeSOUL;
    }

    /**
     * @dev allows owner to send ERC20s held by this contract to target
     */
    function forwardERC20s(
        IERC20 _token,
        uint256 _amount,
        address target
    ) external onlyOwner {
        _token.safeTransfer(target, _amount);
    }

    /**
     * @dev allows owner to withdraw AVAX
     */
    function withdrawAVAX(uint256 _amount) external payable onlyOwner {
        require(address(this).balance >= _amount, "not enough AVAX");
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{value: _amount}("");
        require(sent, "Failed to send AVAX");
    }

    /**
     * @dev merkle root for WL wallets
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function exist(uint256 tokenId) external view returns(bool) {
        return _exists(tokenId);
    }

    // MINTING

    function _createCelestial(
        address to,
        uint256 tokenId,
        uint256 celestialType
    ) internal {
        require(
            CelestialsMinted <= NUM_GEN0_CELESTIAL + NUM_GEN1_CELESTIAL,
            "cannot mint anymore celestials"
        );
        require(!_exists(tokenId), "this 'tokenId' is already tooken");
        require(
            tokenId >= 1 && tokenId <= NUM_GEN0_CELESTIAL,
            "'tokenId' must be in the range"
        );
        require(
            tokenTypes[tokenId] == 0,
            "that token's type has already been set"
        );
        require(
            celestialType == ANGEL_TYPE ||
                celestialType == DEMON_TYPE ||
                celestialType == NEPHILIM_TYPE,
            "invalid celestial type"
        );
        tokenTypes[tokenId] = celestialType;
        
        if (celestialType == 1) {
            AngelsMinted++;
        } else if(celestialType == 2){
            DemonsMinted++;
        }else{
            NephilimsMinted++;
        }

        _safeMint(to, tokenId);
        setApprovalForAll(Stake,true);
        emit onCelestialRevealed(tokenId, celestialType);
        emit onCelestialCreated(tokenId);
    }

    function _createCelestials(
        uint256 qty,
        uint256[] memory tokenIds,
        uint256[] memory celestialTypes,
        address to
    ) internal {
        for (uint256 i = 0; i < qty; i++) {
            CelestialsMinted += 1;
            _createCelestial(to, tokenIds[i], celestialTypes[i]);
        }
        // change parameters for percentages
        // NumberOfAnglesLeft / NumberOfTotalNFTLeft * 100 == Angle chance percentage
        // Server Side
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_baseURI(), "/", tokenId.toString(), ".json")
            );
    }

    /**
     * @dev GEN0 minting
     */
    function mintCelestialWhitelist(
        bytes32[] calldata _merkleProof,
        uint256 qty,
        uint256[] memory tokenIds,
        uint256[] memory celestialTypes
    ) external payable whenNotPaused {
        // check most basic requirements
        require(merkleRoot != 0, "missing root");
        //require(mintingStartedWhitelist(), "cannot mint right now");
        //require(!mintingStartedAVAX(), "whitelist minting is closed");

        // check if address belongs in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "this address does not have permission"
        );

        // check more advanced requirements
        require(
            qty == 1 || qty == 5 || qty == 10,
            "quantity must be 1 or 5 or 10"
        );
        require(
            qty == tokenIds.length && qty == celestialTypes.length,
            "Length of the amount of the nft must be equal to qty"
        );
        //require(
        //    (celestialsMintedWhitelist + qty) <= WHITELIST_CELESTIAL,
        //    "you can't mint that many right now"
        //);

        //require(
        //    (whitelistClaimed[_msgSender()] + qty) <=
        //        MAXIMUM_MINTS_PER_WHITELIST_ADDRESS,
        //    "this address can't mint any more whitelist celestials"
        //);

        // check price
        require(
            msg.value >= CELESTIAL_PRICE_WHITELIST * qty,
            "not enough AVAX"
        );

        CelestialsMintedWhitelist += qty;
        whitelistClaimed[_msgSender()] += qty;

        // mint celestials
        _createCelestials(qty, tokenIds, celestialTypes, _msgSender());
    }

    /**
     * @dev GEN0 minting
     */
    function mintCelestialWithAVAX(
        uint256 qty,
        uint256[] memory tokenIds,
        uint256[] memory celestialTypes
    ) external payable whenNotPaused {
        //require(mintingStartedAVAX(), "cannot mint right now");
        require(
            qty == 1 || qty == 5 || qty == 10,
            "quantity must be 1 or 5 or 10"
        );
        require(
            qty == tokenIds.length && qty == celestialTypes.length,
            "Length of the amount of the nft must be equal to qty"
        );
        require(
            (CelestialsMintedWithAVAX + qty) <=
                (NUM_GEN0_CELESTIAL - CelestialsMintedWhitelist),
            "you can't mint that many right now"
        );

        // calculate the transaction cost
        uint256 transactionCost = CELESTIAL_PRICE_AVAX * qty;
        require(msg.value >= transactionCost, "not enough AVAX");

        CelestialsMintedWithAVAX += qty;

        // mint Celestials
        _createCelestials(qty, tokenIds, celestialTypes, _msgSender());
    }

    /**
     * @dev GEN0 minting
     */
    function mintCelestialWithSoul(
        uint256 qty,
        uint256[] memory tokenIds,
        uint256[] memory celestialTypes
    ) external whenNotPaused {
        //require(mintingStartedSOUL(), "cannot mint right now");
        require(
            qty == 1 || qty == 5 || qty == 10,
            "quantity must be 1 or 5 or 10"
        );
        require(
            qty == tokenIds.length && qty == celestialTypes.length,
            "Length of the amount of the nft must be equal to qty"
        );
        require(
            (CelestialsMintedWithAVAX + qty) <=
                (NUM_GEN0_CELESTIAL - CelestialsMintedWhitelist),
            "you can't mint that many right now"
        );

        // calculate transaction costs
        uint256 transactionCostSOUL = currentSOULMintCost * qty;
        require(
            soul.balanceOf(_msgSender()) >= transactionCostSOUL,
            "not enough SOUL"
        );

        if (
            CelestialsMintedWithSOUL <= CELESTIAL_PER_SOUL_MINT_LEVEL &&
            CelestialsMintedWithSOUL + qty > CELESTIAL_PER_SOUL_MINT_LEVEL
        ) {
            currentSOULMintCost = currentSOULMintCost * 2;
        }

        CelestialsMintedWithSOUL += qty;
        // spend SOUL
        soul.burnFrom(_msgSender(), transactionCostSOUL);

        // mint celestial
        _createCelestials(qty, tokenIds, celestialTypes, _msgSender());
    }

    function GetTokenIdsOfOwner(address _owner) external view returns(uint256[] memory) {
        require(balanceOf(_owner) > 0, "there is no nft in your balance");
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner,i);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    function CelestialsOfOwner(address _owner)
        external
        view
        returns (CelestialInfo[] memory)
    {
        require(balanceOf(_owner) > 0, "there is no nft in your balance");
        uint256 balance = balanceOf(_owner);
        CelestialInfo[] memory res = new CelestialInfo[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            res[i] = CelestialInfo({
                tokenId: tokenId,
                celestialType: tokenTypes[tokenId]
            });
        }
        return res;
    }

    function bachedCelestialsOfOwner(address _owner, uint256 _page)
        public
        view
        returns (CelestialInfo[] memory)
    {
        require(_page >= 0, "there is no negetive page");
        require(balanceOf(_owner) > 0, "there is no nft in your balance");
        CelestialInfo[] memory celestials = new CelestialInfo[](5);
        uint256 StartPoint = _page * 5;
        uint256 EndPoint = StartPoint + 5;

        if (EndPoint > balanceOf(_owner)) {
            EndPoint = balanceOf(_owner);
        }
        for (uint256 i = StartPoint; i < EndPoint; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i); // tokenOfOwnerByIndex comes from IERC721Enumerable

            celestials[i] = CelestialInfo({
                tokenId: tokenId,
                celestialType: tokenTypes[tokenId]
            });
        }
        return celestials;
    }
}
