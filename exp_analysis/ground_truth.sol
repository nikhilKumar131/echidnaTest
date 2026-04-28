// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.0;

import "../contracts/utilities/FullMath.sol"; // must have mul512 contracts/utilities/FullMath.sol

library ExpDecay {

    function compute(uint256 x) internal pure returns (uint256 result) { //exp_ground_truth
    //in fuzz utilities


        //input should not be bigger than 2^64
        //it after 64 bits, input won't have any effect
        //overflow and underflow checks can be added
        


        result = type(uint256).max; // ~ 2^256 - 1 (acts like 2^256 scale) with slight error



        //fullMathLibarary.mul512 => (least significat 2^256, most significant 2^256)
        if ((x & (1 << 0)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffffff0000000000000007ffffffffffffffd555555555555555fff);
        }
        if ((x & (1 << 1)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffffe000000000000001ffffffffffffffeaaaaaaaaaaaaaab5555);
        }
        if ((x & (1 << 2)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffffc000000000000007ffffffffffffff555555555555555fffff);
        }
        if ((x & (1 << 3)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffff800000000000001ffffffffffffffaaaaaaaaaaaaaab555555);
        }
        if ((x & (1 << 4)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffff000000000000007fffffffffffffd55555555555555fffffff);
        }
        if ((x & (1 << 5)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffffe00000000000001fffffffffffffeaaaaaaaaaaaaab55555555);
        }
        if ((x & (1 << 6)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffffc00000000000007fffffffffffff55555555555555fffffffff);
        }
        if ((x & (1 << 7)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffff80000000000001fffffffffffffaaaaaaaaaaaaab5555555555);
        }
        if ((x & (1 << 8)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffff00000000000007ffffffffffffd5555555555555fffffffffff);
        }
        if ((x & (1 << 9)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffe0000000000001ffffffffffffeaaaaaaaaaaaab555555555555);
        }
        if ((x & (1 << 10)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffffc0000000000007ffffffffffff5555555555555fffffffffffff);
        }
        if ((x & (1 << 11)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffff8000000000001ffffffffffffaaaaaaaaaaaab55555555555544);
        }
        if ((x & (1 << 12)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffff0000000000007fffffffffffd555555555555ffffffffffffddd);
        }
        if ((x & (1 << 13)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffe000000000001fffffffffffeaaaaaaaaaaab5555555555551111);
        }
        if ((x & (1 << 14)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffffc000000000007fffffffffff555555555555ffffffffffff77777);
        }
        if ((x & (1 << 15)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffff800000000001fffffffffffaaaaaaaaaaab555555555554444444);
        }
        if ((x & (1 << 16)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffff000000000007ffffffffffd55555555555fffffffffffdddddddd);
        }
        if ((x & (1 << 17)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffe00000000001ffffffffffeaaaaaaaaaab55555555555111111111);
        }
        if ((x & (1 << 18)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffffc00000000007ffffffffff55555555555fffffffffff7777777777);
        }
        if ((x & (1 << 19)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffff80000000001ffffffffffaaaaaaaaaab5555555555444444444445);
        }
        if ((x & (1 << 20)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffff00000000007fffffffffd5555555555ffffffffffdddddddddde38);
        }
        if ((x & (1 << 21)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffe0000000001fffffffffeaaaaaaaaab5555555555111111111127d2);
        }
        if ((x & (1 << 22)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffffc0000000007fffffffff5555555555ffffffffff7777777777d27d2);
        }
        if ((x & (1 << 23)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffff8000000001fffffffffaaaaaaaaab55555555544444444445b05b05);
        }
        if ((x & (1 << 24)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffff0000000007ffffffffd555555555fffffffffddddddddde38e38e38);
        }
        if ((x & (1 << 25)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffe000000001ffffffffeaaaaaaaab55555555511111111127d27d27d2);
        }
        if ((x & (1 << 26)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffffc000000007ffffffff555555555fffffffff777777777d27d27d279e);
        }
        if ((x & (1 << 27)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffff800000001ffffffffaaaaaaaab555555554444444445b05b05b04104);
        }
        if ((x & (1 << 28)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffff000000007fffffffd55555555ffffffffdddddddde38e38e38d68d68);
        }
        if ((x & (1 << 29)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffe00000001fffffffeaaaaaaab555555551111111127d27d27cbfcbfcb);
        }
        if ((x & (1 << 30)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffffc00000007fffffff55555555ffffffff77777777d27d27d2492492493);
        }
        if ((x & (1 << 31)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffff80000001fffffffaaaaaaab5555555444444445b05b05aebaebaebc8b);
        }
        if ((x & (1 << 32)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffff00000007ffffffd5555555fffffffddddddde38e38e38138138152152);
        }
        if ((x & (1 << 33)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffe0000001ffffffeaaaaaab5555555111111127d27d276a76a76c16c16c);
        }
        if ((x & (1 << 34)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffffc0000007ffffff5555555fffffff7777777d27d27cf3cf3cf56f56f563);
        }
        if ((x & (1 << 35)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffff8000001ffffffaaaaaab55555544444445b05b0596596597f97f97e261);
        }
        if ((x & (1 << 36)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffff0000007fffffd555555ffffffdddddde38e38e2be2be2d82d82d549c66);
        }
        if ((x & (1 << 37)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffe000001fffffeaaaaab55555511111127d27d21521522f22f2295b7946f);
        }
        if ((x & (1 << 38)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffffc000007fffff555555ffffff777777d27d279e79e7b87b87acec95ea6fb);
        }
        if ((x & (1 << 39)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffff800001fffffaaaaab555554444445b05b04104105b05b043e7ccc82d38d);
        }
        if ((x & (1 << 40)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffff000007ffffd55555fffffddddde38e38d68d68f08f08c25341efdab8fbb);
        }
        if ((x & (1 << 41)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffe00001ffffeaaaab555551111127d27cbfcbfe5fe5f8986d278883b32810);
        }
        if ((x & (1 << 42)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffffc00007ffff55555fffff77777d27d2492493e93e885a4d0b3718299f991c);
        }
        if ((x & (1 << 43)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffff80001ffffaaaab5555444445b05aebaebc8bc8a56de63f19ef8d63ef3e11);
        }
        if ((x & (1 << 44)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffff00007fffd5555ffffdddde38e38138152151e6e58f6a0745f31d2b44ffd1);
        }
        if ((x & (1 << 45)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffe0001fffeaaab5555111127d276a76c16c10f9f455507ff4e59eae0b49b74);
        }
        if ((x & (1 << 46)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfffc0007fff5555ffff7777d27cf3cf56f563c8083c3dd14fefee723b7cde552);
        }
        if ((x & (1 << 47)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfff8001fffaaab55544445b0596597f97e261c6d26b1524d2b5fba251b1bed3d);
        }
        if ((x & (1 << 48)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfff0007ffd555fffddde38e2be2d82d549cb030fde4780c8ba5d4c942f9675d8);
        }
        if ((x & (1 << 49)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffe001ffeaab55511127d21522f2295b8bc3e72bdf83dfc665624bd38b6095a1);
        }
        if ((x & (1 << 50)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xffc007ff555fff777d279e7b87acecdfdd60a6a1f2240f278b268156aa11c98b);
        }
        if ((x & (1 << 51)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xff801ffaab554445b04105b043e8f48d37cd6eb44b097ac758de9ec8a7e89a70);
        }
        if ((x & (1 << 52)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xff007fd55ffdde38d68f08c257e0ce3f39cd64244ca9510b447cc0144e2b1a83);
        }
        if ((x & (1 << 53)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfe01feab551127cbfe5f89994c44216f70d4017aec234b1fe1d79aef8201f19e);
        }
        if ((x & (1 << 54)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xfc07f55ff77d2493e885eeaa756ad523135569ad22bfc4bfd6fe09972fc98660);
        }
        if ((x & (1 << 55)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xf81fab5445aebc8a58055fcbbb139ae8e0686ad0022ea30aa6272c6f84035f5b);
        }
        if ((x & (1 << 56)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xf07d5fde38151e72f18ff03049ac5d7ea18e81673270e30b6a76da7f924bd6a3);
        }
        if ((x & (1 << 57)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xe1eb51276c110c3c3eb1269f2f5d4afabd8029f1b77328d9d41b38c7b22b96be);
        }
        if ((x & (1 << 58)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0xc75f7cf564105743415cbc9d6368f3b96071095abeaf430dbc067f714a3c1787);
        }
        if ((x & (1 << 59)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0x9b4597e37cb04ff3d675a35530cdd767e347bf8ad0e80abbce4ae95861014318);
        }
        if ((x & (1 << 60)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0x5e2d58d8b3bcdf1abadec7829054f90dda9805aab56c77333024b9d0a507daed);
        }
        if ((x & (1 << 61)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0x22a555477f03973fb6edd5c25a052ae3f0dd961da28ac9959e1329cdbcb21c09);
        }
        if ((x & (1 << 62)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0x4b0556e084f3d1dfa2bc04cb0ab88f528f9435387c7dd33793561a4b342b9b4);
        }
        if ((x & (1 << 63)) != 0)
        {
        (, result) = FullMathLibrary.mul512(result, 0x15fc21041027acbbfcd46780fee71ead23fbcb7f4a81e58767ef801a32c2ef);
        }


        return result;
    }
}