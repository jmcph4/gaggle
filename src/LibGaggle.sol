// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @notice Type definitions for shardd Gaggle logic
 */
library LibGaggle {
    /**
     * @notice Represents the state of a position
     */
    enum State {
        Ready,              /* Position is ready to be brought up */
        Up,                 /* Position is currently active */
        Down,               /* Position is currently inactive */
        Cancelled           /* Position is unable to be brought up */
    }

    /**
     * @notice Represents a position
     */
    struct Position {
        address location;   /* Address of the position contract */
        State status;       /* Current state of the position */
    }
}

