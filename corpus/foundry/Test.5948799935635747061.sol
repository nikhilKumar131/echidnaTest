// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    ReadInitializePositiveAssertionTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadInitializePositiveAssertionTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.readInitializeInput_test1(28, 114, 98398397498105479609944821468249515230823150623603040146611165179580839496831, 0, 32919753992580551885683209098055581913860284181777124440994737298703623182619, 178, 115792089237316195423570985008687907853269984665640564039457584007913129637878, 115792089237316195423570985008687907853269984665640564039457584007913129639801, 347);
  }

  function _setUpActor(address actor) internal {
      vm.startPrank(actor);
      // Add any additional actor setup here if needed
  }

  function _delay(uint256 timeInSeconds, uint256 numBlocks) internal {
      vm.warp(block.timestamp + timeInSeconds);
      vm.roll(block.number + numBlocks);
  }
}
