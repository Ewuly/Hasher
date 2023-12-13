
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
contract RPS {
    struct Game {
        address j1;
        address j2;
        bytes32 c1Hash;
        Move c2;
        uint256 stake;
        uint256 lastAction;
    }
    enum Move {Null, Rock, Paper, Scissors, Spock, Lizard}
    mapping(uint256 => Game) public games;
    uint256 public gameId = 0;
    uint256 public TIMEOUT = 5 minutes;
    
    
    function createGame(bytes32 _c1Hash, address _j2) external payable {
        games[gameId] = Game({
            j1: msg.sender,
            j2: _j2,
            c1Hash: _c1Hash,
            c2: Move.Null,
            stake: msg.value,
            lastAction: block.timestamp
        });
        gameId++;
    }
    function play(uint256 _gameId, Move _c2) external payable {
        Game storage game = games[_gameId];
        require(game.j1 != address(0), "Game does not exist");
        require(game.c2 == Move.Null, "Move is already played");
        require(_c2 != Move.Null, "Move is null");
        require(msg.value == game.stake, "J2 didn't pay the same amount");
        require(msg.sender == game.j2, "Player is not J2");
        game.c2 = _c2;
        game.lastAction = block.timestamp;
    }
    function solve(uint256 _gameId, Move _c1, uint256 _salt) external {
        Game storage game = games[_gameId];
        require(game.j1 != address(0), "Game does not exist");
        require(_c1 != Move.Null, "J1 move is not valid");
        require(game.c2 != Move.Null, "J2 has not played yet");
        require(msg.sender == game.j1, "Caller is not J1");
        require(keccak256(abi.encodePacked(_c1, _salt)) == game.c1Hash, "Hash is not the move");
        if (win(_c1, game.c2)) {
            payable(game.j1).transfer(2 * game.stake);
        } else if (win(game.c2, _c1)) {
            payable(game.j2).transfer(2 * game.stake);
        } else {
            payable(game.j1).transfer(game.stake);
            payable(game.j2).transfer(game.stake);
        }
        game.stake = 0;
        game.c2 = Move.Null;
    }
    function j1Timeout(uint256 _gameId) external {
        Game storage game = games[_gameId];
        require(game.j1 != address(0), "Game does not exist");
        require(game.c2 != Move.Null, "J2 has not played yet");
        require(block.timestamp > game.lastAction + TIMEOUT, "Time is not out");
        payable(game.j2).transfer(2 * game.stake);
        game.stake = 0;
    }
    function j2Timeout(uint256 _gameId) external {
        Game storage game = games[_gameId];
        require(game.j1 != address(0), "Game does not exist");
        require(game.c2 == Move.Null, "J2 has played");
        require(block.timestamp > game.lastAction + TIMEOUT, "Time is not out");
        payable(game.j1).transfer(game.stake);
        game.stake = 0;
    }
    function win(Move _c1, Move _c2) internal pure returns (bool w) {
        if (_c1 == _c2) return false;
        else if (_c1 == Move.Null) return false;
        else if (uint(_c1) % 2 == uint(_c2) % 2) return (_c1 < _c2);
        else return (_c1 > _c2);
    }
}
