// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import {CalldataWrapper} from "../contracts/helpers/CalldataWrapper.sol";

//this test is designed to check all the -ve assertions of ReadInitialize function

contract ReadInitializeNegitiveAssertionTest {

  CalldataWrapper wrapper;

  constructor() {
    wrapper = new CalldataWrapper();
  }
  


  //utility functions

  //this function generates InvalidPoolIds
  //@params seed:uint256 x, a random OffsetSeed :uint8 to generate different InvalidPoolIds
  //@returns: a uint256 representing an InvalidPoolId, with invaid offset valuses
  //invalid pool Id: offset bits[180,187] are represeting x, such that x< -89; x> 89, in two complement respresentation
  //x is uint256 and the values are randomly generated

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

  function makeInvalidPortion(uint256 seed) internal pure returns (uint256) {
    // valid range is [0, 2^47], so anything >= 2^47 + 1 is invalid
    return (1 << 47) + 1 + (seed % (type(uint256).max - (1 << 47)));
  }

  function makeLongHookData(uint256 seed) internal pure returns (bytes memory) {
    // valid range is [0, 2^16), so anything >= 2^16 is invalid
    uint256 value = (1 << 16) + (seed % (type(uint256).max - ((1 << 16)+1)));
    return abi.encodePacked(value);
  }


  // //Test for makeInvalidPoolId
  // //echidna test to ensure that makeInvalidPoolId generates poolIds that fail the assertion in the initialize function of the main contract
  // function invalidPoolIdss_test(uint256 x, uint8 offsetSeed) public pure {

  //     uint256 invalidPoolId = makeInvalidPoolId(x, offsetSeed);

  //     // Sign-extend the byte at bits [187:180] to get the signed offset,
  //     // matching what getLogOffsetFromPoolId does via signextend(0, shr(180, poolId)).
  //     int8 qOffset = int8(uint8((invalidPoolId >> 180) & 0xFF));

  //     assert(qOffset < -89 || qOffset > 89);

  // }
  // //TEST PASSES, Passes SANITY CHECK as well


  //constants for the test

  // poolIds
  uint256 constant POOL_ID_0 =
    (uint256(0xF0F0F0F0F0F0F0F0F) << 188) |  // salt bits [255:188] 
    (uint256(0xA7)                 << 180) |  // offset = -89 in two's complement, bits [187:180]
    uint256(0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F);  // lower bits [179:0]

  // tag2, tag3
  uint256 constant TAG_0 = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F;
  uint256 constant TAG_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  // portion0
  uint256 constant PORTION = 0;

  // value2
  uint256 constant CONTENT = 0xF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F;

  // uint256 constant HOOK_DATA_BYTE_COUNT = 32767;

  // kernelCompact: [len=1][packed breakpoint: height=0xF00F (16-bit) | logPrice=0xF00FF00FF00FF00F (64-bit), left-aligned]
  bytes constant KERNEL_BYTES = hex"0000000000000000000000000000000000000000000000000000000000000001"
                                  hex"F00FF00FF00FF00FF00F00000000000000000000000000000000000000000000";

  // curve: [len=1][two 64-bit logPrices at bits 255:192 and 191:128]
  bytes constant CURVE_BYTES  = hex"0000000000000000000000000000000000000000000000000000000000000001"
                                  hex"F00FF00FF00FF00FF00FF00FF00FF00F00000000000000000000000000000000";

  // hookData: byteCount=0
  bytes constant HOOK_BYTES   = hex"0000000000000000000000000000000000000000000000000000000000000000";



  function _buildHeader(
      uint256 poolId,
      uint256 tag0,
      uint256 tag1,
      uint256 portion,
      uint256 startKernel,
      uint256 startCurve,
      uint256 startHook
  ) internal view returns (bytes memory) {
      return abi.encodePacked(
          wrapper._readInitializeInput.selector,
          poolId,
          tag0, tag1, portion,
          startKernel, startCurve, startHook
      );
  }

  function _buildPayload(uint256 poolId, uint256 tag0, uint256 tag1, uint256 portion) internal view returns (bytes memory) {
      uint256 gap         = 100;
      uint256 startKernel = 7 * 32 + gap;
      uint256 startCurve  = startKernel + KERNEL_BYTES.length + gap;
      uint256 startHook   = startCurve  + CURVE_BYTES.length  + gap;

      return abi.encodePacked(
          _buildHeader(poolId, tag0, tag1, portion, startKernel, startCurve, startHook),
          new bytes(gap), KERNEL_BYTES,
          new bytes(gap), CURVE_BYTES,
          new bytes(gap), HOOK_BYTES
      );
  }

  function _buildPayloadInputCurveAndHook(bytes memory curveBytes, bytes memory hookBytes) internal view returns (bytes memory) {
      uint256 gap         = 100;
      uint256 startKernel = 7 * 32 + gap;
      uint256 startCurve  = startKernel + KERNEL_BYTES.length + gap;
      uint256 startHook   = startCurve  + curveBytes.length  + gap;

      return abi.encodePacked(
          _buildHeader(POOL_ID_0, TAG_0, TAG_1, PORTION, startKernel, startCurve, startHook),
          new bytes(gap), KERNEL_BYTES,
          new bytes(gap), curveBytes,
          new bytes(gap), hookBytes
      );
  }

  //test functions
  function readInitializeInvalidOffsets_test(uint256 x, uint8 offsetSeed) public {
      uint256 invalidPoolId = makeInvalidPoolId(x, offsetSeed);
      (bool success,)       = address(wrapper).call(_buildPayload(invalidPoolId, TAG_0, TAG_1, PORTION));
      assert(!success);
  }


  //we generate two random uint256
  //compare for size and place them in wrong order while encoding
  function readInitializeTagsOutOfOrder_test(uint256 tag_0, uint256 tag_1) public {

      bool success;

      if (tag_0 > tag_1) {
        ( success,)       = address(wrapper).call(_buildPayload(POOL_ID_0, tag_0, tag_1, PORTION));
      }
      else if (tag_1 >tag_0) {
        ( success,) = address(wrapper).call(_buildPayload(POOL_ID_0, tag_1, tag_0, PORTION));
      }
      else {
        // if the tags are equal
        // this will fail if tag0 == 2^256 - 1
        if (tag_0 == type(uint256).max) {
          ( success,) = address(wrapper).call(_buildPayload(POOL_ID_0, tag_0 - 1, tag_1, PORTION));
        }
         else {
        ( success,)     = address(wrapper).call(_buildPayload(POOL_ID_0, tag_0 + 1, tag_1, PORTION));}
      }
      assert(!success);
  }


  //validPortion range: [0, 2^47]
  //invalid portion: portion > 2^47
  function readIntializeInvalidPortion_test(uint256 x) public {

    uint256 invalidPortion = makeInvalidPortion(x);
    (bool success,)       = address(wrapper).call(_buildPayload(POOL_ID_0, TAG_0, TAG_1, invalidPortion));
    assert(!success);
  }

  //nothing to fuzz here?
  function readInitializeCurveLengthIsZero_test() public {
    // curveBytes with length=0 (no elements)
    bytes memory emptyCurve = hex"0000000000000000000000000000000000000000000000000000000000000000";
    (bool success,) = address(wrapper).call(_buildPayloadInputCurveAndHook(emptyCurve,HOOK_BYTES));
    assert(!success);
  }

  function readInitializeInputLongHookData_test(uint256 x) public {

    bytes memory longHookData = makeLongHookData(x);
    (bool success,) = address(wrapper).call(_buildPayloadInputCurveAndHook(CURVE_BYTES,longHookData));
    assert(!success);
  }


}

