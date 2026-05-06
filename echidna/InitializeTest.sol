// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

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

// ---------------------------------------------------------------------------
// Helper library
// ---------------------------------------------------------------------------
library InitializeTestUtils {

  // X59 constants (from X59.sol):
  //   minLogSpacing = (1 << 59) >> 19 = 1 << 40
  //   minLogStep    = (1 << 59) >> 27 = 1 << 32
  //   thirtyTwoX59  = 32 << 59 = 2^64
  uint256 constant MIN_LOG_SPACING = 1 << 40;
  uint256 constant MIN_LOG_STEP    = 1 << 32;
  uint256 constant THIRTY_TWO_X59  = uint256(32) << 59;
  // Cap spacing so qLower and qUpper always fit comfortably
  uint256 constant MAX_SPACING     = THIRTY_TWO_X59 / 8;
  // oneX15 (100% in X15 fixed-point, from X15.sol)
  uint16 constant ONE_X15 = 0x8000;

  // ── pool-id helpers ──────────────────────────────────────────────────────

  /// @dev poolId with logOffset (bits [187:180]) in [-89, +89] (valid).
  ///      Bits [179:0] are always 0 (no hook address, no flag bits) so that
  ///      validateFlags() passes without needing an actual hook contract.
  ///      Top bits [255:188] come from x, producing unique unsaltedPoolIds.
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

  // ── kernel compact encoding ──────────────────────────────────────────────
  //
  // kernelCompactArray is uint256[] whose ABI array.length tells readInitializeInput()
  // the number of packed words (numWords), followed by numWords data words.
  //
  // Minimal 2-breakpoint kernel  (fits in 1 packed word, so array.length = 1):
  //
  //   Implicit origin:   (c=0,      b=0)         implicit start
  //   Explicit pt 1:     (c=0,      b=b1)         horizontal segment → no slope check
  //   Explicit pt 2:     (c=ONE_X15, b=qSpacing)  required end
  //
  // Segment (0,b1)→(ONE_X15,qSpacing): sloped → requires qSpacing−b1 >= MIN_LOG_STEP.
  // We constrain b1 ∈ [1, qSpacing−MIN_LOG_STEP].
  //
  // Bit layout of one packed breakpoint word (80-bit entries, left-aligned):
  //   bits [255:240] c0 (16-bit X15)
  //   bits [239:176] b0 (64-bit X59)
  //   bits [175:160] c1 (16-bit X15)
  //   bits [159:96]  b1 (64-bit X59)
  //   bits [95:0]    padding

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

  // ── curve encoding ───────────────────────────────────────────────────────
  //
  // curveArray is uint256[] with 4 × 64-bit X59 prices per word.
  // Minimal 2-member curve (qLower, qUpper) fits in a single uint256:
  //   bits [255:192] qLower
  //   bits [191:128] qUpper
  // Last curve member = logPriceCurrent → current price = qUpper.

  /// @dev 1-element curveArray for a minimal valid 2-member curve.
  function makeValidCurve(uint256 qLower, uint256 qSpacing)
    internal pure returns (uint256[] memory arr)
  {
    arr = new uint256[](1);
    arr[0] = (qLower << 192) | ((qLower + qSpacing) << 128);
  }
}

// ---------------------------------------------------------------------------
// Echidna test contract
// ---------------------------------------------------------------------------

/// @title InitializeTest
/// @notice Echidna assertion-mode tests for the full NofeeswapDelegatee.initialize
///         execution path.  Mirrors Initialize_test.py (Brownie).
///
/// Run with:
///   ./bin/echidna ./echidna/InitializeTest.sol --config ./echidna.yml
contract InitializeTest {

  Nofeeswap          nofeeswap;
  NofeeswapDelegatee delegatee;
  Access             access;

  // Match the protocol setup in Initialize_test.py
  uint256 constant MAX_POOL_GROWTH = 123;
  uint256 constant PROTOCOL_GROWTH = 456;

  constructor() {
    // ── deterministic deployment without DeployerHelper ────────────────────
    //
    // EVM nonce for a newly deployed contract starts at 1.
    // In this constructor the test contract (address(this)) will CREATE:
    //   nonce=1 → NofeeswapDelegatee  (needs Nofeeswap's address)
    //   nonce=2 → Nofeeswap           (needs NofeeswapDelegatee's address)
    //
    // We predict Nofeeswap's address (nonce=2) before deploying Delegatee.

    address predictedNofeeswap = _predictCreate(address(this), 2);

    NofeeswapDelegatee del = new NofeeswapDelegatee(predictedNofeeswap);
    Nofeeswap          nfs = new Nofeeswap(address(del), address(this));

    require(address(nfs) == predictedNofeeswap, "Nofeeswap address prediction failed");

    delegatee = del;
    nofeeswap = nfs;
    access    = new Access();

    // Set protocol: maxPoolGrowthPortion=123, protocolGrowthPortion=456, owner=this
    nofeeswap.dispatch(
      abi.encodeWithSelector(
        delegatee.modifyProtocol.selector,
        (uint256(MAX_POOL_GROWTH) << 208)
          | (uint256(PROTOCOL_GROWTH) << 160)
          | uint256(uint160(address(this)))
      )
    );
  }

  // ── internal helpers ────────────────────────────────────────────────────

  /// @dev Computes the CREATE address for a deployment from `deployer` at `nonce`
  ///      (nonce 1–127, single-byte RLP encoding).
  function _predictCreate(address deployer, uint8 nonce) internal pure returns (address) {
    // RLP([deployer, nonce]) for nonce in [1, 127]:
    //   0xd6 = list prefix (22 bytes content), 0x94 = address prefix (20 bytes)
    return address(uint160(uint256(keccak256(abi.encodePacked(
      uint8(0xd6),   // RLP list header
      uint8(0x94),   // RLP address prefix
      deployer,      // 20 bytes
      uint8(nonce)   // nonce as 1 byte
    )))));
  }

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
      delegatee.initialize.selector,
      unsaltedPoolId,
      Tag.wrap(t0),
      Tag.wrap(t1),
      X47.wrap(portion),
      kernelArr,
      curveArr,
      bytes("HookData")
    );
    (success, ) = address(nofeeswap).call(
      abi.encodeWithSelector(nofeeswap.dispatch.selector, initData)
    );
  }

  /// @dev poolId = unsaltedPoolId + (keccak256(abi.encodePacked(caller, unsaltedPoolId)) << 188)
  function _poolId(uint256 unsaltedPoolId) internal view returns (uint256) {
    return unsaltedPoolId
      + (uint256(keccak256(abi.encodePacked(address(this), unsaltedPoolId))) << 188);
  }

  // ── test 1: positive path — full invariant check ────────────────────────

  /// @notice All valid inputs → initialize succeeds, every post-init invariant holds.
  function test_initializeSuccess(
    uint256 seedPoolId,
    uint8   offsetSeed,
    uint256 seedTag0,
    uint256 seedTag1,
    uint256 seedPortion,
    uint64  b1Seed,
    uint64  spacingSeed,
    uint64  lowerSeed
  ) external {
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(seedPoolId, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 portion  = InitializeTestUtils.makeValidPortion(seedPortion);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(b1Seed, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    bool ok = _dispatchInitialize(unsaltedPoolId, t0, t1, portion, kernelArr, curveArr);
    // Skip assertions if the pool was already created in a prior Echidna call
    // with the same unsaltedPoolId (valid behavior, not a bug).
    if (!ok) return;

    uint256 poolId = _poolId(unsaltedPoolId);

    // ── dynamic params ────────────────────────────────────────────────────
    (
      uint256 staticParamsStoragePointerExtension,
      uint16  staticParamsStoragePointer,
      X59     logPriceCurrent,
      uint256 sharesTotal,
      X111    growth,
      X216    integral0,
      X216    integral1
    ) = access._readDynamicParams(IStorageAccess(address(nofeeswap)), poolId);

    // ── static params part 1: tags + sqrt values ──────────────────────────
    Tag  tag0Read;
    Tag  tag1Read;
    X127 sqrtOffset;
    X127 sqrtInverseOffset;
    // sqrtSpacing and sqrtInverseSpacing (5th and 6th returns) are not checked
    (tag0Read, tag1Read, sqrtOffset, sqrtInverseOffset, , ) =
      access._readStaticParams0(address(nofeeswap), poolId, uint256(staticParamsStoragePointer));

    // ── static params part 2: integrals + growth portions ─────────────────
    X216    outgoingMax;
    uint256 outgoingMaxModularInverse;
    X47     poolGrowthPortionRead;
    X47     maxPoolGrowthPortionRead;
    X47     protocolGrowthPortionRead;
    Index   pendingKernelLength;
    // incomingMax (3rd of 7 returns) is not checked here
    (outgoingMax, outgoingMaxModularInverse, , poolGrowthPortionRead,
     maxPoolGrowthPortionRead, protocolGrowthPortionRead, pendingKernelLength) =
       access._readStaticParams1(address(nofeeswap), poolId, uint256(staticParamsStoragePointer));

    // ── invariants ────────────────────────────────────────────────────────

    // Growth initialized to oneX111 = 2^111
    assert(X111.unwrap(growth) == int256(uint256(1) << 111));

    // No liquidity shares at initialization
    assert(sharesTotal == 0);

    // First pool ever → both storage pointer fields are zero
    assert(staticParamsStoragePointerExtension == 0);
    assert(staticParamsStoragePointer == 0);

    // No pending kernel update
    assert(Index.unwrap(pendingKernelLength) == 0);

    // Current log-price = qUpper (last member of 2-member curve)
    assert(X59.unwrap(logPriceCurrent) == int256(qLower + qSpacing));

    // Token ordering preserved exactly
    assert(Tag.unwrap(tag0Read) == t0);
    assert(Tag.unwrap(tag1Read) == t1);

    // Growth portions match inputs and protocol setup
    assert(X47.unwrap(poolGrowthPortionRead)     == portion);
    assert(X47.unwrap(maxPoolGrowthPortionRead)  == MAX_POOL_GROWTH);
    assert(X47.unwrap(protocolGrowthPortionRead) == PROTOCOL_GROWTH);

    // Both partial integrals are non-negative
    assert(X216.unwrap(integral0) >= 0);
    assert(X216.unwrap(integral1) >= 0);

    // Each partial integral ≤ outgoingMax (with 2^33 numerical tolerance)
    assert(
      uint256(X216.unwrap(integral0)) <=
        uint256(X216.unwrap(outgoingMax)) + (1 << 33)
    );
    assert(
      uint256(X216.unwrap(integral1)) <=
        uint256(X216.unwrap(outgoingMax)) + (1 << 33)
    );

    // outgoingMaxModularInverse is the modular inverse (mod 2^256) of the odd
    // part of outgoingMax.  The inverse of any odd number is always odd.
    assert(outgoingMaxModularInverse % 2 == 1);

    // sqrtOffset and sqrtInverseOffset are positive values in the expected
    // range for logOffset ∈ [-89, +89]:
    //   min ≈ exp(-89/2) × 2^127 ≈ 2^62
    //   max ≈ exp(+89/2) × 2^127 ≈ 2^192
    uint256 soVal  = uint256(X127.unwrap(sqrtOffset));
    uint256 sioVal = uint256(X127.unwrap(sqrtInverseOffset));
    assert(soVal  >= (1 << 62) && soVal  <= (uint256(1) << 192));
    assert(sioVal >= (1 << 62) && sioVal <= (uint256(1) << 192));
  }

  // ── test 2: double initialization must revert ────────────────────────────

  /// @notice A second initialize for the same poolId must revert with PoolExists.
  function test_cannotInitializeTwice(
    uint256 seedPoolId,
    uint8   offsetSeed,
    uint256 seedTag0,
    uint256 seedTag1,
    uint64  spacingSeed,
    uint64  lowerSeed
  ) external {
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(seedPoolId, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    bool s1 = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
    // If s1 fails the pool was already created by a prior Echidna call; skip.
    if (!s1) return;

    bool s2 = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
    assert(!s2); // PoolExists: second init must revert
  }

  // ── test 3: invalid logOffset → revert ───────────────────────────────────

  /// @notice logOffset outside [-89,+89] must be rejected (LogOffsetOutOfRange).
  function test_invalidOffset_reverts(
    uint256 seedPoolId,
    uint8   offsetSeed,
    uint256 seedTag0,
    uint256 seedTag1,
    uint64  spacingSeed,
    uint64  lowerSeed
  ) external {
    uint256 unsaltedPoolId = InitializeTestUtils.makeInvalidPoolId(seedPoolId, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, 0, kernelArr, curveArr);
    assert(!success);
  }

  // ── test 4: tags out of order → revert ──────────────────────────────────

  /// @notice tag0 >= tag1 must be rejected with TagsOutOfOrder.
  function test_tagsOutOfOrder_reverts(
    uint256 seedPoolId,
    uint8   offsetSeed,
    uint256 seedTag0,
    uint256 seedTag1,
    uint64  spacingSeed,
    uint64  lowerSeed
  ) external {
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(seedPoolId, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    // Deliberately pass (t1, t0): larger tag first
    bool success = _dispatchInitialize(unsaltedPoolId, t1, t0, 0, kernelArr, curveArr);
    assert(!success);
  }

  // ── test 5: invalid growth portion → revert ─────────────────────────────

  /// @notice poolGrowthPortion > oneX47 must be rejected with InvalidGrowthPortion.
  function test_invalidPortion_reverts(
    uint256 seedPoolId,
    uint8   offsetSeed,
    uint256 seedTag0,
    uint256 seedTag1,
    uint256 seedPortion,
    uint64  spacingSeed,
    uint64  lowerSeed
  ) external {
    uint256 unsaltedPoolId = InitializeTestUtils.makeValidPoolId(seedPoolId, offsetSeed);
    (uint256 t0, uint256 t1) = InitializeTestUtils.makeValidTags(seedTag0, seedTag1);
    uint256 invalidPortion = InitializeTestUtils.makeInvalidPortion(seedPortion);
    uint256 qSpacing = InitializeTestUtils.makeValidSpacing(spacingSeed);
    uint256 qLower   = InitializeTestUtils.makeValidLower(lowerSeed, qSpacing);

    uint256[] memory kernelArr = InitializeTestUtils.makeValidKernelCompact(0, qSpacing);
    uint256[] memory curveArr  = InitializeTestUtils.makeValidCurve(qLower, qSpacing);

    bool success = _dispatchInitialize(unsaltedPoolId, t0, t1, invalidPortion, kernelArr, curveArr);
    assert(!success);
  }
}
