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
        Target.readInitializeInputOverlapping_test(0, 0, 2672039260501809270826952812964169618972196, 346138308127436415073850145486425885662418073147019, 92205706001817928329965494649020780526909829431, 10985459375064130737312884070434578918548251, 2921455445887954264251124348816527415955431, 115792089237316195423570985008687907853269984665640564039457584007913129639745, 1890430641629184223073459299597627619359397713039);
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
