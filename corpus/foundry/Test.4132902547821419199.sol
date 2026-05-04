// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    ReadDonateInputTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadDonateInputTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.readDonateInput_test(779569342956602012422523184441113812237696460257090003910, 0, 733067348297375215558980104329625648272098284676801395915, 69991842927260208080230462303200419855540615368, 5131532844471308727964266487628137018387626148778799000);
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
