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
        Target.readInitializeInputHookBytesTooLong_test(59425137134965204414093384443671646608291378235479546860778447175088999613, 0, 37725364717869837671075835206048095667602140732570710424931586771915192, 35238173176030438365431768247121157454880760296364401175406993116363371269, 13238293162191466938992427230234594132573275476463542538912872693580719059, 4412713154938301268206109306365015220334062627488751546935816121345750, 9086896361182455226806171653122808585962682065928054640433119959545255388, 0, 6889447802064595671875497577311210861880796697124437026988545261576590);
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
