// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x30000);
    address constant USER2 = address(0x20000);

    // TODO: Replace with your actual contract instance
    Test Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new Test();
  }

  function test_replay() public {
        _delay(0x47f6f, 0x1016);
    _setUpActor(USER1);
        Target.test_tagsOutOfOrder_reverts(94395214460670369543594187729174703951525173556540186714835775550219099061459, 153, 82823483259330566341726969020194151393068117192163930938052618763581972068200, 30892511599381789847932943513361919974564377777661082398038961505003763788468, 11574564515034550202, 582);
        _delay(0x28928, 0xca2f);
    _setUpActor(USER2);
        Target.test_invalidPortion_reverts(36536142610428209983392283023010578, 251, 4294967293, 68494349981222998471548114704262808883078303195863998054979869980615042162848, 115792089237316195423570985008687907853269984665640564039457584007913129377791, 9784124419972534087, 2010);
        _delay(0x1c7, 0xd8ac);
    _setUpActor(USER2);
        Target.test_cannotInitializeTwice(86844066927987146567678238756515930889952488499230423029593188005934847229949, 48, 6161747338304106955257465821691334313098241056030328892508496239771996998666, 28483696358800291480672082191597349, 7664155719495884212, 16383);
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
