// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    ReadModifyKernelInputTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadModifyKernelInputTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.readModifyKernel_test(2200951988861329425571, 0, 0, 7207967361331919050069462, 28885817914717544207180282581065800686220);
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
