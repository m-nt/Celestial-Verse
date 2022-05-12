//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Soul is ERC20, Ownable, ERC20Burnable {
    mapping(address => bool) controllers;
    uint256 public MAX_SUPPLY = 400000000 * 10**decimals();
    uint256 public MAX_SUPPLY_PART_1 = 95000000 * 10**decimals();
    uint256 public MAX_SUPPLY_PART_2 = 200000000 * 10**decimals();
    // Stages
    uint256 public startTimePart1;
    uint256 public startTimePart2;

    constructor() ERC20("Soul", "SOUL") {}

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only a controller can mint");
        require((totalSupply() + amount) <= MAX_SUPPLY, "Max Supply Exceeded");
        // require(earningStartedPart1(), "Part 1 didn't started yet");
        // require(earningStartedPart2() || earningStartedPart1(),"");
        // require(
        //     earningStartedPart1() &&
        //         (totalSupply() + amount) <= MAX_SUPPLY_PART_1,
        //     "Max supply Part 1 Exceeded or "
        // );
        // require(
        //     !earningStartedPart2() &&
        //         (totalSupply() + amount) <= MAX_SUPPLY_PART_2,
        //     "Max supply Part 2 Exceeded"
        // );
        _mint(to, amount);
    }

    function setStartTimePart1(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimePart1 = _startTime;
    }

    function setStartTimePart2(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimePart2 = _startTime;
    }

    function earningStartedPart1() public view returns (bool) {
        return startTimePart1 != 0 && block.timestamp >= startTimePart1;
    }

    function earningStartedPart2() public view returns (bool) {
        return startTimePart2 != 0 && block.timestamp >= startTimePart2;
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    function addController(address ctrl) external onlyOwner {
        controllers[ctrl] = true;
    }

    function removeController(address ctrl) external onlyOwner {
        controllers[ctrl] = false;
    }
}
