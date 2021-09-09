// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";

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
- Function calls with arbitrary types (Currently only supports address and string)
- Function calls that intend to transfer funds.
- Function calls with an arbitrary number of parameters.
- Multiple function calls in a single vote.

Further, the current implementation does not take the description field (as
specified in the OpenZeppelin Governance API), nor gas efficiency, into
account.
**/

abstract contract DaoManager {

    /* ========== ABSTRACT FUNCTIONS ========== */

    function setGovernor(address _governorAddress) external virtual;
    function getGovernor() public view virtual returns (IGovernor);
    function getProposableParamType(string memory _proposalFunctionName) pure internal virtual returns (string memory);


    /* ========== INTERNAL VIEWS ========== */

    function bytesToAddress(bytes memory _bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(_bys,20))
        } 
    }

    function bytesToString(bytes memory _bys) private pure returns (string memory) {
        return string(abi.encodePacked(_bys));
    }

    function generateTargets() internal view returns (address[] memory) {
        address[] memory targets = new address[](1);
        targets[0] = address(this);
        return targets;
    }

    function generateCalldatas(string memory _proposalFunctionName, bytes calldata _param) internal view returns (bytes[] memory) { // change view back to pure
        string memory _paramType = getProposableParamType(_proposalFunctionName);
        require(bytes(_paramType).length > 0, "This function is not proposeable");
        string memory signature = string(abi.encodePacked(_proposalFunctionName, "(", _paramType, ")"));
        bytes[] memory calldatas = new bytes[](1);
        if(keccak256(abi.encodePacked(_paramType)) == keccak256("address")) {
            calldatas[0] = abi.encodeWithSignature(signature, bytesToAddress(_param));
        } else if(keccak256(abi.encodePacked(_paramType)) == keccak256("string")) {
            calldatas[0] = abi.encodeWithSignature(signature, bytesToString(_param));
        } else {
            calldatas[0] = _param;
        }
        return calldatas;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // ========== VIEWS ==========

    function getProposalId(string memory _proposalFunctionName, bytes calldata _param) public view requireGovernor returns (uint) {
        return getGovernor().hashProposal(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalFunctionName, _param),
            keccak256("description")
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createProposal(string memory _proposalFunctionName, bytes calldata _param) external requireGovernor returns (uint) {
        return getGovernor().propose(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalFunctionName, _param),
            "description"
        );
    }
    
    function executeProposal(string memory _proposalFunctionName, bytes calldata _param) external requireGovernor returns (uint) {
        return getGovernor().execute(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalFunctionName, _param),
            keccak256("description")
        );
    }

    
    /* ========== MODIFIERS ========== */

    modifier requireGovernor(){
        require(address(getGovernor()) != address(0), "You must set a governor by passing an address to setGovernor()");
        _;
    }

}