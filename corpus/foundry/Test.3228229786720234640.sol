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
        Target.readInitializeInputOverlapping_test(11204457964426807301417016890016743146394952156929287179483323815555627634744, 3, 18369220308178722034738485394573884782714848367283685610167294139129600928160, 87513051049273211207175097137142547515188972277145620412363218462831015769983, 12205493, 10457740380262187590933345906637582528914923338780864142909813266265061591442, 409, 81527555772619368052057730649574441215736376202242686833855797347818589775207, 183157542);
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
