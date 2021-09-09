// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IERC20Extended is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract ComicDAO {

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
    function PROPOSAL_SIGNATURE(ProposalType _proposalType) pure internal returns (string memory) {
        if(_proposalType == ProposalType.AddWriter) { return "addWriter(bytes)"; }
        if(_proposalType == ProposalType.AddArtist) { return "addArtist(bytes)"; }
        if(_proposalType == ProposalType.AddConcept) { return "addConcept(bytes)"; }
    }

    function generateTargets() internal view returns (address[] memory) {
        address[] memory targets = new address[](1);
        targets[0] = address(this);
        return targets;
    }

    function generateCalldatas(ProposalType _proposalType, bytes calldata _param) internal pure returns (bytes[] memory) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(PROPOSAL_SIGNATURE(_proposalType), _param);
        return calldatas;
    }

    function getProposalId(ProposalType _proposalType, bytes calldata _param) public view returns (uint) {
        return governor.hashProposal(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            keccak256("description")
        );
    }

    function createProposal(ProposalType _proposalType, bytes calldata _param) external returns (uint) {
        governor.propose(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            "description"
        );
    }
    
    function executeProposal(ProposalType _proposalType, bytes calldata _param) external returns (uint) {
        governor.execute(
            generateTargets(),
            new uint256[](1),
            generateCalldatas(_proposalType, _param),
            keccak256("description")
        );
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


    modifier onlyGovernor() {
        require(msg.sender == address(governor), "Only the governor may execute this function.");
        _;
    }

    function setCoinAddress(address _coinAddress) external { //TODO: onlyOwner?
        coin = IERC20Extended(_coinAddress);
    }

    function setGovernorAddress(address _governorAddress) external { //TODO: onlyOwner?
        governor = IGovernor(_governorAddress);
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

    fallback() external payable {
        revert("Use the contribute() function");
    }

}