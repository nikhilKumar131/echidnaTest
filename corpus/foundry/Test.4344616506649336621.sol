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
        Target.readInitializeInputFull_test(0, 0, 0, 0, 29127024937270803606945601807761525355314196832607010746357204933, 8802652951259136926486195462150250547964878963425004617256913720, 2013886002944882497254155052847789175347715652320225692643033783, 0, 15548330342669806564182657674649549548453292664118260265675812038612);
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
