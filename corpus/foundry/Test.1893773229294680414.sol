// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x30000);

    // TODO: Replace with your actual contract instance
    ReadInitializeFullPositiveTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadInitializeFullPositiveTest();
  }

  function test_replay() public {
        _delay(0x8345, 0xea4e);
    _setUpActor(USER1);
        Target.readInitializeInputOverlapping_test(43114364573925458265981435066633791703031389939680202018818796672268202398156, 73, 3344492049363941068846317266, 1445297, 60634828538882409960915836143462193310806854096605271453197575680434769466696, 4370001, 45988196018236711410878174695345057235287511289391805302856737356989955184334, 1524785992, 1524785992);
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
