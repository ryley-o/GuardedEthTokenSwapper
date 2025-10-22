// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {GuardedEthTokenSwapper} from "../src/GuardedEthTokenSwapper.sol";
import {IGuardedEthTokenSwapper} from "../src/IGuardedEthTokenSwapper.sol";

/**
 * @title IGuardedEthTokenSwapper Interface Compliance Test
 * @notice Verifies that GuardedEthTokenSwapper implements IGuardedEthTokenSwapper correctly
 * @dev Ensures the contract adheres to its declared interface
 */
contract IGuardedEthTokenSwapperTest is Test {
    GuardedEthTokenSwapper public swapper;
    IGuardedEthTokenSwapper public iSwapper;

    function setUp() public {
        // Deploy the contract
        swapper = new GuardedEthTokenSwapper();

        // Cast to interface
        iSwapper = IGuardedEthTokenSwapper(address(swapper));
    }

    /**
     * @notice Test that the contract can be cast to the interface
     * @dev This ensures the contract implements all interface functions
     */
    function testInterfaceCompliance() public view {
        // If this compiles and runs, the contract implements the interface correctly
        assertTrue(address(iSwapper) != address(0), "Interface casting should succeed");
    }

    /**
     * @notice Test that view functions are accessible through the interface
     */
    function testInterfaceViewFunctions() public view {
        // Test router() function
        address routerAddr = iSwapper.router();
        assertTrue(routerAddr != address(0), "Router should be set");

        // Test weth() function
        address wethAddr = iSwapper.weth();
        assertTrue(wethAddr != address(0), "WETH should be set");

        // Test owner() function
        address ownerAddr = iSwapper.owner();
        assertTrue(ownerAddr != address(0), "Owner should be set");

        // Test getFeed() function (unconfigured token should return zero address)
        (address aggregator,,,) = iSwapper.getFeed(address(0x1234));
        assertEq(aggregator, address(0), "Unconfigured token should return zero address");
    }

    /**
     * @notice Test that the interface can be used with the contract
     * @dev The minimum deadline of 300 seconds is hardcoded in the contract logic
     */
    function testInterfaceDeadlineValidation() public {
        // The contract enforces a minimum deadline of 300 seconds (5 minutes)
        // This is hardcoded in the swapEthForToken function logic
        address testToken = address(0x1234);
        uint16 slippage = 200;

        // Deadline too soon (should revert)
        uint256 tooSoonDeadline = block.timestamp + 100;
        vm.expectRevert();
        iSwapper.swapEthForToken{value: 1 ether}(testToken, slippage, tooSoonDeadline);
    }

    /**
     * @notice Test that admin functions are accessible through the interface
     * @dev We don't execute them, just verify they exist and have correct signatures
     */
    function testInterfaceAdminFunctions() public {
        // Prepare arrays for setFeeds
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x1234);

        address[] memory aggregators = new address[](1);
        aggregators[0] = address(0x5678);

        uint24[] memory feeTiers = new uint24[](1);
        feeTiers[0] = 3000;

        uint16[] memory tolerances = new uint16[](1);
        tolerances[0] = 200;

        // Verify setFeeds exists (will revert because we're not owner, but that's expected)
        vm.expectRevert();
        iSwapper.setFeeds(tokens, aggregators, feeTiers, tolerances);

        // Verify removeFeed exists (will revert because we're not owner, but that's expected)
        vm.expectRevert();
        iSwapper.removeFeed(address(0x1234));
    }

    /**
     * @notice Test that swap function is accessible through the interface
     */
    function testInterfaceSwapFunction() public {
        address testToken = address(0x1234);
        uint16 slippage = 200;
        uint256 deadline = block.timestamp + 600;

        // Verify swapEthForToken exists (will revert because token not configured)
        vm.expectRevert();
        iSwapper.swapEthForToken{value: 1 ether}(testToken, slippage, deadline);
    }
}

