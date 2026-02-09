// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;


import {X15} from "../../contracts/utilities/X15.sol";

import {
  X59
} from "../../contracts/utilities/X59.sol";

import {
  X216
} from "../../contracts/utilities/X216.sol";


import {testUtilities} from "./TestUtilities.sol";



//this contract run two tests
contract priceTest{


  //this test use seed values to fuzz the logPrice, sqrtPrice, sqrtInversePrice
  //computes calculatedvalues and compare it to saved values
  //checks if the memory overlap corrupts the value or not
 function store_price_test(
    uint64 logPriceSeed,
    uint216 sqrtPriceSeed,
    uint216 sqrtInversePriceSeed
  ) public {

    (X59 logPrice,
    X216 sqrtPrice,
    X216 sqrtInversePrice,
    X59 logResult,
    X216 sqrtResult,
    X216 sqrtInverseResult)  = testUtilities.storePriceWrap(logPriceSeed, sqrtPriceSeed, sqrtInversePriceSeed);
    
    assert(logResult == logPrice);

    assert(sqrtResult == sqrtPrice);

    assert(sqrtInverseResult == sqrtInversePrice);

    //sanitycheck:
    //changed (logResult != logPrice): test failed
    //changed corelogic pointers by 1 byte: test failed(overlap happened)
  }


  //checks if nearby memory is corrupted while saving values or not
  //add guards in memory
  //check before/after values of both guards
  function memory_corruption_test(
    uint256 pointerSeed,
    uint64 logPriceSeed,
    uint216 sqrtPriceSeed,
    uint216 sqrtInversePriceSeed
    ) public {
    //returns leftGuard and rightGuard after the storePrice function is called
    (bytes32 leftGuardAfter, bytes32 rightGuardAfter)  = testUtilities.memory_corruption_wrap(pointerSeed,logPriceSeed, sqrtPriceSeed, sqrtInversePriceSeed);
    
    //checks if the after before values of guards are same or not
    assert(leftGuardAfter == keccak256("LEFT"));

    assert(rightGuardAfter == keccak256("RIGHT"));

    //sanitycheck:
    //changed keccak256("LEFT") to keccak256("L"),: error
    //changed assert(rightGuardAfter == keccak256("RIGHT")) to assert(rightGuardAfter != keccak256("RIGHT"))
    //:gave error
    //changed corelogic pointers by 1byte: error
  }

}

