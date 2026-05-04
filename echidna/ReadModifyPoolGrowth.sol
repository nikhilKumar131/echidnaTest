// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _poolId_,
  _kernel_,
  _shares_,
  _curve_, _poolGrowthPortion_,
  _hookData_, _hookDataByteCount_, _hookInputByteCount_,
  _freeMemoryPointer_,
  _endOfStaticParams_
} from "../contracts/utilities/Memory.sol";

import "../contracts/utilities/Calldata.sol";
import {CallDataTestCommonUtilities,ReadModifyPoolGrowthPortionTestUtilities, ReadCollectInputTestUtilities} from "./CallDataUtility.sol";

contract CallDataWrapper{

    function _readModifyPoolGrowthPortion() public view returns(
        ReadModifyPoolGrowthPortionTestUtilities.returnedValues memory returnedValues
    ){

        readModifyPoolGrowthPortionInput();

        uint256 poolId;
        uint256 poolGrowthPortion;
        uint256 hookInputByteCount;
        uint256 freeMemoryPointer;

        assembly{

            poolId := mload(_poolId_)
            poolGrowthPortion := shr(208, mload(_poolGrowthPortion_))
            hookInputByteCount := mload(_hookInputByteCount_)
            freeMemoryPointer := mload(_freeMemoryPointer_)

        }

        returnedValues.poolId = poolId;
        returnedValues.poolGrowthPortion = poolGrowthPortion;
        returnedValues.hookInputByteCount = hookInputByteCount;
        returnedValues.freeMemoryPointer = freeMemoryPointer;

    }


    function _readUpdateGrowthPortionInput() public view returns(
      ReadModifyPoolGrowthPortionTestUtilities.returnedValues memory returnedValues
    ){

      readUpdateGrowthPortionsInput();

      uint256 poolId;
      uint256 hookInputByteCount;
      uint256 freeMemoryPointer;
      assembly{
        poolId := mload(_poolId_)
        hookInputByteCount := mload(_hookInputByteCount_)
        freeMemoryPointer := mload(_freeMemoryPointer_)
      }

      returnedValues.poolId = poolId;
      returnedValues.hookInputByteCount = hookInputByteCount;
      returnedValues.freeMemoryPointer = freeMemoryPointer;

    }

    function _readCollectInput() public view returns(
      ReadCollectInputTestUtilities.returnedValues memory ReturnedValues
    ) {
      readCollectInput();

      uint256 poolId;
      uint256 freeMemoryPointer;

      assembly{
        poolId := mload(_poolId_)
        freeMemoryPointer := mload(_freeMemoryPointer_)
      }

      ReturnedValues.poolId = poolId;
      ReturnedValues.freeMemoryPointer = freeMemoryPointer;

    }

}

contract ReadModifyPoolGrowthPortionTest{

    //wrapper instance
    CallDataWrapper wrapper;

    constructor(){
      wrapper = new CallDataWrapper();
    }



    function ReadModifyPoolGrowthPortion_test(
      uint256 poolIdSeed,
      uint8 offsetSeed,
      uint256 poolGrowthPortionSeed
    ) public {

      ( uint256 poolId,
        uint256 poolGrowthPortion) = ReadModifyPoolGrowthPortionTestUtilities.genrateValues(poolIdSeed, offsetSeed, poolGrowthPortionSeed);
    
      bytes memory payload = abi.encodePacked(
        wrapper._readModifyPoolGrowthPortion.selector,
        poolId,
        poolGrowthPortion
      );

      (bool success, bytes memory returnedValues) = address(wrapper).call(payload);
      assert(success);

      ReadModifyPoolGrowthPortionTestUtilities.returnedValues memory ReturnedValues;

      (
        ReturnedValues.poolId,
        ReturnedValues.poolGrowthPortion,
        ReturnedValues.hookInputByteCount,
        ReturnedValues.freeMemoryPointer
      ) = abi.decode(returnedValues, (uint256,uint256,uint256,uint256));

      assert(poolId == ReturnedValues.poolId);
      assert(poolGrowthPortion == ReturnedValues.poolGrowthPortion);

      uint256 hookInputByteCount = _endOfStaticParams_ - _hookInputByteCount_ - 32;
      uint256 freeMemoryPointer = _endOfStaticParams_;

      assert(hookInputByteCount == ReturnedValues.hookInputByteCount);
      assert(freeMemoryPointer == ReturnedValues.freeMemoryPointer);


    }

    function ReadModifyPoolGrowthPortion_Negitive_test(
      uint256 poolIdSeed,
      uint8 offsetSeed,
      uint256 poolGrowthPortionSeed
    ) public {

      ( uint256 poolId,
        uint256 poolGrowthPortion) = ReadModifyPoolGrowthPortionTestUtilities.genrateValues(poolIdSeed, offsetSeed, poolGrowthPortionSeed);
    
      poolGrowthPortion = CallDataTestCommonUtilities.makeInvalidPortion(poolGrowthPortionSeed);
      bytes memory payload = abi.encodePacked(
        wrapper._readModifyPoolGrowthPortion.selector,
        poolId,
        poolGrowthPortion
      );

      (bool success, ) = address(wrapper).call(payload);

      assert(!success);

    }

}

contract ReadUpdateGrowthPortionInputTest{

  //wrapper instance
  CallDataWrapper wrapper;

  constructor(){
    wrapper = new CallDataWrapper();
  }

  struct returnedValues{
    uint256 poolId;
    uint256 hookInputByteCount;
    uint256 freeMemoryPointer;
  }

  function readUpdateGrowthPortionInput_test(
    uint256 poolIdSeed,
    uint8 OffsetSeed
  ) public {

    uint256 poolId = CallDataTestCommonUtilities.makeValidPoolId(poolIdSeed,OffsetSeed);

    bytes memory payload = abi.encodePacked(
      wrapper._readUpdateGrowthPortionInput.selector,
      poolId
    );

    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(success);

    returnedValues memory ReturnedValues;

    uint256 unusedPoolGrowthPortion;
    (
      ReturnedValues.poolId,
      unusedPoolGrowthPortion,
      ReturnedValues.hookInputByteCount,
      ReturnedValues.freeMemoryPointer
    ) = abi.decode(returnData, (uint256,uint256,uint256,uint256));

    assert(poolId == ReturnedValues.poolId);

    uint256 hookInputByteCount = _endOfStaticParams_ - _hookInputByteCount_ - 32;
    uint256 freeMemoryPointer = _endOfStaticParams_;

    assert(hookInputByteCount == ReturnedValues.hookInputByteCount);
    assert(freeMemoryPointer == ReturnedValues.freeMemoryPointer);

  }



}

contract ReadCollectInputTest{

  //wrapper instance
  CallDataWrapper wrapper;

  constructor(){
    wrapper = new CallDataWrapper();
  }

  function readCollectInput_test(
    uint256 poolIdSeed,
    uint8 offSetSeed
  ) public {


  uint256 poolId = CallDataTestCommonUtilities.makeValidPoolId(poolIdSeed,offSetSeed);

  bytes memory payload = abi.encodePacked(
    wrapper._readCollectInput.selector,
    poolId
  );

  (bool success, bytes memory returnData) = address(wrapper).call(payload);

  assert(success);

  }



}