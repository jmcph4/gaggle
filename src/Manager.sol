// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

import "./ITransactional.sol";
import "./LibGaggle.sol";

/**
 * @notice Stores a set of positions, tracking their state and also executing
 *          their associated migration logic
 * @dev Errors are as follows:
 *          1: Identifier out of bounds
 *          2: Invalid state transition
 */
contract Manager is Ownable, Pausable {
    /// Number of positions currently under management
    uint32 public num_positions;

    /// Positions currently under management
    mapping (uint32 => LibGaggle.Position) public positions;

    /**
     * @notice Adds a new position
     * @param loc Address of the implementation contract 
     * @return Unique identifier of the newly-created position
     * @dev Only callable by the owner of this contract
     */
    function add(address loc) external onlyOwner returns (uint32) {
        LibGaggle.Position memory pos = LibGaggle.Position(
            loc,
            LibGaggle.State.Ready
        );
        pos.status = LibGaggle.State.Ready;
        positions[num_positions] = pos;
        num_positions++;
        return num_positions - 1;
    }

    /**
     * @notice Cancels the position associated with the specified identifier
     * @param id Unique identifier of the position
     * @dev Throws if the position is not in the READY state
     * @dev Only callable by the owner of this contract
     */
    function cancel(uint32 id) external checkID(id) onlyOwner {
        require(positions[id].status == LibGaggle.State.Ready, "2");
        positions[id].status = LibGaggle.State.Cancelled;
    }

    /**
     * @notice Activates the specified position
     * @param id Unique identifier of the position
     * @dev Throws if `id` is out of bounds
     * @dev Throws if position is not in the READY state
     * @dev Throws if *any* of the remote calls required to active the position
     *          fail
     * @dev Only callable by the owner of this contract
     */
    function up(uint32 id) external checkID(id) onlyOwner {
        require(positions[id].status == LibGaggle.State.Ready, "2");
        positions[id].status = LibGaggle.State.Up;
        ITransactional(positions[id].location).up();
    }

    /**
     * @notice Deactivates the specified position
     * @param id Unique identifier of the position
     * @dev Throws if `id` is out of bounds
     * @dev Throws if position is not in the UP state
     * @dev Throws if *any* of the remote calls required to deactivate the
     *          position fail
     * @dev Only callable by the owner of this contract
     */
    function down(uint32 id) external checkID(id) onlyOwner {
        require(positions[id].status == LibGaggle.State.Up, "2");
        positions[id].status = LibGaggle.State.Down;
        ITransactional(positions[id].location).down();
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

    /**
     * @notice Enforces that the specified ID is within the valid space of IDs
     * @param id ID to bounds check
     */
    modifier checkID(uint32 id) {
        require(id < num_positions, "1");
        _;
    }
}

