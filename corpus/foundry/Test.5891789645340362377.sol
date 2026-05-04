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
        Target.readDonateInput_test(57481253164843384326282094634785289010517575461659667427413677958745254231, 22, 7513698989313117269524295715637289321668364324810586039841503126143209816395, 1412044898254468616554163316977706556074005052539164920765867094531910943728, 54461157464173949117183052069904663201718395216106325757805785682873295318);
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
