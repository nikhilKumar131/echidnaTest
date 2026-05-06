// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.34;

//imports
import {Nofeeswap} from "../contracts/Nofeeswap.sol";
import {NofeeswapDelegatee} from "../contracts/NofeeswapDelegatee.sol";
import {Access} from "../contracts/helpers/Access.sol";

import {IStorageAccess} from "../contracts/interfaces/IStorageAccess.sol";
import {Tag} from "../contracts/utilities/Tag.sol";
import {X47} from "../contracts/utilities/X47.sol";
import {X59} from "../contracts/utilities/X59.sol";
import {X111} from "../contracts/utilities/X111.sol";
import {X127} from "../contracts/utilities/X127.sol";
import {X216} from "../contracts/utilities/X216.sol";
import {Index} from "../contracts/utilities/Index.sol";



// Helper library
library InitializeTestUtils {


  uint256 constant MIN_LOG_SPACING = 1 << 40;
  uint256 constant MIN_LOG_STEP    = 1 << 32;
  uint256 constant THIRTY_TWO_X59  = uint256(32) << 59;
  // Cap spacing so qLower and qUpper always fit comfortably
  uint256 constant MAX_SPACING     = THIRTY_TWO_X59 / 8;
  // oneX15 (100% in X15 fixed-point, from X15.sol)
  uint16 constant ONE_X15 = 0x8000;

  // ── pool-id helpers ──────────────────────────────────────────────────────

  function makeValidPoolId(uint256 x, uint8 offsetSeed) internal pure returns (uint256) {
    uint8 validByte = uint8(
      (offsetSeed % 180) < 90 ? (offsetSeed % 90) : ((offsetSeed % 90) + 167)
    );
    // bits [255:188] from x (uniqueness), [187:180] = logOffset, [179:0] = 0
    return ((x >> 188) << 188) | (uint256(validByte) << 180);
  }

  /// @dev poolId with logOffset (bits [187:180]) in [90, 166] (invalid range).
  function makeInvalidPoolId(uint256 x, uint8 offsetSeed) internal pure returns (uint256) {
    // 77 invalid unsigned byte values: [90,127] (too positive) + [128,166] (too negative)
    uint8 invalidByte = uint8(90 + (uint256(offsetSeed) % 77));
    uint256 mask = uint256(0xFF) << 180;
    return (x & ~mask) | (uint256(invalidByte) << 180);
  }

  // ── tag helpers ──────────────────────────────────────────────────────────

  /// @dev Returns (t0, t1) with t0 < t1 always.
  function makeValidTags(uint256 s0, uint256 s1)
    internal pure returns (uint256 t0, uint256 t1)
  {
    if (s0 == s1) return s0 == 0 ? (s0, s0 + 1) : (s0 - 1, s0);
    return s0 < s1 ? (s0, s1) : (s1, s0);
  }

  // ── portion helpers ──────────────────────────────────────────────────────

  /// @dev Valid portion in [0, 2^47] (= oneX47).
  function makeValidPortion(uint256 seed) internal pure returns (uint256) {
    return seed % ((1 << 47) + 1);
  }

  /// @dev Invalid portion > 2^47.
  function makeInvalidPortion(uint256 seed) internal pure returns (uint256) {
    return (1 << 47) + 1 + (seed % (type(uint256).max - (1 << 47)));
  }

  // ── spacing and lower-bound helpers ─────────────────────────────────────

  /// @dev Valid qSpacing in [MIN_LOG_SPACING, MAX_SPACING].
  function makeValidSpacing(uint64 spacingSeed) internal pure returns (uint256) {
    return MIN_LOG_SPACING + (uint256(spacingSeed) % (MAX_SPACING - MIN_LOG_SPACING + 1));
  }

  /// @dev Valid qLower such that qLower > qSpacing and qLower+2*qSpacing < THIRTY_TWO_X59.
  function makeValidLower(uint64 lowerSeed, uint256 qSpacing) internal pure returns (uint256) {
    uint256 minL = qSpacing + 1;
    uint256 maxL = THIRTY_TWO_X59 - 2 * qSpacing - 1;
    if (minL >= maxL) return minL;
    return minL + (uint256(lowerSeed) % (maxL - minL));
  }

  /// @dev 1-element kernelCompactArray for a minimal valid 2-breakpoint kernel.
  ///      First breakpoint has height 0 (horizontal first segment, avoids slope check).
  function makeValidKernelCompact(uint64 b1Seed, uint256 qSpacing)
    internal pure returns (uint256[] memory arr)
  {
    uint256 maxB1 = qSpacing - MIN_LOG_STEP; // inclusive upper bound for b1
    uint256 b1 = 1 + (uint256(b1Seed) % maxB1); // b1 ∈ [1, maxB1]

    arr = new uint256[](1);
    // h1=0, b1, h2=ONE_X15, b2=qSpacing packed left-aligned
    arr[0] = (b1 << 176) | (uint256(ONE_X15) << 160) | (qSpacing << 96);
  }


  /// @dev 1-element curveArray for a minimal valid 2-member curve.
  function makeValidCurve(uint256 qLower, uint256 qSpacing)
    internal pure returns (uint256[] memory arr)
  {
    arr = new uint256[](1);
    arr[0] = (qLower << 192) | ((qLower + qSpacing) << 128);
  }

  // ── poolId derivation ────────────────────────────────────────────────────

  /// @dev Replicates the protocol's poolId salting formula.
  /// poolId = unsaltedPoolId + (keccak256(abi.encodePacked(caller, unsaltedPoolId)) << 188)
  function makePoolId(address caller, uint256 unsaltedPoolId)
    internal pure returns (uint256 poolId)
  {
    unchecked {
      poolId = unsaltedPoolId + (
        uint256(keccak256(abi.encodePacked(caller, unsaltedPoolId))) << 188
      );
    }
  }

  // ── invalid flags helpers ────────────────────────────────────────────────

  // Flag bit positions are relative to bit 160 of the poolId.
  // bit 0 (0x1): isPreInitialize   bit 1 (0x2): isPostInitialize
  // bit 2 (0x4): isPreMint         (and so on for other callbacks)
  uint256 constant FLAG_PRE_INITIALIZE  = 0x1;
  uint256 constant FLAG_POST_INITIALIZE = 0x2;
  uint256 constant FLAG_PRE_MINT        = 0x4; // a non-init callback flag

  /// @dev Hook present, zero flags → hook↔flags symmetry violated → InvalidFlags.
  function makeInvalidFlags_hookNoFlags(uint256 baseId, address hook)
    internal pure returns (uint256)
  {
    // makeValidPoolId leaves bits[179:0] = 0; OR in hook address only, no flags.
    return baseId | uint256(uint160(hook));
  }

  /// @dev Non-zero flags, no hook → hook↔flags symmetry violated → InvalidFlags.
  function makeInvalidFlags_flagsNoHook(uint256 baseId)
    internal pure returns (uint256)
  {
    // Set isPreMint (bit 2) — not isPreInitialize — so hook==0 but flags!=0.
    return baseId | (FLAG_PRE_MINT << 160);
  }

  /// @dev Hook present + only non-init flags → isPreInitialize/isPostInitialize both zero → InvalidFlags.
  function makeInvalidFlags_hookNoInitFlag(uint256 baseId, address hook)
    internal pure returns (uint256)
  {
    // isPreMint set but neither isPreInitialize nor isPostInitialize.
    return baseId | (FLAG_PRE_MINT << 160) | uint256(uint160(hook));
  }

  // ── invalid curve helpers ────────────────────────────────────────────────

  /// @dev Step < MIN_LOG_SPACING → LogSpacingIsTooSmall.
  function makeInvalidCurve_spacingTooSmall(uint256 qLower, uint256 spacingSeed)
    internal pure returns (uint256[] memory arr)
  {
    uint256 step = spacingSeed % MIN_LOG_SPACING; // [0, 2^40 - 1]
    arr = new uint256[](1);
    arr[0] = (qLower << 192) | ((qLower + step) << 128);
  }

  /// @dev qLower ∈ [0, qSpacing-1] → violates qLower > qSpacing (BlankIntervalsShouldBeAvoided).
  function makeInvalidCurve_lowerTooSmall(uint256 lowerSeed, uint256 qSpacing)
    internal pure returns (uint256[] memory arr)
  {
    uint256 qLower = lowerSeed % qSpacing; // qLower < qSpacing
    arr = new uint256[](1);
    arr[0] = (qLower << 192) | ((qLower + qSpacing) << 128);
  }

  /// @dev qUpper ∈ [THIRTY_TWO_X59 - qSpacing, THIRTY_TWO_X59 - 1] → violates qUpper < threshold.
  function makeInvalidCurve_upperTooLarge(uint256 qSpacing, uint256 overflowSeed)
    internal pure returns (uint256[] memory arr)
  {
    uint256 qUpper = THIRTY_TWO_X59 - qSpacing + (overflowSeed % qSpacing);
    uint256 qLower = qUpper - qSpacing;
    arr = new uint256[](1);
    arr[0] = (qLower << 192) | (qUpper << 128);
  }

  /// @dev 3rd member = qLower (not strictly inside (qLower, qUpper)) → InvalidCurveArrangement.
  function makeInvalidCurve_badArrangement(uint256 qLower, uint256 qSpacing)
    internal pure returns (uint256[] memory arr)
  {
    uint256 qUpper = qLower + qSpacing;
    arr = new uint256[](1);
    // q2 = qLower: equal to lower bound, fails strict q0 < q2 < q1
    arr[0] = (qLower << 192) | (qUpper << 128) | (qLower << 64);
  }


}

//deployment library
library Deployment{

	//function that pre-computes the address of the deployed contract
  function _predictCreate(address deployer, uint8 nonce) internal pure returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(
      uint8(0xd6),   // RLP list header
      uint8(0x94),   // RLP address prefix
      deployer,      // 20 bytes
      uint8(nonce)   // nonce as 1 byte
    )))));
  }

  // Match the protocol setup in Initialize_test.py
  uint256 constant MAX_POOL_GROWTH = 123;
  uint256 constant PROTOCOL_GROWTH = 456;

	//struct of deployable contracts
	struct deployableContracts{
  Nofeeswap          nofeeswap;
  NofeeswapDelegatee delegatee;
  Access             access;
	}


}

contract Test{

	//helper internal
  /// @dev Builds and dispatches an initialize call; returns success flag.
  function _dispatchInitialize(
    uint256 unsaltedPoolId,
    uint256 t0,
    uint256 t1,
    uint256 portion,
    uint256[] memory kernelArr,
    uint256[] memory curveArr
  	) internal returns (bool success) {
    bytes memory initData = abi.encodeWithSelector(
      deployableContracts.delegatee.initialize.selector,
      unsaltedPoolId,
      Tag.wrap(t0),
      Tag.wrap(t1),
      X47.wrap(portion),
      kernelArr,
      curveArr,
      bytes("HookData")
    );
    (success, ) = address(deployableContracts.nofeeswap).call(
      abi.encodeWithSelector(deployableContracts.nofeeswap.dispatch.selector, initData)
    );
  }

	//run deployment function
	Deployment.deployableContracts deployableContracts;
  uint256 private _poolNonce;

	constructor(){

    address preComputedNofeeswapAddress = Deployment._predictCreate(address(this), 2);


    deployableContracts.delegatee = new NofeeswapDelegatee(preComputedNofeeswapAddress);
    deployableContracts.nofeeswap = new Nofeeswap(address(deployableContracts.delegatee), address(this));

    require(address(deployableContracts.nofeeswap) == preComputedNofeeswapAddress, "Nofeeswap address prediction failed");

		deployableContracts.access = new Access();

    // Set protocol: maxPoolGrowthPortion=123, protocolGrowthPortion=456, owner=this
    deployableContracts.nofeeswap.dispatch(
      abi.encodeWithSelector(
        deployableContracts.delegatee.modifyProtocol.selector,
        (uint256(Deployment.MAX_POOL_GROWTH) << 208)
          | (uint256(Deployment.PROTOCOL_GROWTH) << 160)
          | uint256(uint160(address(this)))
      )
    );

	}

	// //create the test
	// /// @notice tag0 >= tag1 must be rejected with TagsOutOfOrder.
  // function test_tagsOutOfOrder_reverts(
  //   uint256 seedPoolId,
  //   uint8   offsetSeed,
  //   uint256 seedTag0,
  //   uint256 seedTag1,
  //   uint64  spacingSeed,
  //   uint64  lowerSeed
  // 	) external {
	// 	//this ensures 100 percent fuzzing
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
  //   (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

  //   // Deliberately pass (t1, t0): larger tag first — must always revert TagsOutOfOrder
  //   bool success = _dispatchInitialize(unsaltedPoolId, t1, t0, 0, kernelArr, curveArr);
  //   assert(!success);
  // }


  // /// @notice logOffset outside [-89,+89] must be rejected (LogOffsetOutOfRange).
  // function test_invalidOffset_reverts(
  //   uint256 seedPoolId,
  //   uint8   offsetSeed,
  //   uint256 seedTag0,
  //   uint256 seedTag1,
  //   uint64  spacingSeed,
  //   uint64  lowerSeed
  // ) external {
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeInvalidPoolId(seedPoolId, offsetSeed);
  //   (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

  //   bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
  //   assert(!success);
  // }


  // /// @notice poolGrowthPortion > oneX47 must be rejected with InvalidGrowthPortion.
  // function test_invalidPortion_reverts(
  //   uint256 seedPoolId,
  //   uint8   offsetSeed,
  //   uint256 seedTag0,
  //   uint256 seedTag1,
  //   uint256 seedPortion,
  //   uint64  spacingSeed,
  //   uint64  lowerSeed
  // ) external {
	// 	//this ensures 100 percent fuzzing
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
	// 	(uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 invalidPortion = InitializeTestUtils.makeInvalidPortion(seedPortion);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

  //   bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, invalidPortion, kernelArr, curveArr);
  //   assert(!success);
  // }

  // /// @notice A second initialize for the same poolId must revert with PoolExists.
  // function test_cannotInitializeTwice(
  //   uint256 seedPoolId,
  //   uint8   offsetSeed,
  //   uint256 seedTag0,
  //   uint256 seedTag1,
  //   uint64  spacingSeed,
  //   uint64  lowerSeed
  // ) external {
	// 	//this ensures 100 percent fuzzing
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
	// 	(uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

	// 	//s1 is always never going to revert as poolId will always be unique
  //   bool s1 = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
	// 	assert(s1);

	// 	//always reverts as same poolId is used again
  //   bool s2 = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
  //   assert(!s2); // PoolExists: second init must revert
  // }


  // /// @notice Curve step < minLogSpacing must revert (LogSpacingIsTooSmall).
  // function test_invalidCurve_spacingTooSmall(
  //   uint256 seedPoolId, uint8 offsetSeed,
  //   uint256 seedTag0,   uint256 seedTag1,
  //   uint64  spacingSeed, uint64 lowerSeed, uint64 badSpacingSeed
  // ) external {
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
  //   (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);
  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeInvalidCurve_spacingTooSmall(qLower, badSpacingSeed);
  //   bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
  //   assert(!success);
  // }

  // /// @notice qLower <= qSpacing must revert (BlankIntervalsShouldBeAvoided).
  // function test_invalidCurve_lowerTooSmall(
  //   uint256 seedPoolId, uint8 offsetSeed,
  //   uint256 seedTag0,   uint256 seedTag1,
  //   uint64  spacingSeed, uint64 badLowerSeed
  // ) external {
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
  //   (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeInvalidCurve_lowerTooSmall(badLowerSeed, qSpacing);
  //   bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
  //   assert(!success);
  // }

  // /// @notice qUpper >= thirtyTwoX59 - qSpacing must revert (BlankIntervalsShouldBeAvoided).
  // function test_invalidCurve_upperTooLarge(
  //   uint256 seedPoolId, uint8 offsetSeed,
  //   uint256 seedTag0,   uint256 seedTag1,
  //   uint64  spacingSeed, uint64 overflowSeed
  // ) external {
  //   uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
  //   uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
  //   (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
  //   uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
  //   uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
  //   uint256[] memory curveArr  = InitializeTestUtils.makeInvalidCurve_upperTooLarge(qSpacing, overflowSeed);
  //   bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
  //   assert(!success);
  // }

  /// @notice 3rd curve member outside (qLower, qUpper) must revert (InvalidCurveArrangement).
  function test_invalidCurve_badArrangement(
    uint256 seedPoolId, uint8 offsetSeed,
    uint256 seedTag0,   uint256 seedTag1,
    uint64  spacingSeed, uint64 lowerSeed
  ) external {
    uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);
    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeInvalidCurve_badArrangement(qLower, qSpacing);
    bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
    assert(!success);

		curveArr = InitializeTestUtils.makeInvalidCurve_lowerTooSmall(qLower, qSpacing);
		success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
		assert(!success);

		curveArr = InitializeTestUtils.makeInvalidCurve_spacingTooSmall(qLower, qSpacing);
		success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
		assert(!success);

		curveArr = InitializeTestUtils.makeInvalidCurve_upperTooLarge(qSpacing, qLower);
		success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
		assert(!success);

  }

  /// @notice Any of the 3 invalid flag configurations must revert with InvalidFlags.
  function test_invalidFlags_reverts(
    uint256 seedPoolId, uint8 offsetSeed,
    uint256 seedTag0,   uint256 seedTag1,
    uint64  spacingSeed, uint64 lowerSeed
  ) external {
    uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);
    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    // Case 1: hook address present, no flags → symmetry check fails
    uint256 flaggedId = InitializeTestUtils.makeInvalidFlags_hookNoFlags(unsaltedPoolId, address(this));
    bool success = _dispatchInitialize(flaggedId, t0, t1, 0, kernelArr, curveArr);
    assert(!success);

    // Case 2: flags set, no hook address → symmetry check fails
    flaggedId = InitializeTestUtils.makeInvalidFlags_flagsNoHook(unsaltedPoolId);
    success = _dispatchInitialize(flaggedId, t0, t1, 0, kernelArr, curveArr);
    assert(!success);

    // Case 3: hook present, non-init flags only, neither isPreInitialize nor isPostInitialize set
    flaggedId = InitializeTestUtils.makeInvalidFlags_hookNoInitFlag(unsaltedPoolId, address(this));
    success = _dispatchInitialize(flaggedId, t0, t1, 0, kernelArr, curveArr);
    assert(!success);

  }

  /// @notice Valid inputs must always produce a successful initialization with correct post-state.
  function test_validInitialize_succeeds(
    uint256 seedPoolId, uint8 offsetSeed,
    uint256 seedTag0,   uint256 seedTag1,
    uint64  spacingSeed, uint64 lowerSeed
  ) external {
    uint256 mixedSeed = uint256(keccak256(abi.encodePacked(seedPoolId, _poolNonce++)));
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(mixedSeed, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);
    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
    assert(success);

    // The Test contract is msg.sender for all dispatch calls, so poolId is salted with address(this).
    uint256 poolId = InitializeTestUtils.makePoolId(address(this), unsaltedPoolId);

    (
      uint256 staticParamsStoragePointerExtension,
      ,
      X59 logPriceCurrent,
      uint256 sharesTotal,
      X111 growth,
      ,
    ) = deployableContracts.access._readDynamicParams(
        IStorageAccess(address(deployableContracts.nofeeswap)),
        poolId
      );

    // Invariants that hold after every valid initialization
    assert(staticParamsStoragePointerExtension == 0);
    assert(sharesTotal == 0);
    assert(X111.unwrap(growth) == int256(1 << 111));
    // For a 2-member curve [qLower, qLower+qSpacing], logPriceCurrent == last member == qUpper
    assert(X59.unwrap(logPriceCurrent) == int256(qLower + qSpacing));
  }

}

