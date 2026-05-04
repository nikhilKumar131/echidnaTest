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
        Target.readDonateInput_test(50155081088946301622697201122604608983048605736389267633590715373593504794174, 172, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 28475097061097998362564722045887858615258107517385447134834258515036381526389, 115792089237316195423570985008687907853269984665640564039457584007913129639844);
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
