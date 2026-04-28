// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/utilities/X59.sol";
import "./ground_truth.sol";

contract expInverseAnalysis {

  // import expinverse
  function exp_inverse(X59 _val) public pure returns(uint256){
    uint256 a = X59Library.expInverse(_val);
    return a;
  }
  // import exp_decay
  function exp_decay(uint256 _val) public pure returns(uint256){
    uint256 a = ExpDecay.compute(_val);
    return a;
  }

  //function that compares the output

  function compareExpInverse(X59 _val) public pure returns(bool){
    uint256 expInverseResult = exp_inverse(_val);
    uint256 val_unwrapped = uint256(X59.unwrap(_val)); 
    uint256 expDecayResult = exp_decay(val_unwrapped);

    uint256 abs_difference = expInverseResult > expDecayResult ? expInverseResult - expDecayResult : expDecayResult - expInverseResult;

    // 2^40 an acceptable tolerance level
    // this proves that the expInverse function is accurate upto 2^216

    return abs_difference < 2**40;
  }


}