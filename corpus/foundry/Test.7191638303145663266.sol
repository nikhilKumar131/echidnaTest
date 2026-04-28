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
        Target.readInitializeInputFull_test(0, 0, 2512600609920552974204979475370746798332182686971507, 6402524218290663278773400817085681603598538301402994, 1546045604084904740630470465405210905470771924666, 0, 29850288679608631416285225446729360131624255647618201, 657110137442805837710335443158060871491892469387590, 869289180375497526118560057029178140257514404573110789);
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
