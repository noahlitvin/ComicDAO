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

    // DAO Manager Overrides
    
    function getProposableParamType(string memory _proposalFunctionName) pure internal override returns (string memory) {
        if(keccak256(abi.encodePacked(_proposalFunctionName)) == keccak256("addWriter")) { return "address"; }
        if(keccak256(abi.encodePacked(_proposalFunctionName)) == keccak256("addArtist")) { return "address"; }
        if(keccak256(abi.encodePacked(_proposalFunctionName)) == keccak256("addConcept")) { return "string"; }
    }

    function setGovernor(address _governorAddress) external override { //TODO: onlyOwner?
        governor = IGovernor(_governorAddress);
    }
    function getGovernor() public view override returns (IGovernor) {
        return governor;
    }
    

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addConcept(string memory _newConcept) external onlyGovernor {
        concepts.push(_newConcept);
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addWriter(address _param) external onlyGovernor {
        writers.push(_param);
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addArtist(address _param) external onlyGovernor {
        artists.push(_param);
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