// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    ReadInitializeFullPositiveTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadInitializeFullPositiveTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.overlap_test(499639267897096629454416873542296778210352002, 0, 0, 253301955471507948395539988073649958499616191708807, 0, 2470802689634475967554145886858892323165986021027991, 37983463198447181092649806820263399020072693522500, 218823866189068481071674928569654602112881645, 0);
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
