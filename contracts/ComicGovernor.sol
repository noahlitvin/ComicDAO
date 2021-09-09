// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
// Consider implementing -> import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// That does the thing with snapshots I haven't quite grokked yet.

contract ComicGovernor is Governor, GovernorCountingSimple {

    IERC20 private _coin;
    
    constructor(IERC20 _voteCoin)
        Governor("ComicGovernor")
    {
        _coin = _voteCoin;
    }
    
    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 100; //Reduced for testing - 45818; // 1 week
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 1;
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor)
        returns (uint256)
    {
        return _coin.balanceOf(account); // TODO: Update based on spec
    }
}