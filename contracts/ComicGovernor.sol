// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
// Consider implementing -> import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// That does the thing with snapshots I haven't quite grokked yet.

contract ComicGovernor is Governor, GovernorCountingSimple {

    IERC20 private _coin;
    mapping(address => uint) private accountVotes;
    
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

    function _castVote(uint256 proposalId, address account, uint8 support, string memory reason) internal override returns (uint256) {
        accountVotes[msg.sender]++;
        return super._castVote(proposalId, account, support, reason);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor)
        returns (uint256)
    {
        return _coin.balanceOf(account) + (sqrt(accountVotes[msg.sender] + 1) * 10); //  Increase voting power for more voting participation
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}