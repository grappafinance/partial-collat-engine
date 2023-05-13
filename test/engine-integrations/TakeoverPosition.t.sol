// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import {AdvancedFixture} from "./AdvancedFixture.t.sol";

import "grappa-core/config/enums.sol";
import "grappa-core/config/types.sol";
import "grappa-core/config/constants.sol";
import "grappa-core/config/errors.sol";

// contract TestTakeoverPosition is AdvancedFixture {
//     uint256 public expiry;

//     uint64 private amount = uint64(1 * UNIT);
//     uint256 private tokenId;
//     uint64 private strike;
//     uint256 private initialCollateral;

//     address private accountId;

//     function setUp() public {
//         usdc.mint(address(this), 1000_000 * 1e6);
//         usdc.approve(address(engine), type(uint256).max);

//         // setup account for alice
//         vm.startPrank(alice);
//         usdc.mint(alice, 1000_000 * 1e6);

//         usdc.approve(address(engine), type(uint256).max);

//         expiry = block.timestamp + 7 days;

//         oracle.setSpotPrice(address(weth), 3500 * UNIT);

//         // mint option
//         initialCollateral = 500 * 1e6;

//         strike = uint64(4000 * UNIT);

//         accountId = alice;

//         tokenId = getTokenId(TokenType.CALL, productId, expiry, strike, 0);
//         ActionArgs[] memory actions = new ActionArgs[](2);
//         actions[0] = createAddCollateralAction(usdcId, alice, initialCollateral);
//         actions[1] = createMintAction(tokenId, alice, amount);

//         // mint option
//         engine.execute(accountId, actions);

//         vm.stopPrank();
//     }

//     function testCannotTakeoverHealthyVault() public {
//         vm.expectRevert(AM_AccountIsHealthy.selector);
//         engineId.takeoverPosition(accountId, address(this), 0);
//     }

//     function testCannotTakeoverPositionWithoutPayingCollateral() public {
//         oracle.setSpotPrice(address(weth), 3800 * UNIT);

//         vm.expectRevert(BM_AccountUnderwater.selector);
//         engineId.takeoverPosition(accountId, address(this), 0);
//     }

//     function testCannotTakeoverPositionWithoutPayingEnoughCollateral() public {
//         oracle.setSpotPrice(address(weth), 3800 * UNIT);

//         vm.expectRevert(BM_AccountUnderwater.selector);
//         engineId.takeoverPosition(accountId, address(this), uint80(50 * 1e6));
//     }

//     function testTakeoverPosition() public {
//         oracle.setSpotPrice(address(weth), 3800 * UNIT);

//         uint80 tapUpAmount = 300 * 1e6;

//         engineId.takeoverPosition(accountId, address(this), tapUpAmount);

//         // old margin account should be reset
//         (uint256 shortCallId, , uint64 shortCallAmount, , uint80 collateralAmount, uint8 collateralId) = engine
//             .marginAccounts(accountId);

//         assertEq(shortCallId, 0);
//         assertEq(shortCallAmount, 0);
//         assertEq(collateralAmount, 0);
//         assertEq(collateralId, 0);

//         // new margin account should be updated
//         (shortCallId, , shortCallAmount, , collateralAmount, collateralId) = engine.marginAccounts(address(this));

//         assertEq(shortCallId, tokenId);
//         assertEq(shortCallAmount, amount);
//         assertEq(collateralAmount, initialCollateral + tapUpAmount);
//         assertEq(collateralId, usdcId);
//     }
// }
