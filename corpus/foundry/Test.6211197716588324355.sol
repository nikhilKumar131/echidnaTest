// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    InitializeTest Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new InitializeTest();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.test_initializeSuccess(6224887992290160144475087412024225575937757291024383216985654627962458800, 1, 1613344808079094871527219637102560839942182540263196605516572127710348177, 8311278279729406466102432108355587520697600754010389462567881169543052279, 7, 1338562673711645, 23911, 9359419617948780095);
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
