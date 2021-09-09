// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Libraries
import "@openzeppelin/contracts/governance/IGovernor.sol";

/**
@title DAO Manager
@author Noah Litvin
@notice The intention of this contract is to allow an inheriting contract 
to permit a Governor (that adheres to OpenZeppelin's 4.x Governance API) to
interact with functions specified in the inheriting contract as succinctly
as possible.

In other words, it should be possible to propose, retrieve proposal IDs,
vote on proposals, and execute proposals that interact with whitelisted
functions in a contract that inherit this one.

Many limitations exist in the current implementation and, due to restrictions
in Solidity, it is unclear if this will ever be viable for production use
(at least without modifications to the underlying Governance API).

Current limitations include:
- Function calls that intend to transfer funds.
- Function calls with an arbitrary number of parameters.
- Function calls with arbitrary types.
- Multiple function calls in a single vote.

Further, the current implementation does not take the description field (as
specified in the OpenZeppelin Governance API), nor gas efficiency, into
account.
**/
abstract contract DaoManager {

    /* ========== ABSTRACT FUNCTIONS ========== */

    function setGovernor(address _governorAddress) external virtual;
    function getGovernor() public view virtual returns (IGovernor);
    function getProposalSignature(uint _proposalType) pure internal virtual returns (string memory);


    /* ========== INTERNAL VIEWS ========== */

    function generateTargets() internal view returns (address[] memory) {
        address[] memory targets = new address[](1);
        targets[0] = address(this);
        return targets;
    }

    function generateCalldatas(uint _proposalType, bytes calldata _param) internal pure returns (bytes[] memory) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(getProposalSignature(_proposalType), _param);
        return calldatas;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // ========== VIEWS ==========

    function getProposalId(uint _proposalType, bytes calldata _param) public view requireGovernor returns (uint) {
        return getGovernor().hashProposal(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            keccak256("description")
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createProposal(uint _proposalType, bytes calldata _param) external requireGovernor returns (uint) {
        return getGovernor().propose(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            "description"
        );
    }
    
    function executeProposal(uint _proposalType, bytes calldata _param) external requireGovernor returns (uint) {
        return getGovernor().execute(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            keccak256("description")
        );
    }

    
    /* ========== MODIFIERS ========== */

    modifier requireGovernor(){
        require(address(getGovernor()) != address(0), "You must set a governor by passing an address to setGovernor()");
        _;
    }

}