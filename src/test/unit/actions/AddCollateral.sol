// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// import test base and helpers.
import {Fixture} from "src/test/shared/Fixture.t.sol";
import {ActionHelper} from "src/test/shared/ActionHelper.sol";

import "src/types/MarginAccountTypes.sol";
import "src/constants/MarginAccountConstants.sol";
import "src/constants/MarginAccountEnums.sol";

contract TestAddCollateral is Fixture, ActionHelper {
    function setUp() public {
        usdc.mint(address(this), 10000 * 1e6);
        usdc.approve(address(grappa), type(uint256).max);

        weth.mint(address(this), 100 * 1e18);
        weth.approve(address(grappa), type(uint256).max);
    }

    function testAddCollateralChangeStorage() public {
        uint256 depositAmount = 1000 * 1e6;

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createAddCollateralAction(address(usdc), address(this), depositAmount);
        grappa.execute(address(this), actions);
        (, , , , uint80 _collateralAmount, address _collateral) = grappa.marginAccounts(address(this));

        assertEq(_collateral, address(usdc));
        assertEq(_collateralAmount, depositAmount);
    }

    function testAddCollateralMoveBalance() public {
        uint256 grappaBalanceBefoe = usdc.balanceOf(address(grappa));
        uint256 myBalanceBefoe = usdc.balanceOf(address(this));
        uint256 depositAmount = 1000 * 1e6;

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createAddCollateralAction(address(usdc), address(this), depositAmount);
        grappa.execute(address(this), actions);

        uint256 grappaBalanceAfter = usdc.balanceOf(address(grappa));
        uint256 myBalanceAfter = usdc.balanceOf(address(this));

        assertEq(myBalanceBefoe - myBalanceAfter, depositAmount);
        assertEq(grappaBalanceAfter - grappaBalanceBefoe, depositAmount);
    }

    function testAddCollateralLoopMoveBalances() public {
        uint256 grappaBalanceBefoe = usdc.balanceOf(address(grappa));
        uint256 myBalanceBefoe = usdc.balanceOf(address(this));
        uint256 depositAmount = 500 * 1e6;

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(address(usdc), address(this), depositAmount);
        actions[1] = createAddCollateralAction(address(usdc), address(this), depositAmount);
        grappa.execute(address(this), actions);

        uint256 grappaBalanceAfter = usdc.balanceOf(address(grappa));
        uint256 myBalanceAfter = usdc.balanceOf(address(this));

        assertEq(myBalanceBefoe - myBalanceAfter, depositAmount * 2);
        assertEq(grappaBalanceAfter - grappaBalanceBefoe, depositAmount * 2);
    }

    function testCannotAddDifferentCollateralToSameAccount() public {
        uint256 usdcAmount = 500 * 1e6;
        uint256 wethAmount = 10 * 1e18;

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(address(usdc), address(this), usdcAmount);
        actions[1] = createAddCollateralAction(address(weth), address(this), wethAmount);

        vm.expectRevert(WrongCollateral.selector);
        grappa.execute(address(this), actions);
    }
}
