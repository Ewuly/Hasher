// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RPS {
    address public j1; // The first player creating the contract.
    address public j2; // The second player.
    enum Move {Null, Rock, Paper, Scissors, Spock, Lizard} // Possible moves. Note that if the parity of the moves is the same the lower one wins, otherwise the higher one.
    bytes32 public c1Hash; // Commitment of j1.
    Move public c2; // Move of j2. Move.Null before he played.
    uint256 public stake; // Amount bet by each party.
    uint256 public TIMEOUT = 5 minutes; // If some party takes more than TIMEOUT to respond, the other can call TIMEOUT to win.
    uint256 public lastAction; // The time of the last action. Useful to determine if someone has timed out.

    /** @dev Constructor. Must send the amount at stake when creating the contract. Note that the move and salt must be saved.
     *  @param _c1Hash Must be equal to keccak256(c1,salt) where c1 is the move of the j1.
     */
    function RPSinit(bytes32 _c1Hash, address _j2) external payable {
        stake = msg.value; // La mise correspond à la quantité d'ethers envoyés.
        j1 = msg.sender;
        j2 = _j2;
        c1Hash = _c1Hash;
        lastAction = block.timestamp;
    }

    /** @dev To be called by j2 and provided stake.
     *  @param _c2 The move submitted by j2.
     */
    function play(Move _c2) external payable {
        require(c2 == Move.Null, "Move is already played"); // J2 has not played yet.
        require(_c2 != Move.Null, "Move is null"); // A move is selected.
        require(msg.value == stake, "J2 didn't pay the same amount"); // J2 has paid the stake.
        require(msg.sender == j2, "Player is not J2"); // Only j2 can call this function.

        c2 = _c2;
        lastAction = block.timestamp;
    }

    /** @dev To be called by j1. Reveal the move and send the ETH to the winning party or split them.
     *  @param _c1 The move played by j1.
     *  @param _salt The salt used when submitting the commitment when the constructor was called.
     */
    function solve(Move _c1, uint256 _salt) external {
        require(_c1 != Move.Null, "J1 move is not valid"); // J1 should have made a valid move.
        require(c2 != Move.Null, "J2 has not played yet"); // J2 must have played.

        require(msg.sender == j1, "Caller is not J1"); // J1 can call this.
        require(keccak256(abi.encodePacked(_c1, _salt)) == c1Hash, "Hash is not the move"); // Verify the value is the committed one.

        // If j1 or j2 throws at fallback it won't get funds and that is his fault.
        // Despite what the warnings say, we should not use transfer as a throwing fallback would be able to block the contract, in case of tie.
        if (win(_c1, c2)) {
            payable(j1).transfer(2 * stake);
        } else if (win(c2, _c1)) {
            payable(j2).transfer(2 * stake);
        } else {
            payable(j1).transfer(stake);
            payable(j2).transfer(stake);
        }
        stake = 0;
        c2 = Move.Null;
    }

    /** @dev Let j2 get the funds back if j1 did not play.
     */
    function j1Timeout() external {
        require(c2 != Move.Null, "J2 has not played yet"); // J2 already played.
        require(block.timestamp > lastAction + TIMEOUT, "Time is not out"); // Timeout time has passed.
        payable(j2).transfer(2 * stake);
        stake = 0;
    }

    /** @dev Let j1 take back the funds if j2 never played.
     */
    function j2Timeout() external {
        require(c2 == Move.Null, "J2 has played"); // J2 has not played.
        require(block.timestamp > lastAction + TIMEOUT, "Time is not out"); // Timeout time has passed.
        payable(j1).transfer(stake);
        stake = 0;
    }

    /** @dev Is this move winning over the other.
     *  @param _c1 The first move.
     *  @param _c2 The move the first move is considered again.
     *  @return w True if c1 beats c2. False if c1 is beaten by c2 or in case of tie.
     */
    function win(Move _c1, Move _c2) internal pure returns (bool w) {
        if (_c1 == _c2) return false; // They played the same so no winner.
        else if (_c1 == Move.Null) return false; // They did not play.
        else if (uint(_c1) % 2 == uint(_c2) % 2) return (_c1 < _c2);
        else return (_c1 > _c2);
    }
}
