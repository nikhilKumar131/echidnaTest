// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    ReadInitializePositiveAssertionTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new ReadInitializePositiveAssertionTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.readInitializeInputHookBytesTooLong_test(316720346280191281713480291595541894437162747532074155746138383360762953350, 0, 261694666525894886313264590030061761276841697944109293750696310222243193, 199987503614454245112852060998242586906535583745090605516504956364065013348, 25304277717446639063686013913099558861166319829705105089532865422378497773, 171534306579363488867932100138958364713938090476282955094255838574858394, 119695314681479490983314985557072837241199430568427564668316880590229421886, 0, 40206222605520526912890518586090805054574744775227820869928823470364172);
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
