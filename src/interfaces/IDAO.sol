// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface DAO {
    error InvalidInitialization();
    error NotInitializing();

    event Initialized(uint64 version);
    event ProposalCreated(uint256 proposalId, address proposer);
    event ProposalExecuted(uint256 proposalId);
    event ProposalQueued(uint256 id, uint256 eta);
    event Voted(uint256 proposalId, address voter, bool support, uint256 votes);

    function __acceptAdmin() external;
    function _authorizeCaller(address _caller) external;
    function _deauthorizeCaller(address _caller) external;
    function authorizedCallers(address) external view returns (bool);
    function createProposal(address[] memory _targets, string[] memory _signatures, bytes[] memory _datas) external;
    function delegate(address delegatee) external;
    function executeProposal(uint256 proposalId) external;
    function guardian() external view returns (address);
    function initialize(address _token, address _treasury, address _timelock, address _gaurdian) external;
    function latestProposalIds(address) external view returns (uint256);
    function proposalCost() external view returns (uint256);
    function proposalCount() external view returns (uint256);
    function proposalMaxOperations() external pure returns (uint256);
    function proposalReceipts(uint256, address) external view returns (bool hasVoted, bool support, uint96 votes);
    function proposalThreshold() external pure returns (uint256);
    function proposals(uint256)
        external
        view
        returns (
            bool executed,
            address proposer,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 startBlock,
            uint256 endBlock,
            uint256 eta
        );
    function queueProposal(uint256 proposalId) external;
    function queuedTransactions(bytes32) external view returns (bool);
    function quorumVotes() external pure returns (uint256);
    function timelock() external view returns (address);
    function treasury() external view returns (address);
    function treasuryAddress() external view returns (address);
    function undelegate() external;
    function vote(uint256 proposalId, bool support) external;
    function voted(address, uint256) external view returns (bool);
    function votingDelay() external pure returns (uint256);
    function votingPeriod() external pure returns (uint256);
    function werewolfToken() external view returns (address);
    function werewolfTokenAddress() external view returns (address);
}
