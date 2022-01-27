// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";

import "./ITransactional.sol";
import "./LibGaggle.sol";

/**
 * @notice Implements a very simple ERC20 token trade.
 *          Given two ERC20 tokens, $A and $B, and a minimum output quantity, X,
 *          this strategy will buy *at least* X $B using *the entire balance of
 *          $B available to this contract*. To unwind the position, the opposite
 *          occurs.
 * @dev Errors are as follows:
 *          1: Address is null when disallowed
 *          2: Quantity out of range
 *          3: Position not active when it needs to be
 *          4: Trade not viable due to price
 */
contract SpotHold is ITransactional, Ownable {
    /// Input token
    IERC20 public input;

    /// Output token
    IERC20 public output;

    /// Minimum quantity of output token to receive upon position entry
    uint256 public amount_out;

    /// Handle to Uniswap V3 router to be used for trading
    ISwapRouter public immutable router;

    /// Price position entered at
    LibGaggle.Quotient public price;

    /// Is the position active?
    bool public live;

    /**
     * @param input_token Address of purchasing token
     * @param output_token Address of desired token
     * @param output_quantity (Minimum) quantity of desired token to receive
     *          upon position entry
     * @dev Throws if either of the token addresses are null
     * @dev Throws if output quantity is zero
     */
    constructor(
        address input_token,
        address output_token,
        uint256 output_quantity,
        address uniswap_router
    ) {
        require(
            input_token != address(0) &&
            output_token != address(0) &&
            uniswap_router != address(0),
        "1");
        require(output_quantity > 0, "2");

        input = IERC20(input_token);
        output = IERC20(output_token);
        amount_out = output_quantity;
        router = ISwapRouter(uniswap_router);
        live = false;
    }

    function up() external onlyOwner {
        uint256 amount_in = input.balanceOf(address(this));

        uint256 reported_amount_out = router.exactInputSingle(
            uniswapParams(LibGaggle.Direction.Up)
        );
        require(reported_amount_out >= amount_out, "4");

        price = LibGaggle.Quotient(amount_in, reported_amount_out);
        live = true;
    }

    function down() external onlyOwner {
        uint256 amount_in = output.balanceOf(address(this));

        uint256 reported_amount_out = router.exactInputSingle(
            uniswapParams(LibGaggle.Direction.Down)
        );
        live = false;

        /* withdraw assets */
        input.transfer(msg.sender, input.balanceOf(address(this)));
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    /**
     * @notice Determines whether the position is currently profitable or not
     * @return Flag specifying profitability of the position
     * @dev Throws if the position has not been entered
     */
    function profitable() external view returns (bool) {
        require(live, "3");
        uint256 wad_price = price.numerator / price.denominator;
        uint256 curr_price = 0; /* TODO: implement this! */

        return wad_price > curr_price;
    }

    /**
     * @notice Constructs parameter type suitable for submission to the Uniswap
     *          Periphery
     * @param direction Whether the position is going UP or DOWN
     * @return Uniswap parameter type
     */
    function uniswapParams(
        LibGaggle.Direction direction
    ) internal view returns (
        ISwapRouter.ExactInputSingleParams memory
    ) {
        if (direction == LibGaggle.Direction.Up) {
            return ISwapRouter.ExactInputSingleParams(
                address(input),
                address(output),
                0, /* TODO: fix */
                address(this),
                block.timestamp,
                input.balanceOf(address(this)),
                amount_out,
                0 /* TODO: fix */
            );
        } else if (direction == LibGaggle.Direction.Down) {
            return ISwapRouter.ExactInputSingleParams(
                address(output),
                address(input),
                0, /* TODO: fix */
                address(this),
                block.timestamp,
                output.balanceOf(address(this)),
                amount_out, /* TODO: fix */
                0 /* TODO: fix */
            );
        }
    }

    /**
     * @notice Withdraws all Ether held by this contract to the caller
     * @dev Only callable by the owner of this contract
     */
    function withdrawEth() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    /**
     * @notice Withdraws all of the specified ERC20 held by this contract to the
     *          caller
     * @param token Address of the ERC20 contract
     * @dev Only callable by the owner of this contract
     */
    function withdrawERC20(address token) external onlyOwner {
        IERC20 tok = IERC20(token);
        uint256 balance = tok.balanceOf(address(this));
        tok.transfer(msg.sender, balance);
    }

    receive() external payable {}

    fallback() external payable {}
}

