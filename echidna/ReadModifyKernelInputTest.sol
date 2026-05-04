// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

import "../contracts/utilities/Calldata.sol";
import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _poolId_,
  _kernel_,
  _shares_,
  _curve_,
  _hookData_, _hookDataByteCount_, _hookInputByteCount_,
  _freeMemoryPointer_,
  _endOfStaticParams_
} from "../contracts/utilities/Memory.sol";

import {ReadDonateHelper} from "./ReadDonateInputTest.sol";

//wrapper Contract
contract CallDataWrapper{

  function _readModifyKernelInput() public view returns(
    readModifyKernelHelper.returnedValues memory returnedValues
  ){
    KernelCompact kernelCompact = readModifyKernelInput();

    uint256 poolId;
    uint256 kernelPlacement;
    uint256 hookDataPlacement;
    uint256 freeMemoryPointer;
    uint256 hookDataByteCount;
    uint256 hookInputByteCount;
    bytes32 kernelHash;
    bytes32 hookDataHash;
    assembly{
      poolId := mload(_poolId_)
      kernelPlacement := mload(_kernel_)
      hookDataPlacement := mload(_hookData_)
      freeMemoryPointer := mload(_freeMemoryPointer_)
      hookDataByteCount := shr(240, mload(_hookDataByteCount_))
      hookInputByteCount := mload(_hookInputByteCount_)

      // kernelHash: hookData immediately follows kernelCompact in memory
      let kernelCompactByteCount := sub(hookDataPlacement, kernelCompact)
      kernelHash := keccak256(kernelCompact, kernelCompactByteCount)

      hookDataHash := keccak256(hookDataPlacement, hookDataByteCount)

    }

    returnedValues.poolId = poolId;
    returnedValues.kernelPlacement = kernelPlacement;
    returnedValues.hookDataPlacement = hookDataPlacement;
    returnedValues.freeMemoryPointer = freeMemoryPointer;
    returnedValues.kernelCompact = kernelCompact;
    returnedValues.hookDataByteCount = hookDataByteCount;
    returnedValues.hookInputByteCount = hookInputByteCount;
    returnedValues.kernelHash = kernelHash;
    returnedValues.hookDataHash = hookDataHash;
  
  }

}

//helping Library
library readModifyKernelHelper{

  struct returnedValues{
    uint256 poolId;
    uint256 kernelPlacement;
    uint256 hookDataPlacement;
    uint256 freeMemoryPointer;
    KernelCompact kernelCompact;
    uint256 hookDataByteCount;
    uint256 hookInputByteCount;
    bytes32 kernelHash;
    bytes32 hookDataHash;
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

  // valuesGenerator
  function valuesGenrator(
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 kernelByteSeed,
    uint256 hookDataSeed,
    uint256 gapSeed
  ) internal pure returns (
    uint256 poolId,
    bytes memory kernelBytes,
    bytes memory hookDataBytes,
    uint256 gap1,
    uint256 gap2
  ) {
    poolId = ReadDonateHelper.makeValidPoolId(poolIdSeed, offsetSeed);
    kernelBytes = makeValidKernelCompactBytes(kernelByteSeed);
    hookDataBytes = ReadDonateHelper.makeValidHookDataBytes(hookDataSeed);
    gap1 = ReadDonateHelper.makeRandomGap(gapSeed);
    gap2 = uint256(keccak256(abi.encodePacked(gap1))) % 201;
  }

  //payloadGenerator
  function payloadGenerator(
    CallDataWrapper wrapper,
    uint256 poolId,
    bytes memory kernelBytes,
    bytes memory hookDataBytes,
    uint256 gap1,
    uint256 gap2
  ) internal view returns(
    bytes memory payload
  ){
    //abi encoding packed
    uint256 startKernel = 32*3 + gap1;
    uint256 startHookData = startKernel + kernelBytes.length + gap2;

    payload = abi.encodePacked(
      wrapper._readModifyKernelInput.selector,
      poolId,
      startKernel,
      startHookData,
      new bytes(gap1), kernelBytes,
      new bytes(gap2), hookDataBytes
    );

  }


}



//Test contract
contract ReadModifyKernelInputTest{

  //wrapper instance
  CallDataWrapper wrapper;

  constructor(){
    wrapper = new CallDataWrapper();
  }

  struct values{
    uint256 kernelPlacement;

  }

  //test function
  function readModifyKernel_test(
    //seeds
    uint256 poolIdSeed,
    uint8 offsetSeed,
    uint256 kernelByteSeed,
    uint256 hookDataByteSeed,
    uint256 gapSeed
  ) public {

    //valuesGenerator
    (uint256 poolId,
    bytes memory kernelBytes,
    bytes memory hookDataBytes,
    uint256 gap1,
    uint256 gap2) = readModifyKernelHelper.valuesGenrator(poolIdSeed, offsetSeed, kernelByteSeed, hookDataByteSeed, gapSeed);
    
    //payloadGenerator
    bytes memory payload = readModifyKernelHelper.payloadGenerator(wrapper, poolId, kernelBytes, hookDataBytes, gap1, gap2);
    (bool success, bytes memory returnedValues) = address(wrapper).call(payload);

    //assertion test
    assert(success);

    //decode returnedValues
    readModifyKernelHelper.returnedValues memory returnedValuesDecoded;
    ( returnedValuesDecoded.poolId, 
      returnedValuesDecoded.kernelPlacement,
      returnedValuesDecoded.hookDataPlacement,
      returnedValuesDecoded.freeMemoryPointer,
      returnedValuesDecoded.kernelCompact,
      returnedValuesDecoded.hookDataByteCount,
      returnedValuesDecoded.hookInputByteCount,
      returnedValuesDecoded.kernelHash,
      returnedValuesDecoded.hookDataHash)= abi.decode(returnedValues, (uint256,uint256,uint256,uint256,KernelCompact,uint256,uint256,bytes32,bytes32));

    assert(poolId == returnedValuesDecoded.poolId);

    values memory Values;
    Values.kernelPlacement = _endOfStaticParams_;

    uint256 numWords;
    assembly { numWords := mload(add(kernelBytes, 32)) }
    uint256 kernelCompactByteCount = numWords << 5;
    uint256 kernelByteCount = (kernelCompactByteCount / 5) << 5;
    uint256 hookDataByteCount;
    assembly { hookDataByteCount := mload(add(hookDataBytes, 32)) }
    uint256 hookInputByteCount = _endOfStaticParams_ + kernelByteCount + kernelCompactByteCount + hookDataByteCount - _hookInputByteCount_ - 32;

    uint256 kernelCompactPlacement = Values.kernelPlacement + kernelByteCount;
    uint256 hookDataPlacement = KernelCompact.unwrap((returnedValuesDecoded.kernelCompact)) + kernelCompactByteCount;
    uint256 freeMemoryPointer = hookDataPlacement + hookDataByteCount;

    assert(Values.kernelPlacement == returnedValuesDecoded.kernelPlacement);
    assert(hookDataPlacement == returnedValuesDecoded.hookDataPlacement);
    assert(freeMemoryPointer == returnedValuesDecoded.freeMemoryPointer);
    assert(hookDataByteCount == returnedValuesDecoded.hookDataByteCount);
    assert(hookInputByteCount == returnedValuesDecoded.hookInputByteCount);

    bytes32 expectedHookDataHash;
    assembly {
        expectedHookDataHash := keccak256(add(hookDataBytes, 64), hookDataByteCount)
    }
    assert(returnedValuesDecoded.hookDataHash == expectedHookDataHash);

    bytes32 expectedKernelHash;
    assembly {
        expectedKernelHash := keccak256(add(kernelBytes, 64), sub(mload(kernelBytes), 32))
    }
    assert(returnedValuesDecoded.kernelHash == expectedKernelHash);


  }



}
