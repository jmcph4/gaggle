// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

import "../Manager.sol";
import "./MockPosition.sol";

contract ManagerTest is DSTest {
    ITransactional mock_pos;
    IERC20 mock_tok;

    function setUp() public {
        mock_pos = new MockPosition();

        ERC20PresetMinterPauser _tok = new ERC20PresetMinterPauser("Mock Token", "MOCK");
        _tok.mint(address(this), 100);

        mock_tok = IERC20(_tok);
    }

    function test_addNormal() public {
        Manager manager = new Manager();
        manager.add(address(mock_pos));
    }

    function test_cancelNormal() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));

        manager.cancel(id);
    }

    function testFail_cancelOutOfBounds() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));

        manager.cancel(id + 1);
    }

    function testFail_cancelPositionUp() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));
        manager.up(id);

        manager.cancel(id);
    }

    function test_upNormal() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));
       
        manager.up(id);

        (address actual_location,
            LibGaggle.State actual_state) = manager.positions(id);

        assertEq(actual_location, address(mock_pos));
        assertTrue(actual_state == LibGaggle.State.Up);
    }

    function test_downNormal() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));
        manager.up(id);

        manager.down(id);

        (address actual_location,
            LibGaggle.State actual_state) = manager.positions(id);

        assertEq(actual_location, address(mock_pos));
        assertTrue(actual_state == LibGaggle.State.Down);
    }

    function testFail_downPositionReady() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));

        manager.down(id);

        (address actual_location,
            LibGaggle.State actual_state) = manager.positions(id);

        assertEq(actual_location, address(mock_pos));
        assertTrue(actual_state == LibGaggle.State.Ready);
    }

    function testFail_downPositionCancelled() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));
        manager.cancel(id);

        manager.down(id);

        (address actual_location,
            LibGaggle.State actual_state) = manager.positions(id);

        assertEq(actual_location, address(mock_pos));
        assertTrue(actual_state == LibGaggle.State.Cancelled);
    }

    function testFail_downOutOfBounds() public {
        Manager manager = new Manager();
        uint32 id = manager.add(address(mock_pos));

        manager.down(id + 1);
    }

    function test_withdrawEthNormalZeroBalance() public {
        Manager manager = new Manager();

        manager.withdrawEth();

        assertEq(address(manager).balance, 0);
    }

    function test_withdrawEthNormalNonZeroBalance() public {
        Manager manager = new Manager();
        payable(address(manager)).transfer(100 wei);
        uint256 old_balance = address(this).balance;

        manager.withdrawEth();

        uint256 manager_balance = address(manager).balance;
        uint256 new_balance = address(this).balance;

        assertEq(manager_balance, 0);
        assertEq(new_balance - old_balance, 100 wei);
    }

    function test_withdrawERC20NormalZeroBalance() public {
        Manager manager = new Manager();

        manager.withdrawERC20(address(mock_tok));

        assertEq(mock_tok.balanceOf(address(manager)), 0);
    }

    function test_withdrawERC20NormalNonZeroBalance() public {
        Manager manager = new Manager();
        mock_tok.transfer(address(manager), 100);
        uint256 old_balance = mock_tok.balanceOf(address(this));

        manager.withdrawERC20(address(mock_tok));

        uint256 manager_balance = mock_tok.balanceOf(address(manager));
        uint256 new_balance = mock_tok.balanceOf(address(this));

        assertEq(manager_balance, 0);
        assertEq(new_balance - old_balance, 100);
    }

    receive() external payable {}

    fallback() external payable {}
}
