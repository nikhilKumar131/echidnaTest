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
        _delay(0x214c9, 0x3920);
    _setUpActor(USER1);
        Target.readInitializeInputFull_test(1524785992, 255, 4370000, 4369999, 114430170430784426130958504194602190405664109406573290765791633858200116893748, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 86833489694592966388995464618751010877115966256183861717914771443554768364479, 1524785991, 67744915414645022144568998196235733306411196797031097809932402937575896700496);
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
