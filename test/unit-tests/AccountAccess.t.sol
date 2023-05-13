// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import {AdvancedFixture} from "../engine-integrations/AdvancedFixture.t.sol";

import "grappa-core/config/errors.sol";
import "grappa-core/config/types.sol";

import "src/errors.sol";

contract AdvancedMarginEngineAccessTest is AdvancedFixture {
    uint256 private depositAmount = 100 * 1e6;

    address private subAccountIdToModify;

    function setUp() public {
        usdc.mint(address(this), 1000_000 * 1e6);
        usdc.approve(address(engine), type(uint256).max);

        subAccountIdToModify = address(uint160(alice) ^ uint160(1));
    }

    function testTransferAccount() public {
        vm.startPrank(alice);
        engine.transferAccount(subAccountIdToModify, address(this));
        vm.stopPrank();

        // can access subaccount!
        _assertCanAccessAccount(address(this), true);
    }

    function testCannotTransferUnAuthorizedAccount() public {
        vm.expectRevert(NoAccess.selector);
        engine.transferAccount(alice, address(this));
    }

    function testCannotOverrideAnotherAccount() public {
        // write something to account "address(this)"
        _assertCanAccessAccount(address(this), true);

        vm.startPrank(alice);
        vm.expectRevert(AM_AccountIsNotEmpty.selector);
        engine.transferAccount(subAccountIdToModify, address(this));
        vm.stopPrank();
    }

    function _assertCanAccessAccount(address subAccountId, bool _canAccess) internal {
        // we can update the account now
        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);

        if (!_canAccess) vm.expectRevert(NoAccess.selector);

        engine.execute(subAccountId, actions);
    }
}
