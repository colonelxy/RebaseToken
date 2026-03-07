// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "@forge-test/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken public token;

    uint256 constant INITIAL_RATE = 5e10;

    function setUp() public {
        token = new RebaseToken();
    }

    /* //////////////////////////////////////////////////////////////
       mint() tests
    ////////////////////////////////////////////////////////////// */

    function testMintIncreasesBalance() public {
        address recipient = address(0xABCD);
        uint256 amount = 1e18;

        token.mint(recipient, amount);
        assertEq(token.balanceOf(recipient), amount);
    }

    function testFuzz_Mint(address to, uint256 amount) public {
        // avoid minting to the zero address in fuzz (though contract allows it)
        vm.assume(to != address(0));
        token.mint(to, amount);
        assertEq(token.balanceOf(to), amount);
    }

    /* //////////////////////////////////////////////////////////////
       setInterestRate() tests
    ////////////////////////////////////////////////////////////// */

    function test_SetInterestRate_canDecrease() public {
        // initial rate should match the constant defined in the contract
        assertEq(token.interestRate(), INITIAL_RATE);

        uint256 newRate = INITIAL_RATE - 1;

        // expect the event with the correct value to be emitted
        vm.expectEmit(true, false, false, true);
        emit RebaseToken.interestRateSet(newRate);

        token.setInterestRate(newRate);
        assertEq(token.interestRate(), newRate);
    }

    function testRevert_SetInterestRate_cannotIncrease() public {
        uint256 higher = INITIAL_RATE + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                RebaseToken.RebaseToken__interestRateCanOnlyDecrease.selector,
                INITIAL_RATE,
                higher
            )
        );
        token.setInterestRate(higher);
    }

    function test_SetInterestRate_canSetEqual() public {
        // setting to the same value should not revert and leave rate unchanged
        token.setInterestRate(INITIAL_RATE);
        assertEq(token.interestRate(), INITIAL_RATE);
    }

    function testFuzz_SetInterestRate_canDecrease(uint256 delta) public {
        // ensure delta is non-zero and less than INITIAL_RATE
        vm.assume(delta > 0 && delta < INITIAL_RATE);
        uint256 newRate = INITIAL_RATE - delta;
        vm.expectEmit(true, false, false, true);
        emit RebaseToken.interestRateSet(newRate);
        token.setInterestRate(newRate);
        assertEq(token.interestRate(), newRate);
    }

    function testFuzz_SetInterestRate_cannotIncrease(uint256 higher) public {
        vm.assume(higher > INITIAL_RATE);
        vm.expectRevert(
            abi.encodeWithSelector(
                RebaseToken.RebaseToken__interestRateCanOnlyDecrease.selector,
                INITIAL_RATE,
                higher
            )
        );
        token.setInterestRate(higher);
    }
}
