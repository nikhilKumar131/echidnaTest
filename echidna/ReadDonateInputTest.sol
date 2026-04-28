// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import "../contracts/utilities/Calldata.sol";
import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _hookInputByteCount_
} from "../contracts/utilities/Memory.sol";
import {writeStorage} from "../contracts/utilities/Storage.sol";

import {ReadInitializeInputTestUtils} from "./ReadInitializePositiveAssertionTest.sol";

contract CallDataWrapper{

  function _readDonateInput() public view returns(
    uint256 freeMemoryPointer
  ){
    readDonateInput();
    freeMemoryPointer = getFreeMemoryPointer();
  }

}

library ReadDonateHelper{

  function inputsGenerator(
    uint256 poolIdSeed,
    uint256 sharesSeed,
    uint256 hookDataByteCountSeed,
    uint256 gapSeed
  ) internal view returns(
    uint256 poolId,
    uint256 shares,
    uint256 hookDataBytesCount,
    uint256 gap
  ) {

  }

}

contract ReadDonateInputTest {

  CallDataWrapper wrapper;

  constructor(){
    wrapper = new CallDataWrapper();
  }

  function readDonateInput_test(
    uint256 poolIdSeed,
    uint256 sharesSeed,
    uint256 hookDataByteCountSeed,
    uint256 gapSeed
  ) public{


    assert(true);
  }


}