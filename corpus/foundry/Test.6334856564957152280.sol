// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x20000);

    // TODO: Replace with your actual contract instance
    ReadInitializeFullPositiveTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadInitializeFullPositiveTest();
  }

  function test_replay() public {
        _delay(0x82c11, 0x619b);
    _setUpActor(USER1);
        Target.overlap_test(19052097476079753389789281443376718481098890349303806780350533463410843543409, 253, 4370001, 75039498994990049452307408278621643408066872724028503740978452690213381980623, 1524785993, 20726345664053498051428067335068211901841636882311662056707431596057850440302, 20151195030594221010760986833823707867948995904177845304135319933088617030647, 93203530993144512330918787167617957193787970618253482606800764537030451734472, 1524785992);
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
