// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import {AdvancedFixture} from "./AdvancedFixture.t.sol";

import "grappa-core/config/enums.sol";
import "grappa-core/config/types.sol";
import "grappa-core/config/constants.sol";
import "grappa-core/config/errors.sol";
import "src/errors.sol";

import "../mocks/MockERC20.sol";

contract TestMintVanillaOption is AdvancedFixture {
    uint256 public expiry;

    function setUp() public {
        usdc.mint(address(this), 1000_000 * 1e6);
        usdc.approve(address(engine), type(uint256).max);

        weth.mint(address(this), 100 * 1e18);
        weth.approve(address(engine), type(uint256).max);

        expiry = block.timestamp + 14 days;

        oracle.setSpotPrice(address(weth), 3000 * UNIT);
    }

    function testMintCall() public {
        uint256 depositAmount = 10000 * 1e6;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);
        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, tokenId);
        assertEq(shortPutId, 0);
        assertEq(shortCallAmount, amount);
        assertEq(shortPutAmount, 0);

        assertEq(engine.isAccountHealthy(address(this)), true);
    }

    function testMintCoveredCall() public {
        uint256 depositAmount = 2 * 1e17; // 0.2 eth

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productIdEthCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);
        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, tokenId);
        assertEq(shortPutId, 0);
        assertEq(shortCallAmount, amount);
        assertEq(shortPutAmount, 0);
    }

    function testMintCallWithBTCCollat() public {
        // create wbtc and mint to user
        MockERC20 wbtc = new MockERC20("WBTC", "WBTC", 8);
        wbtc.mint(address(this), 1 * 1e8);
        wbtc.approve(address(engine), type(uint256).max);
        // register wbtc in the system
        uint8 wbtcId = grappa.registerAsset(address(wbtc));
        uint40 productIdBtcCollat =
            grappa.getProductId(address(oracle), address(engine), address(weth), address(usdc), address(wbtc));
        engine.setProductMarginConfig(productIdBtcCollat, 180 days, 1 days, 7000, 1000, 10000);
        oracle.setSpotPrice(address(wbtc), 40_000 * UNIT); // 10x price of eth

        // prepare arguments
        uint256 depositAmount = 2 * 1e6; // 0.02 btc
        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;
        uint256 tokenId = getTokenId(TokenType.CALL, productIdBtcCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wbtcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);
        (uint256 callId,, uint64 shortCallAmount,, uint80 collatAmount, uint8 collatId) = engine.marginAccounts(address(this));

        assertEq(callId, tokenId);
        assertEq(shortCallAmount, amount);
        assertEq(collatAmount, depositAmount);
        assertEq(collatId, wbtcId);
    }

    function testCannotMintCallWithLittleCollateral() public {
        uint256 depositAmount = 100 * 1e6;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintCallWithOtherProductId() public {
        uint256 depositAmount = 2 * 1e17; // 0.2 eth

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        // try to mint a tokenId that belongs to another margin engine
        uint40 fakeProductId = grappa.getProductId(address(oracle), address(1), address(weth), address(usdc), address(weth));
        uint256 tokenId = getTokenId(TokenType.CALL, fakeProductId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        vm.expectRevert(GP_Not_Authorized_Engine.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintCallWithDifferentCollateralType() public {
        uint256 depositAmount = 1 * 1e18;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(AM_InvalidToken.selector);
        engine.execute(address(this), actions);
    }

    function testMintCallSpread() public {
        uint256 longStrike = 3000 * UNIT;
        uint256 shortStrike = 3200 * UNIT;

        uint256 depositAmount = shortStrike - longStrike;

        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL_SPREAD, productId, expiry, longStrike, shortStrike);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, tokenId);
        assertEq(shortPutId, 0);
        assertEq(shortCallAmount, amount);
        assertEq(shortPutAmount, 0);
    }

    function testMintPut() public {
        uint256 depositAmount = 1000 * 1e6;

        uint256 strikePrice = 2000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);
        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, 0);
        assertEq(shortPutId, tokenId);
        assertEq(shortCallAmount, 0);
        assertEq(shortPutAmount, amount);
    }

    function testCannotMintPutWithLittleCollateral() public {
        uint256 depositAmount = 100 * 1e6;

        uint256 strikePrice = 2000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testMintPutSpread() public {
        uint256 longStrike = 2800 * UNIT;
        uint256 shortStrike = 2600 * UNIT;

        uint256 depositAmount = longStrike - shortStrike;

        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT_SPREAD, productId, expiry, longStrike, shortStrike);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        (, uint256 shortPutId,, uint64 shortPutAmount,,) = engine.marginAccounts(address(this));

        assertEq(shortPutId, tokenId);
        assertEq(shortPutAmount, amount);
    }

    function testCanMintStraddle() public {
        uint256 depositAmount = 2000 * 1e6;

        uint256 strikePrice = 3000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 callId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);
        uint256 putId = getTokenId(TokenType.PUT, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](3);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(callId, address(this), amount);
        actions[2] = createMintAction(putId, address(this), amount);
        engine.execute(address(this), actions);

        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, callId);
        assertEq(shortPutId, putId);
        assertEq(shortPutAmount, amount);
        assertEq(shortCallAmount, amount);

        assertEq(option.balanceOf(address(this), shortCallId), amount);
        assertEq(option.balanceOf(address(this), shortPutId), amount);
    }

    function testCanMintStrangle() public {
        uint256 depositAmount = 1000 * 1e6;
        uint256 amount = 1 * UNIT;

        uint256 callId = getTokenId(TokenType.CALL, productId, expiry, 4000 * UNIT, 0);
        uint256 putId = getTokenId(TokenType.PUT, productId, expiry, 2000 * UNIT, 0);

        ActionArgs[] memory actions = new ActionArgs[](3);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(callId, address(this), amount);
        actions[2] = createMintAction(putId, address(this), amount);
        engine.execute(address(this), actions);

        (uint256 shortCallId, uint256 shortPutId, uint64 shortCallAmount, uint64 shortPutAmount,,) =
            engine.marginAccounts(address(this));

        assertEq(shortCallId, callId);
        assertEq(shortPutId, putId);
        assertEq(shortPutAmount, amount);
        assertEq(shortCallAmount, amount);

        assertEq(option.balanceOf(address(this), shortCallId), amount);
        assertEq(option.balanceOf(address(this), shortPutId), amount);
    }

    function testCannotMintWithoutCollateral() public {
        uint256 strikePrice = 3000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintTwoCalls() public {
        // mint the first call
        uint256 depositAmount = 10000 * 1e6;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, productId, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        // prepare second mint
        ActionArgs[] memory action2 = new ActionArgs[](1);
        uint256 secondCallId = getTokenId(TokenType.CALL, productId, expiry, 5000 * UNIT, 0);
        action2[0] = createMintAction(secondCallId, address(this), amount);

        // expect call to revert
        vm.expectRevert(AM_InvalidToken.selector);
        engine.execute(address(this), action2);
    }
}
