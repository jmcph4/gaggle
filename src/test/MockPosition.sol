// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ITransactional.sol";

contract MockPosition is ITransactional {
    function up() external {
        /* do useless stuff... */
        uint256 x = 0;

        for (uint256 i=0;i<12;i++) {
            x++;
        }
    }

    function down() external {
        /* do more useless stuff... */
        uint256 x = 0;

        for (uint256 i=0;i<12;i++) {
            x++;
        }
    }
}

