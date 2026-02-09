// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {PriceLibrary} from "../../contracts/utilities/Price.sol";

import {X15, zeroX15, oneX15} from "../../contracts/utilities/X15.sol";
import {
  X59,
  epsilonX59,
  twoX59,
  thirtyTwoX59,
  min,
  max,
  minLogStep,
  minLogSpacing
} from "../../contracts/utilities/X59.sol";
import {
  X216,
  zeroX216,
  epsilonX216,
  oneX216,
  expInverse8X216,
  min,
  max
} from "../../contracts/utilities/X216.sol";

import "../../echidna/FuzzUtilities.sol";



using PriceLibrary for uint256;


//this library stores utility functions for echidna_testing of 
//functions given in the assignment
library testUtilities{


    //this wrapper stores takes seed values for (logPrice,sqrtPrice, sqrtInversePrice)
    //convert them to actual values
    //return(stored values and calculated values)
    function storePriceWrap(
        uint64 logPrice,
        uint216 sqrtPrice,
        uint216 sqrtInversePrice
      ) internal returns (
        X59 logPriceConverted,
        X216 sqrtPriceConverted,
        X216 sqrtInversePriceConverted,
        X59 logResult,
        X216 sqrtResult,
        X216 sqrtInverseResult
      ) {
        uint256 pricePointer;

        //leaves 32bytes before saving the values to ensure logic consistency
        assembly {
          let p := mload(0x40)          // current free memory pointer
          mstore(0x40, add(p, 96))      // reserve 96 bytes (enough for before + data + after)
          pricePointer := add(p, 32)         // <-- ensure pointer >= p + 32
        }

        //convert logPrice to x59
        X59 logPriceConverted = get_a_logPrice(logPrice);
        //convert sqrtPrice to x216
        X216 sqrtPriceConverted = get_an_integral(sqrtPrice);

        //convert SqrtInversePrice to x216
        X216 sqrtInversePriceConverted = get_an_integral(sqrtInversePrice);


        //saves converted values in memory 
        pricePointer.storePrice(logPriceConverted, sqrtPriceConverted, sqrtInversePriceConverted);
        logResult = pricePointer.log();
        sqrtResult = pricePointer.sqrt(false);
        sqrtInverseResult = pricePointer.sqrt(true); //effor

        //returns values
        return (
         logPriceConverted,
         sqrtPriceConverted,
         sqrtInversePriceConverted,
         logResult,
         sqrtResult,
         sqrtInverseResult
      );
    }


    //this function is used inside MEMORY_CORRUPTION_WRAP
    function pointer_allocator(uint256 seed) internal returns(uint256 pointer,  bytes memory buf){
        // Allocate a buffer big enough for:
        // - 32 bytes before (for preceding slot)
        // - 64 bytes for the packed layout (more than enough)
        // - 32 bytes after (for right guard)
        bytes memory buf = new bytes(160);

        uint256 base;
        assembly {
            // buf points to length; data starts at buf + 32
            base := add(buf, 32)
        }

        // Choose an offset in a safe range:
        // We want: pointer >= base + 32, and pointer + 64 <= base + 160
        // So offset in [32 .. 64] is plenty safe and still varies alignment.
        uint256 offset = 32 + (seed % 33); // [32 .. 64]

        pointer = base + offset;
    }





    function memory_corruption_wrap(
        uint256 pointerSeed,
        uint64 logPrice,
        uint216 sqrtPrice,
        uint216 sqrtInversePrice
      ) internal returns (
        bytes32 leftGuardAfter,
        bytes32 rightGuardAfter
      ) {
         (uint256 pricePointer,bytes memory buf) = pointer_allocator(pointerSeed);


        //convert logPrice to x59
        X59 logPriceConverted = get_a_logPrice(logPrice);
        //convert sqrtPrice to x216
        X216 sqrtPriceConverted = get_an_integral(sqrtPrice);

        //convert SqrtInversePrice to x216
        X216 sqrtInversePriceConverted = get_an_integral(sqrtInversePrice);

        bytes32 leftGuard = keccak256("LEFT");
        bytes32 rightGuard = keccak256("RIGHT");
        assembly {
          mstore(sub(pricePointer, 32), leftGuard) //error
          mstore(add(pricePointer, 64), rightGuard)
        }



        pricePointer.storePrice(logPriceConverted, sqrtPriceConverted, sqrtInversePriceConverted);
        // logResult = pricePointer.log();
        // sqrtResult = pricePointer.sqrt(false);
        // sqrtInverseResult = pricePointer.sqrt(true);
        assembly{
          leftGuardAfter := mload(sub(pricePointer,32))
          rightGuardAfter := mload(add(pricePointer,64))
        }


      }

//-------------------------------------------------------------------------------------------------------------------
//FUNCTIONS FOR CALLDATA_TEST

    //this just creates a valid buildHookData for passing the abi call
    function buildHookData(int256 n, int256 content) internal pure returns (bytes memory) {
        // layout: [ uint256(n) ][ content ][ content ] ... (n times)
        bytes memory out = abi.encodePacked(int256(n));
        for (int256 i = 0; i < n; i++) {
            out = abi.encodePacked(out, int256(content));
        }
        return out;
    }




}