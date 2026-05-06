// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);
    address constant USER2 = address(0x30000);
    address constant USER3 = address(0x20000);

    // TODO: Replace with your actual contract instance
    Test Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new Test();
  }

  function test_replay() public {
        _delay(0x63, 0x1d);
    _setUpActor(USER1);
        Target.test_invalidCurve_badArrangement(5595139080810230562404105774314004388806159841293663252541933686432228056219, 86, 115792089237265596158433357922891642550906346137612344911589351427115159912451, 1161, 4884309058641270063, 6315945929402325708);
        _delay(0x2a683, 0x154c);
    _setUpActor(USER2);
        Target.test_invalidCurve_badArrangement(75569795497173259817525610347536314515477380385809807515853300546672356810944, 160, 478, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 192, 12207075126965881043);
        _delay(0xf1b9, 0xa2);
    _setUpActor(USER3);
        Target.test_invalidFlags_reverts(115792089237316195423570985008687907853269984665640564039457584007913129623553, 98, 62196213590547893327820810232, 36907983979297629146094553906065036904468349449175584341237463116816891995219, 13964907619501364215, 1001);
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
