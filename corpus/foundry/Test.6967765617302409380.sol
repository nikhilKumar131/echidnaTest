// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    Test Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new Test();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.test_tagsOutOfOrder_reverts(0, 0, 310189559095896575480724710646079050506713940088110912326014432790275, 0, 85584998951, 0);
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
