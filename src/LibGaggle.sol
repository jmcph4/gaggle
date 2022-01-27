// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @notice Type definitions for shared Gaggle logic
 */
library LibGaggle {
    /**
     * @notice Represents the state of a position
     */
    enum State {
        Ready,                  /* Position is ready to be brought up */
        Up,                     /* Position is currently active */
        Down,                   /* Position is currently inactive */
        Cancelled               /* Position is unable to be brought up */
    }

    /**
     * @notice Represents a position
     */
    struct Position {
        address location;       /* Address of the position contract */
        State status;           /* Current state of the position */
    }

    /**
     * @notice Represents a fraction
     */
    struct Quotient {
        uint256 numerator;      /* Numerator */
        uint256 denominator;    /* Denominator */
    }

    /**
     * @notice Represents the direction of a state transition of a position
     */
    enum Direction {
        Up,                     /* Position is going upwards */
        Down                    /* Position is going downwards */
    }
}

