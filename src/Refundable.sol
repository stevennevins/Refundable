// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Refundable {
    /// from nouns
    /// @notice The maximum priority fee used to cap gas refunds in `castRefundableVote`
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice The vote refund gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REFUND_BASE_GAS = 36000;

    /// @notice The maximum gas units the DAO will refund voters on; supports about 9,190 characters
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;

    /// @notice The maximum basefee the DAO will refund voters on
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;

    event Refund(address indexed origin, uint256 calcultedRefund, bool sent);

    modifier refundable() {
        uint256 startGas = gasleft();
        _;
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
        uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
        uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
        uint256 refundAmount = min(gasPrice * gasUsed, balance);
        (bool refundSent,) = tx.origin.call{value: refundAmount}("");
        emit Refund(tx.origin, refundAmount, refundSent);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
