// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
The intention of this contract is to abstract management of a DAO by allowing an inheriting contract to specify functions that can be proposed and executed by a contract following OpenZeppelin's Governor API with as little code as possible.
Ideally, just a modifier in the inhereting contract would allow this, but due to constraints with Solidity, there's a little more to it.
Many limitations exist with this current implementation:
- passing msg.value
- parameter types
- number of params
Further notes:
- This does not take into account the description field
- This does not take into account gas efficiency.
*/


// Libraries
import "@openzeppelin/contracts/governance/IGovernor.sol";

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