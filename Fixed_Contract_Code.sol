Fixed Code:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;    }
}
contract CryptoRoulette is Ownable {
    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 0.1 ether;
    bool public paused = false;
    struct Game {
        address player;
        uint256 number;
        bool isWinner;
    }
    Game[] public gamesPlayed;
    event GamePlayed(address indexed player, uint256 guessedNumber, bool isWinner);
    event ContractPaused();
    event ContractUnpaused();
    event FundsTransferred(address indexed recipient, uint256 amount);
    event FundsReceived(address indexed sender, uint256 amount);
   modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
  constructor() {
        shuffle();
    }
    function shuffle() internal {
        secretNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % 20) + 1;
    }
   function play(uint256 number) external payable whenNotPaused {
        require(msg.value >= betPrice, "Insufficient bet amount");
        require(number >= 1 && number <= 20, "Invalid number");
        bool isWinner = (number == secretNumber);
        gamesPlayed.push(Game(msg.sender, number, isWinner));
        if (isWinner) {
            uint256 contractBalance = address(this).balance;
            lastPlayed = block.timestamp;
            shuffle();
            (bool success, ) = msg.sender.call{value: contractBalance}("");
            require(success, "Transfer failed");
            emit FundsTransferred(msg.sender, contractBalance);
        }
        emit GamePlayed(msg.sender, number, isWinner);
    }

    function getLastGameResult() public view returns (uint256 guessedNumber, bool isWinner) {
        require(gamesPlayed.length > 0, "No games played");
        Game memory lastGame = gamesPlayed[gamesPlayed.length - 1];
        require(lastGame.player == msg.sender, "Not your game");

        return (lastGame.number, lastGame.isWinner);
    }

    function pause() public onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    function disableContract() public onlyOwner {
        require(block.timestamp > lastPlayed + 1 days, "Cannot disable yet");
        paused = true; // Disable the contract
        uint256 contractBalance = address(this).balance;

        if (contractBalance > 0) {
            (bool success, ) = owner.call{value: contractBalance}("");
            require(success, "Transfer failed");
        }

        emit ContractPaused();
    }
}

