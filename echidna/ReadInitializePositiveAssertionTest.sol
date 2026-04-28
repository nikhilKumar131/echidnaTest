// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import {CalldataWrapper} from "../contracts/helpers/CalldataWrapper.sol";

import "../contracts/utilities/Calldata.sol";
import {
  _poolId_, _tag0_, _tag1_, _poolGrowthPortion_,
  _sqrtOffset_, _sqrtInverseOffset_,
  _kernel_, _curve_, _hookData_,
  _hookDataByteCount_, _hookInputByteCount_,
  _freeMemoryPointer_, _msgSender_, _endOfStaticParams_,
  getCurve, getHookData, getFreeMemoryPointer, getHookDataByteCount
} from "../contracts/utilities/Memory.sol";
import {Curve} from "../contracts/utilities/Curve.sol";
import {KernelCompact} from "../contracts/utilities/KernelCompact.sol";



//this library provides helper functions and utility functios
library ReadInitializeInputTestUtils{

  struct hashedBytes{
    bytes32 curveHash;
    bytes32 kernelHash;
    bytes32 hookDataHash;
  }

  //helper functions

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

  //Generates valid tags, such that tag0 < tag1
  //both tags are uint256 in range
  function makeValidTags(uint256 seedTag0, uint256 seedTag1) internal pure returns (uint256 tag0, uint256 tag1) {

    //case of both tags being equal, we can simply add 1 to tag1 to ensure tag0 < tag1
    if(seedTag0 == seedTag1){
      //a workaround to avoid overflow in case tags == 2^256 - 1
      (tag0, tag1) = seedTag0 == 0 ? (seedTag0, seedTag1 + 1) : (seedTag1 - 1, seedTag0 );
    }
    else{
      (tag0, tag1) = seedTag0 < seedTag1 ? (seedTag0, seedTag1) : (seedTag1, seedTag0);
    }


  }

  //Generates a valid portion value in the range of [0, 2^47]
  function makeValidPortion(uint256 seed) internal pure returns (uint256) {
    return (seed % (2**47 + 1));
  }

  //Generates a valid kernel compact bytes
  //@params seed: a random uint256 value
  //@returns: a bytes value representing valid kernel compact bytes
  //seed is used to generate valid kernelLength in range [2, 1020]
  function makeValidKernelCompactBytes(uint256 seed) internal pure returns (bytes memory) {
    uint256 kernelLength = 2 + (seed % 1019); // valid range is [2, 1020]
    uint256 numWords = (kernelLength * 80 + 255) / 256;  //ceiling function

    uint256[] memory words = new uint256[](numWords); 
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(seed, i)));
    }

    bytes memory kernelCompactBytes = abi.encodePacked(numWords,words);
    return kernelCompactBytes;
  }

  //Generates a valid curveBytes
  //@params seed: a random uint256 value
  //seed is used to generate valid curveLength in range [2, type(int16).max(65535)]
  //@returns: a bytes value representing valid curveBytes
  function makeValidCurveBytes(uint256 seed) internal pure returns (bytes memory) {
    uint256 curveLength = 2 + (seed % 1021); // valid range is [2, 65535], but reasonable range is [2,1020]
    uint256 numWords = (curveLength * 64 + 255) / 256;

    uint256[] memory words = new uint256[](numWords); 
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(seed, i)));
    }

    bytes memory curveBytes = abi.encodePacked(numWords, words);
    return curveBytes;
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

  //generates invalidPortions
  function makeInvalidPortion(uint256 seed) internal pure returns (uint256) {
    // valid range is [0, 2^47], so anything >= 2^47 + 1 is invalid
    return (1 << 47) + 1 + (seed % (type(uint256).max - (1 << 47)));
  }

  //generates long hook data bytes 
  function makeLongHookData(uint256 seed) internal pure returns (bytes memory) {
    // valid range is [0, 2^16), so anything >= 2^16 is invalid
    uint256 value = (1 << 16) + (seed % (type(uint256).max - ((1 << 16)+1)));
    return abi.encodePacked(value);
  }



  //PAYLOAD BUILDING FUNCTIONS
  //payload function is broken in multiple components to allow for more flexibility in case of -ve assertion testing

  //builds the payload header, which contains static fields
  function _buildHeader(
      uint256 poolId,
      uint256 tag0,
      uint256 tag1,
      uint256 portion,
      uint256 startKernel,
      uint256 startCurve,
      uint256 startHook,
      CalldataWrapper wrapper
  ) internal pure returns (bytes memory) {
      return abi.encodePacked(
          wrapper._readInitializeInput.selector,
          poolId,
          tag0, tag1, portion,
          startKernel, startCurve, startHook
    );
  }

  //build full payload with dynamic gap and gap bites
  function _buildPayload(uint256 poolId, uint256 tag0, uint256 tag1, uint256 portion, uint256 gap, bytes memory kernelBytes, bytes memory curveBytes, bytes memory hookDataBytes, CalldataWrapper wrapper) internal pure returns (bytes memory) {
      uint256 startKernel = 7 * 32 + gap;
      uint256 startCurve  = startKernel + kernelBytes.length + gap;
      uint256 startHook   = startCurve  + curveBytes.length  + gap;

      return abi.encodePacked(
          _buildHeader(poolId, tag0, tag1, portion, startKernel, startCurve, startHook, wrapper),
          new bytes(gap), kernelBytes,
          new bytes(gap), curveBytes,
          new bytes(gap), hookDataBytes
      );
  }

  //random values generator for all payload inputs

    struct PayloadComponents {
    uint256 poolId;
    uint256 tag0;
    uint256 tag1;
    uint256 portion;
    bytes kernelBytes;
    bytes curveBytes;
    bytes hookDataBytes;
    uint256 gap;
  }

  // struct PayloadComponentsOverlapping {
  //   uint256 poolId;
  //   uint256 tag0;
  //   uint256 tag1;
  //   uint256 portion;
  //   uint256 seed;
  //   bytes curveBytes;
  //   bytes hookDataBytes;
  //   uint256 gap;
  // }

  function generatePayloadStruct(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 gap)
    internal pure returns (PayloadComponents memory) {
      PayloadComponents memory payload;

      payload.poolId = makeValidPoolId(seedPoolId, offsetSeed);
      (payload.tag0, payload.tag1) = makeValidTags(seedTag0, seedTag1);
      payload.portion = makeValidPortion(seedPortion);
      payload.kernelBytes = makeValidKernelCompactBytes(seedKernelBytes);
      payload.curveBytes = makeValidCurveBytes(seedCurveBytes);
      payload.hookDataBytes = makeValidHookDataBytes(seedHookDataBytes);
      payload.gap = makeRandomGap(gap);      
      
      return payload;
    }
  


  //payload for callDataWrapperCustom
    //builds the payload header, which contains static fields
  function _buildHeader(
      uint256 poolId,
      uint256 tag0,
      uint256 tag1,
      uint256 portion,
      uint256 startKernel,
      uint256 startCurve,
      uint256 startHook,
      callDataWrapperCustom wrapper
  ) internal pure returns (bytes memory) {
      return abi.encodePacked(
          wrapper._readInitializeInputCustom.selector,
          poolId,
          tag0, tag1, portion,
          startKernel, startCurve, startHook
    );
  }

  //build full payload with dynamic gap and gap bites
  function _buildPayload(uint256 poolId, uint256 tag0, uint256 tag1, uint256 portion, uint256 gap, bytes memory kernelBytes, bytes memory curveBytes, bytes memory hookDataBytes, callDataWrapperCustom wrapper) internal pure returns (bytes memory) {
      uint256 startKernel = 7 * 32 + gap;
      uint256 startCurve  = startKernel + kernelBytes.length + gap;
      uint256 startHook   = startCurve  + curveBytes.length  + gap;

      return abi.encodePacked(
          _buildHeader(poolId, tag0, tag1, portion, startKernel, startCurve, startHook, wrapper),
          new bytes(gap), kernelBytes,
          new bytes(gap), curveBytes,
          new bytes(gap), hookDataBytes
      );
  }

  //FUNCTIONS FOR OVERLAPPING FUNCTION

  //Random Data: creates bytes to pass as data
  function makeRandomBytes (uint256 seed) internal pure returns (bytes memory) {

    //generate random bytes with length in range [2230, 3029]
    //why 2330? because minimum valid random bytes needed is 1021 + 62(adjusting for first 32 bytes of each data), rest is padding
    //array is fuzzed to keep length random in size
    //range is kept small to ensure overlapping everytime
    uint256 length = 2330 + (seed % 1000);
    bytes memory randomBytes = new bytes(length);

    //fills random bytes with seed+1
    assembly {
      let ptr := add(randomBytes, 32)
      let end := add(ptr, length)
      for {} lt(ptr, end) { ptr := add(ptr, 32) } {
          mstore(ptr, add(seed,1))
      }
    }

    return randomBytes;

  }

  //valid values for (startKernal, startCurve, startHook)
  //@params seed1, seed2, seed3
  //@returns startKernel, startCurve, startHookdata
  //converts seed in valid range, then arrange them and adjust for first 32 bits
  function KCHoffsets(uint256 seed1, uint256 seed2, uint256 seed3) internal pure returns(uint256 startKernel, uint256 startCurve, uint256 startHookData) {

    //get them in range [0,999]
    seed1 = seed1 % 1000;
    seed2 = seed2 % 1000;
    seed3 = seed3 % 1000;


    //arrange as per accending order
    if (seed1 > seed2) (seed1, seed2) = (seed2, seed1);
    if (seed2 > seed3) (seed2, seed3) = (seed3, seed2);
    // if (seed1 > seed3) (seed1, seed3) = (seed3, seed1);
    if (seed1 > seed2) (seed1, seed2) = (seed2, seed1);

    //adjusting for first 32 bytes of data
    //in case of perfect overlap these ranges are required
    (seed1, seed2, seed3) = ( seed1, seed2 + 65, seed3 + 130);


    // //random arrangement
    // uint256 r = seed1%5;
    // if (r == 0) return (seed1, seed2, seed3);
    // if (r == 1) return (seed1, seed3, seed2);
    // if (r == 2) return (seed2, seed1, seed3);
    // if (r == 3) return (seed2, seed3, seed1);
    // if (r == 4) return (seed3, seed1, seed2);
    // return (seed3, seed2, seed1);

    (startKernel, startCurve, startHookData) = (seed1, seed2, seed3);
  }

  //function to overwrite bytes
  function overWriteBytes(bytes memory Bytes_, uint256 value) internal pure returns(bytes memory updatedBytes) {
    updatedBytes = Bytes_;
    assembly {
      // pointer to start of actual data (skip length slot)
      let ptr := add(updatedBytes, 32)

      // write 32 bytes at (ptr + offset(value))
      mstore(add(ptr, value), value)
    }
  }

  //takes random bytes from 'makeRandomBytes' and rewrite few bites to make valid byte(first 32 bits)
  function adjustingRandomBytes(bytes memory randomBytes, uint256 startKernel, uint256 startCurve, uint256 startHookData) internal pure returns(bytes memory updatedBytes){
    //overwrite the byte that is pointed by offset
    //the startKernel, startCurve, startHookdata, can also act as length for itself

    updatedBytes = randomBytes;

    updatedBytes = overWriteBytes(updatedBytes, startKernel);
    updatedBytes = overWriteBytes(updatedBytes, startCurve);
    updatedBytes = overWriteBytes(updatedBytes, startHookData);

  }


  

  //build payload for overlapping function
  function _buildPayloadOverlap(uint256 poolId, uint256 tag0, uint256 tag1, uint256 portion, uint256 seed1, uint256 seed2, uint256 seed3, callDataWrapperCustom wrapper, uint256 randomBytesSeed) internal pure returns (bytes memory) {

    bytes memory randomBytes = makeRandomBytes(randomBytesSeed);
    (uint256 startKernel, uint256 startCurve, uint256 startHookData) = KCHoffsets(seed1, seed2, seed3);
    randomBytes = adjustingRandomBytes(randomBytes, startKernel, startCurve, startHookData);

    return abi.encodePacked(
      _buildHeader(poolId, tag0, tag1, portion, startKernel, startCurve, startHookData, wrapper),
      randomBytes
    );

  }





}

//this contract test the utility functions in the ReadInitializeInputTestUtils library, to ensure that they are generating valid and invalid inputs as expected
//test PASSES and clears SANITY CHECK
contract ReadInitializeInputTestUtilsTests {

  //Test for makeValidPoolId
  function validPoolIds_test(uint256 x, uint8 offsetSeed) public pure {

    uint256 validPoolId = ReadInitializeInputTestUtils.makeValidPoolId(x, offsetSeed);

    //extract offset bits
    uint8 offset = uint8((validPoolId >>180) & 0xFF);

    //check that offset is in the valid range of [-89, 89]
    assert(offset <= 89 || offset >=167);
  }

  //Test for makeValidTags
  //test PASSES and clears SANITY CHECK
  function validTags_test(uint256 seedTag0, uint256 seedTag1) public pure {
    (uint256 tag0, uint256 tag1) = ReadInitializeInputTestUtils.makeValidTags(seedTag0, seedTag1);
    assert(tag0 < tag1);
  }

  //Test for makeValidPortion
  function validPortion_test(uint256 seed) public pure {
    uint256 portion = ReadInitializeInputTestUtils.makeValidPortion(seed);
    assert(portion <= 2**47);
  }

  //Test for makeValidKernelCompactBytes
  function test_kernelCompactBytes(uint256 seed) public pure {
    bytes memory result = ReadInitializeInputTestUtils.makeValidKernelCompactBytes(seed);

    uint256 kernelLength = 2 + (seed % 1019);
    uint256 numWords = (kernelLength * 80 + 255) / 256;

    // 1. total byte length must be 32 (prefix) + numWords * 32
    assert(result.length == 32 + numWords * 32);

    // 2. first word must equal numWords (the length prefix)
    uint256 firstWord;
    assembly { firstWord := mload(add(result, 32)) }
    assert(firstWord == numWords);
  }

  //Test for makeValidCurveBytes
  function ValidCurveBytes_test(uint256 seed) public pure {
    bytes memory result = ReadInitializeInputTestUtils.makeValidCurveBytes(seed);

    uint256 curveLength = 2 + (seed % 1201); //actual range is [2, 65534], but reasonable range is [2, 1200]
    uint256 numWords = (curveLength * 64 +255) / 256;

    //total bytes must be 32 + numWords*32
    assert(result.length == 32 + numWords * 32);

    //first word must equal numWords
    uint256 firstWord;
    assembly { firstWord := mload(add(result, 32)) }
    assert(firstWord == numWords);
  }





}

//this test is designed to check +ve assertions of ReadInitializeInput function
contract ReadInitializePositiveAssertionTest{

  CalldataWrapper wrapper;

  constructor() {
    wrapper = new CalldataWrapper();
  }

  //this test ensures if all inputs are fuzzed within valid range, the function doesn't revert
  //issue: running out of gas 
  //issue resolved by putting practical limit on size of curveBytes, kernelCompactBytes
  function readInitializeInput_test1(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag0, outputs.tag1, outputs.portion, outputs.gap, outputs.kernelBytes, outputs.curveBytes, outputs.hookDataBytes, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(success);

    }

  //-ve assertion test: invalid offsets
  //if poolId is invalid and rest are correct, the function should revert
  function readInitializeInputInvalidPoolId_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);

    //manually substituting outputs.poolId with invalid poolId
    uint256 invalidPoolId = ReadInitializeInputTestUtils.makeInvalidPoolId(seedPoolId, offsetSeed);
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(invalidPoolId, outputs.tag0, outputs.tag1, outputs.portion, outputs.gap, outputs.kernelBytes, outputs.curveBytes, outputs.hookDataBytes, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(!success);

    }



  //-ve assertion test: tags invalid
  function readInitializeInputTagsOutOfOrder_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);

    //manually interchanging the tags to make them invalid
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag1, outputs.tag0, outputs.portion, outputs.gap, outputs.kernelBytes, outputs.curveBytes, outputs.hookDataBytes, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(!success);

  }


  //-ve assertion test: portion invalid
  function readInitializeInputInvalidPortion_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);

    //manually generating invalid portion and substituting in payload
    uint256 invalidPortions = ReadInitializeInputTestUtils.makeInvalidPortion(seedPortion);
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag0, outputs.tag1, invalidPortions, outputs.gap, outputs.kernelBytes, outputs.curveBytes, outputs.hookDataBytes, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(!success);

  }


  //-ve assertion test: curveBytes zero
  function readInitializeInputCurveZero_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);

    //manually substituting curveBytes with zero to make it invalid
    bytes memory emptyCurve = hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag0, outputs.tag1, outputs.portion, outputs.gap, outputs.kernelBytes, emptyCurve, outputs.hookDataBytes, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(!success);

  }

  //-ve assertion test: hookBytesTooLong invalid
  function readInitializeInputHookBytesTooLong_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);

    //manually substituting hookDataBytes with long hook data to make it invalid
    uint256 numWords = (65664) / 32;
    uint256[] memory words = new uint256[](numWords);
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(uint256(65664), i)));
    }

    bytes memory longHookData = abi.encodePacked(uint256(65664), words); 
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag0, outputs.tag1, outputs.portion, outputs.gap, outputs.kernelBytes, outputs.curveBytes, longHookData, wrapper);

    (bool success,)     = address(wrapper).call(payload);
    assert(!success);

  }



}


//calldataWrapperCustom

contract callDataWrapperCustom {


  function _readInitializeInputCustom() public returns (
    uint256 poolId,
    uint256 tag0,
    uint256 tag1,
    uint48 portion,
    uint16 kernelPlacement,
    KernelCompact kernelCompact,
    uint256 curvePlacement,
    uint256 hookDataPlacement,
    uint256 freeMemoryPointer,
    uint256 hookDataByteCount,
    uint256 hookInputByteCount,
    ReadInitializeInputTestUtils.hashedBytes memory hashes
    // bytes memory returnData
  ) {
    kernelCompact = readInitializeInput();
    bytes32 curveHash;
    bytes32 kernelHash;
    bytes32 HookdataHash;
    // uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      poolId  := mload(_poolId_)
      tag0    := mload(_tag0_)
      tag1    := mload(_tag1_)
      portion := shr(208, mload(_poolGrowthPortion_))
      kernelPlacement := mload(_kernel_)
      curvePlacement := mload(_curve_)
      hookDataPlacement := mload(_hookData_)
      freeMemoryPointer := mload(_freeMemoryPointer_)
      hookDataByteCount := shr(240, mload(_hookDataByteCount_))
      hookInputByteCount := mload(_hookInputByteCount_)

      // curveHash := keccak256(curvePlacement, curveByteCount) 
      let curveByteCount := sub(sub(hookDataPlacement, curvePlacement), 8)
      curveHash := keccak256(curvePlacement, curveByteCount)

      // kernelHash
      // kernelCompact is the pointer returned by readInitializeInput()
      // it's a KernelCompact (uint256 underneath), accessible directly in assembly
      let kernelCompactByteCount := sub(curvePlacement, kernelCompact)
      kernelHash := keccak256(kernelCompact, kernelCompactByteCount)

      HookdataHash := keccak256(hookDataPlacement, hookDataByteCount)
    
    }
    hashes.curveHash = curveHash;
    hashes.kernelHash = kernelHash;
    hashes.hookDataHash = HookdataHash;
  }

}

contract ReadInitializeFullPositiveTest{

  //this test is designed to check the full functionality of readInitializeInput function, by reading the inputs and returning them as logs, which can be decoded off-chain to verify correctness of the function
  callDataWrapperCustom wrapper;

  constructor() {
    wrapper = new callDataWrapperCustom();
  }

  function readInitializeInputFull_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedGap) public {

    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedGap);
    bytes memory payload = ReadInitializeInputTestUtils._buildPayload(outputs.poolId, outputs.tag0, outputs.tag1, outputs.portion, outputs.gap, outputs.kernelBytes, outputs.curveBytes, outputs.hookDataBytes, wrapper);

    (bool success, bytes memory returnData)     = address(wrapper).call(payload);
    // assert(false);

    assert(success);

    // wrapper now returns ABI-encoded typed values — decode them directly
    (uint256 returnedPoolId, uint256 returnedTag0, uint256 returnedTag1, uint48 returnedPortion, uint16 returnedKernelPlacement, KernelCompact returnedKernelCompact, uint256 returnedCurvePlacement, uint256 returnedHookDataPlacement, uint256 returnedFreeMemoryPointer, uint256 returnedHookDataByteCount,uint256 returnedHookInputByteCount, ReadInitializeInputTestUtils.hashedBytes memory returnedHashes) =
      abi.decode(returnData, (uint256, uint256, uint256, uint48, uint16, KernelCompact, uint256, uint256, uint256, uint256, uint256, ReadInitializeInputTestUtils.hashedBytes));

    // derivePoolId: poolId = unsaltedPoolId + (keccak256(abi.encodePacked(caller, unsaltedPoolId)) << 188)
    // msg.sender inside the wrapper is address(this) because this contract made the .call()
    uint256 expectedPoolId = outputs.poolId + (uint256(keccak256(abi.encodePacked(address(this), outputs.poolId))) << 188);
    assert(returnedPoolId == expectedPoolId);
    assert(returnedTag0 == outputs.tag0);
    assert(returnedTag1 == outputs.tag1);
    assert(returnedPortion == outputs.portion);

    //check for kernel
    uint256 kernelLength = 2 + (seedKernelBytes % 1019); // valid range is [2, 1020]
    uint256 kernelCompactNumWords = (kernelLength * 80 + 255) / 256;  //ceiling function
    uint256 kernelCompactByteCount = kernelCompactNumWords * 32;
    uint256 kernelByteCount = (kernelCompactByteCount / 5) * 32;
    uint16 kernelPlacement = _endOfStaticParams_;
    uint256 kernelCompactPlacement = kernelPlacement + kernelByteCount;



    //assertions kernel
    assert(kernelPlacement == returnedKernelPlacement);
    assert(kernelCompactPlacement == KernelCompact.unwrap(returnedKernelCompact));


    //calculations for curve
    uint256 curvePlacement = kernelCompactPlacement + kernelCompactByteCount;
    uint256 curveLength = 2 + (seedCurveBytes % 1021); // valid range is [2, 65535], but reasonable range is [2,1020]
    uint256 curveNumWords = (curveLength * 64 +255) / 256;
    uint256 curveByteCount = curveNumWords * 32;
 

    //curve assertions
    assert(curvePlacement == returnedCurvePlacement);
    // assert(curveByteCount == returnedCurveByteCount);


    //hookdata calculations
    uint256 hookDataPlacement = curvePlacement + curveByteCount + uint256(8);
    uint256 hookDataByteCount = seedHookDataBytes % 1021; // valid range [0, 65535] , but reasonalbe range is [[2, 1020]]
    uint256 freeMemoryPointer = hookDataPlacement + hookDataByteCount;
    uint256 hookInputByteCount = uint256(kernelPlacement) + kernelByteCount + kernelCompactByteCount + curveByteCount + hookDataByteCount + uint256(8) - _hookInputByteCount_ - uint256(32); //8 bytes for curve length and hook data byte count

    //hookdata assertions
    assert(hookDataPlacement == returnedHookDataPlacement);
    assert(freeMemoryPointer == returnedFreeMemoryPointer);
    assert(hookDataByteCount == returnedHookDataByteCount);
    assert(hookInputByteCount == returnedHookInputByteCount);

    //bytes assertions
    bytes memory cb = outputs.curveBytes;
    bytes32 curveHash;
    assembly {
        // cb memory layout: [solidity_length (32)] [count_prefix (32)] [curve words...]
        // add(cb, 64) skips both prefix words
        // sub(mload(cb), 32) = total length - count_prefix = curve words length only
        curveHash := keccak256(add(cb, 64), sub(mload(cb), 32))
    }    
    assert(curveHash == returnedHashes.curveHash);

    bytes memory kb = outputs.kernelBytes;
    bytes32 expectedKernelHash;
    assembly {
        expectedKernelHash := keccak256(add(kb, 64), sub(mload(kb), 32))
    }
    assert(returnedHashes.kernelHash == expectedKernelHash);


    bytes memory hb = outputs.hookDataBytes;
    bytes32 expectedHookDataHash;
    assembly {
        expectedHookDataHash := keccak256(add(hb, 64), hookDataByteCount)
    }
    assert(returnedHashes.hookDataHash == expectedHookDataHash);

  }

  

  function overlap_test(
    uint256 seedPoolId, 
    uint8 offsetSeed,
    uint256 seedTag0, 
    uint256 seedTag1,
    uint256 seedPortion,
    uint256 seedKernelBytes,
    uint256 seedCurveBytes,
    uint256 seedHookDataBytes,
    uint256 seedBytes
  ) public {
    //used to originate poolId, tags, portion
    ReadInitializeInputTestUtils.PayloadComponents memory outputs = ReadInitializeInputTestUtils.generatePayloadStruct(seedPoolId, offsetSeed, seedTag0, seedTag1, seedPortion, seedKernelBytes, seedCurveBytes, seedHookDataBytes, seedBytes);

    //generate random bytes
    bytes memory bytes_ = ReadInitializeInputTestUtils.makeRandomBytes(seedBytes);
    uint256 bytesLength;

    assembly{
      bytesLength := mload(bytes_)
    }

    //generate random Offsets
    (uint256 startKernel, uint256 startCurve, uint256 startHookDataBytes) = ReadInitializeInputTestUtils.KCHoffsets(seedKernelBytes, seedCurveBytes, seedHookDataBytes);

    //generate random BytesLength
    // CurveBytes is capped so curve data (startCurve+32 + CurveBytes*32) fits inside bytes_,
    // preventing the expectedCurveHash from reading garbage memory beyond the array.
    uint256 maxKernelWords = (bytesLength > startKernel + 32) ? (bytesLength - startKernel - 32) / 32 : 1;
    if (maxKernelWords == 0) maxKernelWords = 1;
    uint256 maxCurveWords = (bytesLength > startCurve + 32) ? (bytesLength - startCurve - 32) / 32 : 1;
    if (maxCurveWords == 0) maxCurveWords = 1;
    (uint256 KernelBytes, uint256 CurveBytes, uint256 HookDataBytes) = (seedKernelBytes % maxKernelWords, 1 + (seedCurveBytes % maxCurveWords), seedHookDataBytes % 500);

    //update bytes for kernel

    // bytes32 memory kernelSavedHash;
    // bytes32 memory kernelCalculatedHash;
    uint256 kernelByteCountSaved;
    uint256 curveByteCountSaved;
    uint256 hookDataByteCountSaved;
    // bytes32 hookDataHashExpected;

    assembly{
      let ptr := add(bytes_, 32)
      let startK := add(ptr, startKernel)
      mstore(startK, KernelBytes)

      let startC := add(ptr, startCurve)
      mstore(startC, CurveBytes)

      let startH := add(ptr, startHookDataBytes)
      mstore(startH, HookDataBytes)

      //loaded in reverse order, to ensure no invalid overlaping of first 32 bytes
      hookDataByteCountSaved := mload(startH)
      curveByteCountSaved := mload(startC)
      kernelByteCountSaved := mload(startK)

      // hookDataHashExpected := keccak256(startH, HookDataBytes)

    }

    //ensures no invliad overlapping of first 32 bytes
    assert(kernelByteCountSaved == KernelBytes);
    assert(curveByteCountSaved == CurveBytes);
    assert(hookDataByteCountSaved == HookDataBytes);

    //build Payload
    bytes memory payload = abi.encodePacked(
      ReadInitializeInputTestUtils._buildHeader(outputs.poolId, outputs.tag0, outputs.tag1, outputs.portion, startKernel + 224, startCurve + 224, startHookDataBytes + 224, wrapper),
      bytes_
    );

    (bool success, bytes memory returnData) = address(wrapper).call(payload);
    // assert(false);

    assert(success);

    // wrapper now returns ABI-encoded typed values — decode them directly
    (uint256 returnedPoolId, uint256 returnedTag0, uint256 returnedTag1, uint48 returnedPortion, uint16 returnedKernelPlacement, KernelCompact returnedKernelCompact, uint256 returnedCurvePlacement, uint256 returnedHookDataPlacement, uint256 returnedFreeMemoryPointer, uint256 returnedHookDataByteCount,uint256 returnedHookInputByteCount, ReadInitializeInputTestUtils.hashedBytes memory returnedHashes) =
      abi.decode(returnData, (uint256, uint256, uint256, uint48, uint16, KernelCompact, uint256, uint256, uint256, uint256, uint256, ReadInitializeInputTestUtils.hashedBytes));

    // derivePoolId: poolId = unsaltedPoolId + (keccak256(abi.encodePacked(caller, unsaltedPoolId)) << 188)
    // msg.sender inside the wrapper is address(this) because this contract made the .call()
    uint256 expectedPoolId = outputs.poolId + (uint256(keccak256(abi.encodePacked(address(this), outputs.poolId))) << 188);
    assert(returnedPoolId == expectedPoolId);
    assert(returnedTag0 == outputs.tag0);
    assert(returnedTag1 == outputs.tag1);
    assert(returnedPortion == outputs.portion);


    uint16 kernelPlacement = _endOfStaticParams_;
    uint256 kernelCompactPlacement = uint256(kernelPlacement) + (kernelByteCountSaved * 32 / 5) * 32;

    assert(kernelPlacement == returnedKernelPlacement);
    assert(kernelCompactPlacement == KernelCompact.unwrap(returnedKernelCompact));

    uint256 kernelCompactByteCount = kernelByteCountSaved * 32;        // word count → bytes
    uint256 kernelByteCount = (kernelCompactByteCount / 5) * 32;       // kernel expansion factor
    uint256 curvePlacement = uint256(kernelPlacement) + kernelByteCount + kernelCompactByteCount;
    assert(returnedCurvePlacement == curvePlacement);

    uint256 hookDataPlacement = curvePlacement + curveByteCountSaved * 32 + 8;
    assert(returnedHookDataPlacement == hookDataPlacement);
    assert(hookDataByteCountSaved == returnedHookDataByteCount);

    bytes32 expectedCurveHash;
    assembly {
      // skip bytes_ length slot (32) + word-count prefix at startCurve (32)
      let ptr := add(add(bytes_, 32), add(startCurve, 32))
      expectedCurveHash := keccak256(ptr, mul(curveByteCountSaved, 32))
    }
    assert(returnedHashes.curveHash == expectedCurveHash);


    bytes32 expectedHookDataHash;
    assembly {
      // skip bytes_ length slot (32) + hook byte-count prefix at startHookDataBytes (32)
      let ptr := add(add(bytes_, 32), add(startHookDataBytes, 32))
      expectedHookDataHash := keccak256(ptr, hookDataByteCountSaved)
    }
    assert(returnedHashes.hookDataHash == expectedHookDataHash);

    // bytes32 expectedKernelHash;
    // assembly {
    //   // skip bytes_ length slot (32) + kernel word-count prefix at startKernel (32)
    //   let ptr := add(add(bytes_, 32), add(startKernel, 32))
    //   expectedKernelHash := keccak256(ptr, mul(kernelByteCountSaved, 32))
    // }
    // assert(returnedHashes.kernelHash == expectedKernelHash);


    assert(true);
  }


}

