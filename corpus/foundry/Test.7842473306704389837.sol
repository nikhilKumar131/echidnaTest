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
        Target.readInitializeInputFull_test(0, 0, 22404437053786698271109198883945489278831042991987756598312248978725088, 1980460941946484557485848458334311045105984601399801575445768099618, 89266110017015790591638689762641517540273862278305998826963871294731153, 0, 498375042809821955745832242288993864104471623789516087184807210861295460, 283752775731265651022859210830378640460484313411895075142557824976443769, 14628602095209310499130216412564847537087396516500406301747772990654632);
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
