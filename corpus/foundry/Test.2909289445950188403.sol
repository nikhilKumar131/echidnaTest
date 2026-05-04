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
        Target.readDonateInput_test(38810979664343224566933638937473563942198185733, 0, 3433845551389743384435091810544958523363882439944857641, 2094661052615571547885437126184870742490404663623, 1899474157355784498510174250776076075951737208929364);
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
