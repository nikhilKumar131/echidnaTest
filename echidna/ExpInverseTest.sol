// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../contracts/utilities/X59.sol";
import "../exp_analysis/ground_truth.sol";
import "./FuzzUtilities.sol";

contract ExpInverseTest {

  function expInverse_accuracy_test(uint64 seed) public pure {
    // expInverse valid range: (0, 2^64) raw X59 value

    X59 val = get_a_logPrice(seed);

    uint256 expInverseResult = X59Library.expInverse(val);
    uint256 expDecayResult = ExpDecay.compute(uint256(X59.unwrap(val)));

    uint256 abs_difference = expInverseResult > expDecayResult
      ? expInverseResult - expDecayResult
      : expDecayResult - expInverseResult;

    // tolerance: 2^40 out of 2^256 scale = 216 bits of precision
    assert(abs_difference < 2**40);
  }

  function exp_values_test(uint64 seed) public pure {
    //compares the output of X59.exp with the ground truth values of expinverse and exponentialOver16
  
    
    X59 val = get_a_logPrice(seed);
    (X216 expInverseResult, X216 expOver16Result) = X59Library.exp(val);

    uint256 expInverseResultUnwrapped = uint256(X216.unwrap(expInverseResult));
    uint256 expOver16ResultUnwrapped = uint256(X216.unwrap(expOver16Result));

    uint256 expInverseGroundTruth = ExpDecay.compute(uint256(X59.unwrap(val))) >> 40;
    uint256 expOver16GroundTruth = ExpDecay.compute(uint256(int256(2**64) - X59.unwrap(val))) >> 40;

    uint256 diff = expInverseResultUnwrapped > expInverseGroundTruth
    ? expInverseResultUnwrapped - expInverseGroundTruth
    : expInverseGroundTruth - expInverseResultUnwrapped;

    uint256 diffOver16 = expOver16ResultUnwrapped > expOver16GroundTruth
    ? expOver16ResultUnwrapped - expOver16GroundTruth
    : expOver16GroundTruth - expOver16ResultUnwrapped;

    // assert( expInverseResultUnwrapped == expInverseGroundTruth );
    // assert( expOver16ResultUnwrapped  expOver16GroundTruth );
    assert(diff <= 1);
    assert(diffOver16 <= 1);
  }

}
