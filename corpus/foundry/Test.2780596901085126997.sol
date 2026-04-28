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
        Target.readInitializeInputOverlapping_test(0, 0, 4706017832574223384725640597448233720333494970643867376, 5095962371393209441363724855839824514746321112300259229243563, 59211567721357336470457987900794427723560202792536448533935983, 2211436760977480795362410366696230079645577533964534873920, 25079076340981507563643616758543395403537414919472198564, 115792089237316195423570985008687907853269984665640564039457584007913129639745, 2473266315804770293937674359424209772683439124468194290589);
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
