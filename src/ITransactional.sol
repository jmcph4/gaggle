// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @notice Represents a migration
 */
interface ITransactional {
    function up() external;
    function down() external;
}

