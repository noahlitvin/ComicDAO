// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./DaoManager.sol";
interface IERC20Extended is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract ComicDAO is DaoManager {

    address[] public writers;
    address[] public artists;
    string[] public concepts;
    uint[] public conceptsAwaitingSketch;
    uint[] public sketchesAwaitingDrawing;

    IERC20Extended private coin;
    IGovernor private governor;

    enum ProposalType {
        AddWriter,
        AddArtist,
        AddConcept
    }

    // DAO Manager overrides
    function getProposalSignature(uint _proposalType) pure internal override returns (string memory) {
        if(ProposalType(_proposalType) == ProposalType.AddWriter) { return "addWriter(bytes)"; }
        if(ProposalType(_proposalType) == ProposalType.AddArtist) { return "addArtist(bytes)"; }
        if(ProposalType(_proposalType) == ProposalType.AddConcept) { return "addConcept(bytes)"; }
    }

    function setGovernor(address _governorAddress) external override { //TODO: onlyOwner?
        governor = IGovernor(_governorAddress);
    }
    function getGovernor() public view override returns (IGovernor) {
        return governor;
    }
    

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addConcept(string memory _newConcept) external onlyGovernor {
        concepts.push(_newConcept));
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addConcept(bytes calldata _param) external onlyGovernor {
        concepts.push(string(abi.encodePacked(_param)));
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addWriter(bytes calldata _param) external onlyGovernor {
        writers.push(bytesToAddress(_param));
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addArtist(bytes calldata _param) external onlyGovernor {
        artists.push(bytesToAddress(_param));
    }

    function setCoinAddress(address _coinAddress) external { // TODO: onlyOwner?
        coin = IERC20Extended(_coinAddress);
    }


    /* @notice This function mints $CMC tokens for contributors */
    function contribute() external payable {
        coin.mint(msg.sender, msg.value); // TODO: modify based on spec
    }

    /* @notice This function allows any approved writer to submit a sketch corresponding to an approved concept, receive payment, and prevent someone from resubmitting a sketch corresponding to the same concept */
    function submitSketch(uint conceptId, string memory _sketchURI) external returns (uint sketchId) {
        
    }

    /* @notice This function allows any approved artist to submit a drawing corresponding to a sketch awaiting a drawing, receive payment, and prevent someone from resubmitting a drawing corresponding to the same sketch */
    function submitDrawing(uint conceptId, string memory _sketchURI) external returns (uint sketchId) {
        
    }

    function bytesToAddress(bytes memory _bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(_bys,20))
        } 
    }

    // ========== RESTRICTED ==========

    /**
     * @notice Fallback function
     */
    fallback() external payable {
        revert("Use the contribute() function");
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == address(governor), "Only the governor may execute this function.");
        _;
    }

}