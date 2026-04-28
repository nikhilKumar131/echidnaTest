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
        Target.readInitializeInputFull_test(7, 11, 61736695971364270367142327894957152918585667776715688715847848281961494745528, 297748787204267478996529137403980502140654479185968580056022465248155717099, 1631548738015819461049522323173388313538817946555405471938226247521918818265, 2, 43704724392629304876684732533246930218569189236070080046163135325610939602533, 1993171303590940547217667726928404835730640662029563598225264717332702302293, 19235625867238566288375976758558362528036957498634444051604802238509811533097);
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
