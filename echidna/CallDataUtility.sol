//this contains helper functions for all calldata functions
// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

library CallDataTestCommonUtilities{

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


  //Generates a valid portion value in the range of [0, 2^47]
  function makeValidPortion(uint256 seed) internal pure returns (uint256) {
    return (seed % (2**47 + 1));
  }

  //generates invalidPortions
  function makeInvalidPortion(uint256 seed) internal pure returns (uint256) {
    // valid range is [0, 2^47], so anything >= 2^47 + 1 is invalid
    return (1 << 47) + 1 + (seed % (type(uint256).max - (1 << 47)));
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

 //generates long hook data bytes
  function makeLongHookData(uint256 seed) internal pure returns (bytes memory) {
    // max valid hookDataByteCount is 65535 (16-bit); range here is [65536, 65735]
    uint256 hookDataByteCount = 65536 + (seed % 200);
    uint256 numWords = (hookDataByteCount + 31) / 32;

    uint256[] memory words = new uint256[](numWords);
    for (uint256 i = 0; i < numWords; i++) {
      words[i] = uint256(keccak256(abi.encodePacked(seed, i)));
    }

    return abi.encodePacked(hookDataByteCount, words);
  }




}

library ReadModifyPoolGrowthPortionTestUtilities{
    struct returnedValues{
        uint256 poolId;
        uint256 poolGrowthPortion;
        uint256 hookInputByteCount;
        uint256 freeMemoryPointer;
    }


    function genrateValues(uint256 poolIdSeed,uint8 offsetSeed, uint256 poolGrowthPortionSeed)
    internal view returns(
        uint256 poolId,
        uint256 poolGrowthPortion
    ){
        poolId = CallDataTestCommonUtilities.makeValidPoolId(poolIdSeed, offsetSeed);
        poolGrowthPortion = CallDataTestCommonUtilities.makeValidPortion(poolGrowthPortionSeed);
    }

}

library ReadUpdateGrowthPortionInputUtilities{

  struct returnedValues{
    uint256 poolId;
    uint256 poolGrowthPortion;
    uint256 hookInputByteCount;
    uint256 freeMemoryPointer;
  }

}

library ReadCollectInputTestUtilities{

  struct returnedValues{
    uint256 poolId;
    uint256 freeMemoryPointer;
  }

}

library ReadSwapInputHookDataTestUtilities {

  struct generatedValues{
    uint256 poolId;
    int128 amountSpecified;
    int256 logPriceLimit;
    uint128 crossThreshold;
    uint8 zeroForOne;
    bytes hookDataBytes;
    uint256 gap;
  }


  function generateValues(
    uint256 poolIdSeed,
    uint8 offSetSeed,
    int128 amountSeed,
    int256 logPriceLimitSeed,
    uint128 crossThresholdSeed,
    uint8 zeroForOneSeed,
    uint256 hookDataByteCountSeed,
    uint256 gapSeed
  ) internal pure returns(
    generatedValues memory GeneratedValues
  ){
    GeneratedValues.poolId = CallDataTestCommonUtilities.makeValidPoolId(poolIdSeed, offSetSeed);
    GeneratedValues.amountSpecified = amountSeed;
    GeneratedValues.logPriceLimit = logPriceLimitSeed;
    GeneratedValues.crossThreshold = crossThresholdSeed;
    GeneratedValues.zeroForOne = (zeroForOneSeed % 3);

    GeneratedValues.hookDataBytes = CallDataTestCommonUtilities.makeValidHookDataBytes(hookDataByteCountSeed);

    GeneratedValues.gap = CallDataTestCommonUtilities.makeRandomGap(gapSeed);
  }
  
}