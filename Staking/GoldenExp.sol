// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

/**
 * @title GoldenExp is an ERC20-compliant token, but cannot be transferred and can only be minted through the GoldenExpMinter contract or redeemed for GOLDENG by destruction.
 * - The maximum amount that can be minted through the GoldenExpMinter contract is 55 million.
 * - GoldenExp can be used for community governance voting.
 */

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./Governable.sol";

interface IGoldenStakingRewards {
    function refreshReward(address user) external;
}

contract GoldenExp is ERC20Votes, Governable {

    mapping(address => bool) public GoldenExpMinter;
//    uint256 maxMinted = 370_000_000_000_000* 1e18;
    uint256 public totalMinted;

    constructor(

    ) ERC20Permit("GoldenExp") ERC20("GoldenExp", "GOLDENXP") {
        gov = msg.sender;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        revert("not authorized");
    }

    function setMinter(address[] calldata _contracts, bool[] calldata _bools) external onlyGov {
        for(uint256 i = 0;i<_contracts.length;i++) {
            GoldenExpMinter[_contracts[i]] = _bools[i];
        }
    }

    function mint(address user, uint256 amount) external returns(bool) {
        require(GoldenExpMinter[msg.sender] == true, "not authorized");
        uint256 reward = amount;
        IGoldenStakingRewards(msg.sender).refreshReward(user);
        _mint(user, reward);
        totalMinted += reward;

        return true;
    }

    function burn(address user, uint256 amount) external returns(bool) {
        require(GoldenExpMinter[msg.sender] == true, "not authorized");
        IGoldenStakingRewards(msg.sender).refreshReward(user);
        _burn(user, amount);
        return true;
    }

}

