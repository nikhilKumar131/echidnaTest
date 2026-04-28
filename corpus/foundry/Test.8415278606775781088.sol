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
        Target.readInitializeInputOverlapping_test(1, 0, 270105850319070340453445103362844634976402802217622340042028491989592782223, 115773120376856259594657627333970176374423620502448333377715860878441626904, 1040021005376225204267464961554314822048701696680621685950044927522349505584, 148847092902520413604007522703682199779612743494701458583303034855156, 1142933088843376999910071395508971785537465424360990262856855037928509834, 115792089237316195423570985008687907853269984665640564039457584007913129639745, 17082001137756263652896762629263390031634316018480362492330439973805003283);
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
