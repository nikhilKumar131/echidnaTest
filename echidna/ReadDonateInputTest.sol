// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import "../contracts/utilities/Calldata.sol";
import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _poolId_,
  _shares_,
  _curve_,
  _hookData_, _hookDataByteCount_, _hookInputByteCount_,
  _freeMemoryPointer_,
  _endOfStaticParams_
} from "../contracts/utilities/Memory.sol";


import {writeStorage} from "../contracts/utilities/Storage.sol";


// import showing stack too deep, so copied reqired3 functions as of now
// import {ReadInitializeInputTestUtils} from "./ReadInitializePositiveAssertionTest.sol";

contract CallDataWrapper{


  function _readDonateInput() public view returns(
    ReadDonateHelper.returnedValues memory returnedValues
  ){
    readDonateInput();

    uint256 poolId;
    uint256 shares;
    uint256 curve;
    uint256 hookDataPlacement;
    uint256 freeMemoryPointer;
    uint256 hookDataByteCount;
    uint256 hookInputByteCount;
    bytes32 hashedHookData;


    assembly{
      poolId := mload(_poolId_)
      shares := mload(_shares_)
      curve := mload(_curve_)
      hookDataPlacement := mload(_hookData_)
      freeMemoryPointer := mload(_freeMemoryPointer_)
      hookDataByteCount := shr(240, mload(_hookDataByteCount_))
      hookInputByteCount := mload(_hookInputByteCount_)

      hashedHookData := keccak256(hookDataPlacement, hookDataByteCount)

    }


    ( returnedValues.poolId,
      returnedValues.shares,
      returnedValues.curve,
      returnedValues.hookDataPlacement,
      returnedValues.freeMemoryPointer,
      returnedValues.hookDataByteCount,
      returnedValues.hookInputByteCount,
      returnedValues.hashedHookData) = (poolId, shares, curve, hookDataPlacement, freeMemoryPointer, hookDataByteCount, hookInputByteCount, hashedHookData);

  }

}

library ReadDonateHelper{

  //COPIED FUNCTION FROM READiNITALIZEPOSITIVEASSERTIONTEST.SOL
    //Generates a valid poolId with offset in the range of [-89, 89]
  function makeValidPoolId(uint256 x, uint8 offsetSeed) internal pure returns (uint256 poolId) {

    // Two's-complement 8-bit offsets in the valid range [-89, +89] correspond to unsigned byte values [167, 255] and [0, 89].
    // we can use a double module to cover both sides of the valid range without branching:
    // offsetSeed % 90 gives us a value in [0, 89], and (offsetSeed % 90) + 167 gives us a value in [167, 256).
    // offsetSeed % 180 gives us a value in [0, 179], which we can then map to the valid ranges by adding 167 and taking modulo 256.
    uint8 validByte = uint8((offsetSeed % 180) < 90 ? (offsetSeed % 90) : ((offsetSeed % 90) + 167));

    // Clear bits [187:180] then plant the valid byte.
    uint256 mask = uint256(0xFF) << 180;
    poolId = (x & ~mask) | (uint256(validByte) << 180);
  }


  //Generates a valid hookBytes
  //@params seed: a random uint256 value
  //seed is used to generate valid hookLength in range [2, type(int16).max(65535)]
  //@returns: a bytes value representing valid hookBytes
  function makeValidHookDataBytes(uint256 seed) internal pure returns (bytes memory) {
    uint256 hookDataByteCount = seed % 1021; // valid range [0, 65535] , but reasonalbe range is [[2, 1020]]
    uint256 numWords = (hookDataByteCount + 31) / 32;

    uint256[] memory words = new uint256[](numWords);
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(seed, i)));
    }

    return abi.encodePacked(hookDataByteCount, words);
  }

  //Generates random gap value in range [0, 200]
  function makeRandomGap(uint256 seed) internal pure returns (uint256) {
    return seed % 201;
  }

    //INVALID VALUES GENERATORS
  //inalid poolid generator
  function makeInvalidPoolId(
      uint256 x,
      uint8 offsetSeed
  ) internal pure returns (uint256 poolId) {
      // Two's-complement 8-bit offsets outside [-89, +89] are invalid.
      // In unsigned byte terms, invalid values occupy [90, 166]:
      //   [90,  127] → signed +90 to +127  (too positive)
      //   [128, 166] → signed -128 to -90  (too negative)
      // That is exactly 77 contiguous values, so a simple modulo covers both
      // invalid sides without needing two separate branches.
      uint8 invalidByte = uint8(90 + (uint256(offsetSeed) % 77));

      // Clear bits [187:180] then plant the invalid byte.
      uint256 mask = uint256(0xFF) << 180;
      poolId = (x & ~mask) | (uint256(invalidByte) << 180);
  }

  // //generates long hook data bytes 
  // function makeLongHookData(uint256 seed) internal pure returns (bytes memory) {
  //   // valid range is [0, 2^16), so anything >= 2^16 is invalid
  //   uint256 value = (1 << 16) + (seed % (type(uint256).max - ((1 << 16)+1)));
  //   return abi.encodePacked(value);
  // }



  //NEW FUNCTIONS

  //struct to return values from callDataWrapper._readDonateInput()
  struct returnedValues {
    uint256 poolId;
    uint256 shares;
    uint256 curve;
    uint256 hookDataPlacement;
    uint256 freeMemoryPointer;
    uint256 hookDataByteCount;
    uint256 hookInputByteCount;
    bytes32 hashedHookData;
  }

  //range [1,type(int128).max]
  function makeValidSharesforDonate(uint256 seed) internal pure returns(uint256 shares){
    shares = 1 + (seed % uint256(int256((type(int128).max) ))); // range [1,type(int128).max]
  }

  function makeInvalidSharesforDonate(uint256 seed) internal pure returns(uint256 shares){
    shares = 1 + uint256(int256((type(int128).max))) + (seed % uint256(int256((type(int128).max) ))); // range [type(int128).max + 1,]
  }

  function outputGenerator(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) internal pure returns(
    uint256 poolId,
    uint256 shares,
    bytes memory hookDataBytes,
    uint256 gap
  ) {
    poolId = makeValidPoolId(poolIdSeed,offsetSeed);
    shares = makeValidSharesforDonate(sharesSeed);
    hookDataBytes = makeValidHookDataBytes(hookDataByteSeed);
    gap = makeRandomGap(gapSeed);
  }

  //payloadGenerator
  function payloadGenerator(CallDataWrapper wrapper, uint256 poolId, uint256 shares, bytes memory hookDataBytes, uint256 gap ) internal pure returns(bytes memory payload){

    uint256 startHookData = 3 * 32 + gap;

    payload = abi.encodePacked(
      wrapper._readDonateInput.selector,
      poolId,
      shares,
      startHookData,
      new bytes(gap), hookDataBytes
    );
  }

}

contract ReadDonateInputTest {

  CallDataWrapper wrapper;

  constructor(){
    wrapper = new CallDataWrapper();
  }

  function readDonateInput_test(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public{

    //generateOutputs
    (
      uint256 poolId,
      uint256 shares,
      bytes memory hookDataBytes,
      uint256 gap
    ) = ReadDonateHelper.outputGenerator(poolIdSeed, offsetSeed, sharesSeed, hookDataByteSeed, gapSeed);


    //create payload
    bytes memory payload = ReadDonateHelper.payloadGenerator(wrapper, poolId, shares, hookDataBytes, gap);


    //pass the payload
    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(success);

    //decode returnData
    ( uint256 returnedPoolId,
      uint256 returnedShares,
      uint256 returnedCurve,
      uint256 returnedHookDataPlacement,
      uint256 returnedFreeMemoryPointer,
      uint256 returnedHookDataByteCount,
      uint256 returnedHookInputByteCount,
      bytes32 returnedHashedHookData) = abi.decode(returnData, (uint256,uint256,uint256,uint256,uint256,uint256,uint256, bytes32));

    //assert poolId, shares
    //poolId:: expected: poolId; returedPoolId: returned.poolId
    assert(poolId == returnedPoolId);
    assert(shares == returnedShares);

    //calculating values and offsets
    uint256 curvePlacement = _endOfStaticParams_;
    uint256 hookDataPlacement = curvePlacement + 32;

    uint256 hookDataByteCount = hookDataByteSeed % 1021; //internal logic of makeValidHookDataBytes
    uint256 hookInputByteCount = _endOfStaticParams_ + 32 + hookDataByteCount - _hookInputByteCount_ - 32;
    uint256 freeMemoryPointer = hookDataPlacement + hookDataByteCount;


    assert(curvePlacement == returnedCurve);
    assert(hookDataPlacement == returnedHookDataPlacement);
    assert(hookDataByteCount == returnedHookDataByteCount);
    assert(hookInputByteCount == returnedHookInputByteCount);
    assert(freeMemoryPointer == returnedFreeMemoryPointer);
    
    bytes32 hashedHookDataBytes;
    assembly {
        // add(hookDataBytes, 64): skip Solidity length slot (32) + hookDataByteCount prefix (32)
        hashedHookDataBytes := keccak256(add(hookDataBytes, 64), hookDataByteCount)
    }
    assert(hashedHookDataBytes == returnedHashedHookData);

  }


  //TEST FAILS
  //it allows invalid poolIds to be stored, no valid checks for it
  function readDonateInput_invalidPoolId_test(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public{

    //generateOutputs
    (
      uint256 poolId,
      uint256 shares,
      bytes memory hookDataBytes,
      uint256 gap
    ) = ReadDonateHelper.outputGenerator(poolIdSeed, offsetSeed, sharesSeed, hookDataByteSeed, gapSeed);

    uint256 invalidPoolId = ReadDonateHelper.makeInvalidPoolId(poolIdSeed, offsetSeed);
    //create payload
    bytes memory payload = ReadDonateHelper.payloadGenerator(wrapper, invalidPoolId, shares, hookDataBytes, gap);


    //pass the payload
    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(!success);

  }


  //edgeCase: shares = 0 is missing
  //covered in next test
  function readDonateInput_invalidShares_test(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public{

    //generateOutputs
    (
      uint256 poolId,
      uint256 shares,
      bytes memory hookDataBytes,
      uint256 gap
    ) = ReadDonateHelper.outputGenerator(poolIdSeed, offsetSeed, sharesSeed, hookDataByteSeed, gapSeed);

    //create payload
    uint256 invalidShares = ReadDonateHelper.makeInvalidSharesforDonate(sharesSeed);
    bytes memory payload = ReadDonateHelper.payloadGenerator(wrapper, poolId, invalidShares, hookDataBytes, gap);


    //pass the payload
    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(!success);

  }


  function readDonateInput_ZeroShares_test(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public{

    //generateOutputs
    (
      uint256 poolId,
      uint256 shares,
      bytes memory hookDataBytes,
      uint256 gap
    ) = ReadDonateHelper.outputGenerator(poolIdSeed, offsetSeed, sharesSeed, hookDataByteSeed, gapSeed);

    //create payload
    uint256 zeroShares = 0;
    bytes memory payload = ReadDonateHelper.payloadGenerator(wrapper, poolId, zeroShares, hookDataBytes, gap);


    //pass the payload
    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(!success);

  }



  function readDonateInput_ZtooLongHookData_test(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 sharesSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public{

    //generateOutputs
    (
      uint256 poolId,
      uint256 shares,
      bytes memory hookDataBytes,
      uint256 gap
    ) = ReadDonateHelper.outputGenerator(poolIdSeed, offsetSeed, sharesSeed, hookDataByteSeed, gapSeed);


    //manually substituting hookDataBytes with long hook data to make it invalid
    uint256 numWords = (65664) / 32;
    uint256[] memory words = new uint256[](numWords);
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(uint256(65664), i)));
    }
    bytes memory longHookData = abi.encodePacked(uint256(65664), words); 

    //create payload
    bytes memory payload = ReadDonateHelper.payloadGenerator(wrapper, poolId, shares, longHookData, gap);


    //pass the payload
    (bool success, bytes memory returnData) = address(wrapper).call(payload);

    assert(!success);

  }


}