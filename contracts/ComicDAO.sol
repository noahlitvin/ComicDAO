// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./DaoManager.sol";
interface IERC20Extended is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract ComicDAO is DaoManager {

    mapping(address => bool) public writers;
    mapping(address => bool) public artists;
    string[] public concepts;
    mapping(uint => string) public conceptToSketch;
    mapping(string => string) public sketchToDrawing;
    uint completedDrawings;

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
    function addWriter(address _param) external onlyGovernor {
        writers[_param] = true;
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addArtist(address _param) external onlyGovernor {
        artists[_param] = true;
    }

    /* @notice This function allows the governor to add new writer to the DAO. */
    function addConcept(string memory _newConcept) external onlyGovernor {
        concepts.push(_newConcept);
    }

    /* @notice This function allows any approved writer to submit a sketch corresponding to an approved concept, receive payment, and prevent someone from resubmitting a sketch corresponding to the same concept */
    function submitSketch(uint _conceptId, string memory _sketchURI) external {
        require(writers[msg.sender], "Only approved writers may submit sketches");
        require(bytes(conceptToSketch[_conceptId]).length > 0, "A sketch has already been submitted for this concept.");

        conceptToSketch[_conceptId] = _sketchURI;

        uint _paymentAmount = address(this).balance / 100; // Writers and artists receive 1% of the pool per submission.
        (bool sent,) = msg.sender.call{value: _paymentAmount}("");
        require(sent, "Failed to send Ether");
    }

    /* @notice This function allows any approved artist to submit a drawing corresponding to a sketch awaiting a drawing, receive payment, and prevent someone from resubmitting a drawing corresponding to the same sketch */
    function submitDrawing(string memory _sketchURI, string memory _drawingURI) external {
        require(artists[msg.sender], "Only approved artists may submit drawings");
        require(bytes(sketchToDrawing[_sketchURI]).length > 0, "A drawing has already been submitted for this sketch.");

        sketchToDrawing[_sketchURI] = _drawingURI;
        completedDrawings++;

        uint _paymentAmount = address(this).balance / 100; // Writers and artists receive 1% of the pool per submission.
        (bool sent,) = msg.sender.call{value: _paymentAmount}("");
        require(sent, "Failed to send Ether");
    }

    /* @notice This function allows the address of CMC coin to be set, only once. */
    function setCoinAddress(address _coinAddress) external {
        require(address(coin) == address(0), "The coin address has already been set.");
        coin = IERC20Extended(_coinAddress);
    }

    /* @notice This function mints $CMC tokens for contributors */
    function contribute() external payable {
        require(msg.value > 0, "You must contribute ether.");
        uint coinsToMint = msg.value - (sqrt(completedDrawings + 1) / msg.value);  // Amount of coins issues decreases as more drawings are completed to incentivize early participation.
        coin.mint(msg.sender, coinsToMint);
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
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