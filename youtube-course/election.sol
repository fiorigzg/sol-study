// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Election {

    string[] public electors;
    address public owner;
    uint256 public maxVotes;
    uint256 public totalVotes;
    uint256 public electionEndTime;
    mapping(address => bool) public userVotes;
    mapping(uint256 => uint256) public numberOfVotes;

    error OnlyOwnerAllowed();
    error ElectorDoesNotExist(uint256 _pickedElector, uint256 _totalElectors);

    event Voted(uint256 _voted, address _voter);

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        _;
    }

    constructor(string[] memory _electors, uint256 _maxVotes, uint256 _electionTime) {
        electors = _electors;
        maxVotes = _maxVotes;
        owner = msg.sender;
        electionEndTime = block.timestamp + _electionTime;
    }

    function voteWinner() public view returns(string memory) {
        uint256 winner = 0;
        uint256 winnerVotes = 0;
        bool isWinner = false;
        for (uint256 i = 0; i < electors.length; i++) {
            if (numberOfVotes[i] > winnerVotes) {
                winner = i;
                winnerVotes = numberOfVotes[i];
                isWinner = true;
            }
        }

        if (isWinner) return electors[winner];
        return "nobody";
    }

    function vote(uint256 _number) public {
        require(userVotes[msg.sender]==false, "Your address can't vote");
        if (_number >= electors.length) revert ElectorDoesNotExist(_number, electors.length);
        require(totalVotes < maxVotes, "Max votes has been reached");
        require(msg.sender != owner, "Owner can't vote");
        require(block.timestamp < electionEndTime, "Voting is over");

        userVotes[msg.sender] = true;
        numberOfVotes[_number] += 1;
        totalVotes += 1;

        emit Voted(_number, msg.sender);
    }

    function stopVote() public onlyOwner {
        electionEndTime = block.timestamp;
    }

    function resetMaxVotes(uint256 _newMaxVotes) public onlyOwner {
        require(_newMaxVotes > maxVotes, "You can't decrease maxVotes");

        maxVotes = _newMaxVotes;
    }

    function resetEndTime(uint256 _newEndTime) public onlyOwner {
        require(_newEndTime > electionEndTime, "Must be later");

        electionEndTime = _newEndTime;
    }
}