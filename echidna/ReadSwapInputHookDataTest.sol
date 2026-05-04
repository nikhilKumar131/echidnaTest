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
import {CallDataTestCommonUtilities,ReadSwapInputHookDataTestUtilities} from "./CallDataUtility.sol";

contract CallDataWrapper{

    //function
		function _readSwapInput() public {
			readSwapInput();
		}

}

contract ReadSwapInputHookDataTest{

    //wrapper Instance
    CallDataWrapper wrapper;

    constructor(){
      wrapper = new CallDataWrapper();
    }

    //test function
    function readSwapInput_test(
        uint256 poolIdSeed,
        uint8 offSetSeed,
        int128 amountSeed,
        int256 qLimitSeed,
				uint128 crossThresholdSeed,
        uint8 zeroForOneSeed,
        uint256 hookDataByteCountSeed,
        uint256 gapSeed
    ) public {

        //generate Values
        ReadSwapInputHookDataTestUtilities.generatedValues memory GeneratedValues;
        
				GeneratedValues = ReadSwapInputHookDataTestUtilities.generateValues(poolIdSeed, offSetSeed, amountSeed, qLimitSeed, crossThresholdSeed, zeroForOneSeed, hookDataByteCountSeed, gapSeed);

				uint256 startOfHookData = 5*32 + GeneratedValues.gap;

				bytes memory payload = abi.encodePacked(
						wrapper._readSwapInput.selector,
						GeneratedValues.poolId,
						int256(GeneratedValues.amountSpecified),   // 32 bytes, not int128
						GeneratedValues.logPriceLimit,
						(uint256(GeneratedValues.crossThreshold) << 128) | uint256(GeneratedValues.zeroForOne),  // packed 32-byte word
						startOfHookData,
						new bytes(GeneratedValues.gap),
						GeneratedValues.hookDataBytes
				);


        //assertion test

				(bool success, ) = address(wrapper).call(payload);

				assert(success);

    }

    //Negitive assertion test function
    function readSwapInputHookDataTooLong_test(
        uint256 poolIdSeed,
        uint8 offSetSeed,
        int128 amountSeed,
        int256 qLimitSeed,
				uint128 crossThresholdSeed,
        uint8 zeroForOneSeed,
        uint256 hookDataByteCountSeed,
        uint256 gapSeed
    ) public {

        //generate Values
        ReadSwapInputHookDataTestUtilities.generatedValues memory GeneratedValues;
        
				GeneratedValues = ReadSwapInputHookDataTestUtilities.generateValues(poolIdSeed, offSetSeed, amountSeed, qLimitSeed, crossThresholdSeed, zeroForOneSeed, hookDataByteCountSeed, gapSeed);
				GeneratedValues.hookDataBytes = CallDataTestCommonUtilities.makeLongHookData(hookDataByteCountSeed);

				uint256 startOfHookData = 5*32 + GeneratedValues.gap;

				bytes memory payload = abi.encodePacked(
						wrapper._readSwapInput.selector,
						GeneratedValues.poolId,
						int256(GeneratedValues.amountSpecified),   // 32 bytes, not int128
						GeneratedValues.logPriceLimit,
						(uint256(GeneratedValues.crossThreshold) << 128) | uint256(GeneratedValues.zeroForOne),  // packed 32-byte word
						startOfHookData,
						new bytes(GeneratedValues.gap),
						GeneratedValues.hookDataBytes
				);


        //assertion test

				(bool success, ) = address(wrapper).call(payload);

				assert(!success);

    }

}