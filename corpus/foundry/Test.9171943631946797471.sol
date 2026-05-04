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
        Target.readDonateInput_test(41237475032023452043632968044, 0, 239936772060261730235649468352605, 9891970609407567898156116360533341, 1357473338067654017367609633);
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
