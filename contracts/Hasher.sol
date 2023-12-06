// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Hasher{
    /** @dev Give the commitement. Must only be called locally.
     *  @param _c The move.
     *  @param _salt The salt to increase entropy.
     */
    function hash(uint8 _c, uint256 _salt) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_c,_salt));
    }
}