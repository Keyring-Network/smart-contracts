// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

/*
    Copyright 2016, Adrià Massanet

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Checked results with FIPS test vectors
    https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/dss/186-2rsatestvectors.zip
    file SigVer15_186-3.rsp
    
 */


import "./RsaMessagePacking.sol";

library BarrettBigModExp {

    // ========== DATA STRUCTURES ==========

    /**
     * @dev A 1024-bit unsigned integer stored in 4 x 256-bit limbs (big-endian).
     *      data[0] is the most significant 256 bits
     *      data[3] is the least significant 256 bits
     */
    struct Uint1024 {
        uint256[4] data;
    }

    /**
     * @dev A 2048-bit unsigned integer stored in 8 x 256-bit limbs (big-endian).
     *      data[0] is the most significant 256 bits
     *      data[7] is the least significant 256 bits
     */
    struct Uint2048 {
        uint256[8] data;
    }

    // ========== HELPERS: 256-BIT ADD, SUB, MUL ==========

    /**
     * @dev Return (sum, carryOut) = a + b + carryIn, for 256-bit words.
     */
    function add256Carry(
        uint256 a,
        uint256 b,
        uint256 carryIn
    )
        internal
        pure
        returns (uint256 sum, uint256 carryOut)
    {
        unchecked {
            uint256 s = a + b + carryIn;
            carryOut = (s < a || s < b || (carryIn == 1 && s <= a + b)) ? 1 : 0;
            sum = s;
        }
    }

    /**
     * @dev Return (diff, borrowOut) = a - (b + borrowIn).
     *      BorrowOut is 1 if b+borrowIn > a, else 0.
     */
    function sub256Borrow(
        uint256 a,
        uint256 b,
        uint256 borrowIn
    )
        internal
        pure
        returns (uint256 diff, uint256 borrowOut)
    {
        unchecked {
            uint256 bb = b + borrowIn;
            diff = a - bb;
            borrowOut = (bb > a) ? 1 : 0;
        }
    }

    /**
     * @dev Full 256x256 => (low, high) 512-bit multiply via inline assembly.
     */
    function full256Mul(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 lo, uint256 hi)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let mm := mulmod(x, y, not(0))
            lo := mul(x, y)
            hi := sub(sub(mm, lo), lt(mm, lo))
        }
    }

    // ========== COMPARISONS ==========

    /**
     * @dev Compare two 1024-bit numbers a vs b.
     * @return negative if a < b, 0 if a == b, positive if a > b
     */
    function compare1024(Uint1024 memory a, Uint1024 memory b)
        internal
        pure
        returns (int256)
    {
        for (uint256 i = 0; i < 4; i++) {
            if (a.data[i] < b.data[i]) {
                return -1;
            } else if (a.data[i] > b.data[i]) {
                return 1;
            }
        }
        return 0;
    }

    /**
     * @dev Compare two 2048-bit numbers a vs b.
     * @return negative if a < b, 0 if a == b, positive if a > b
     */
    function compare2048(Uint2048 memory a, Uint2048 memory b)
        internal
        pure
        returns (int256)
    {
        for (uint256 i = 0; i < 8; i++) {
            if (a.data[i] < b.data[i]) {
                return -1;
            } else if (a.data[i] > b.data[i]) {
                return 1;
            }
        }
        return 0;
    }

    // ========== SUBTRACTIONS (1024, 2048) ==========

    function sub1024(Uint1024 memory a, Uint1024 memory b)
        internal
        pure
        returns (Uint1024 memory result)
    {
        uint256 borrow = 0;
        for (uint256 i = 0; i < 4; i++) {
            uint256 j = 3 - i;
            (result.data[j], borrow) = sub256Borrow(a.data[j], b.data[j], borrow);
        }
    }

    function sub2048(Uint2048 memory a, Uint2048 memory b)
        internal
        pure
        returns (Uint2048 memory result)
    {
        uint256 borrow = 0;
        for (uint256 i = 0; i < 8; i++) {
            uint256 j = 7 - i;
            (result.data[j], borrow) = sub256Borrow(a.data[j], b.data[j], borrow);
        }
    }

    // ========== MULTIPLY: 1024 x 1024 => 2048, 1024 x 2048 => 3072 (or truncated) ==========

    /**
     * @dev Multiply two 1024-bit numbers => 2048 bits.
     *      We'll store the product in a 8-limb big-endian array.
     */
    function mul1024x1024(Uint1024 memory a, Uint1024 memory b)
        internal
        pure
        returns (Uint2048 memory product)
    {
        // We do the schoolbook approach: for i, j in 0..3
        // a.data[i] * b.data[j] => partial 512-bit.
        // Then add to product at index i+j.
        uint256[8] memory intermediate; // big-endian limbs

        // i=0 => top limb of a, i=3 => bottom limb. We'll just be consistent.
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 4; j++) {
                (uint256 lo, uint256 hi) = full256Mul(a.data[i], b.data[j]);
                uint256 index = i + j; // 0..6 possible

                // Add lo to intermediate[index], hi to intermediate[index+1], plus any carry
                {
                    (uint256 sum, uint256 carry) = add256Carry(
                        intermediate[index],
                        lo,
                        0
                    );
                    intermediate[index] = sum;

                    (sum, carry) = add256Carry(
                        (index + 1 < 8) ? intermediate[index + 1] : 0,
                        hi,
                        carry
                    );
                    if (index + 1 < 8) {
                        intermediate[index + 1] = sum;
                    }
                    // carry leftover => put it in index+2 if in range
                    if (carry != 0 && index + 2 < 8) {
                        intermediate[index + 2] += carry;
                    }
                }
            }
        }

        // Convert the intermediate to Uint2048
        for (uint256 i = 0; i < 8; i++) {
            product.data[i] = intermediate[i];
        }
    }

    /**
     * @dev Multiply a 1024-bit number by a 2048-bit number => up to 3072 bits.
     *      For Barrett, we often only need the low 2048 bits, but let's store all
     *      3072 bits in a 12-limb array if we want to be thorough. Then we can
     *      keep only 2048 or 2560 bits as needed.
     *
     *      For simplicity, let's store the full product in 12-limb big-endian,
     *      though it’s quite large. Then the top 4 limbs might be 0 if the product
     *      doesn't actually reach 3072 bits.
     */
    struct Uint3072 {
        uint256[12] data;
    }

    function mul1024x2048(Uint1024 memory a, Uint2048 memory b)
        internal
        pure
        returns (Uint3072 memory product)
    {
        uint256[12] memory tmp;

        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 8; j++) {
                (uint256 lo, uint256 hi) = full256Mul(a.data[i], b.data[j]);
                uint256 index = i + j; // max = 3+7=10

                // Add lo -> tmp[index], hi -> tmp[index+1], etc.
                {
                    (uint256 sum, uint256 carry) = add256Carry(tmp[index], lo, 0);
                    tmp[index] = sum;

                    (sum, carry) = add256Carry(
                        (index+1 < 12) ? tmp[index + 1] : 0,
                        hi,
                        carry
                    );
                    if (index+1 < 12) {
                        tmp[index + 1] = sum;
                    }
                    if (carry != 0 && index+2 < 12) {
                        tmp[index + 2] = tmp[index + 2] + carry;
                    }
                }
            }
        }

        // Copy into product
        for (uint256 i = 0; i < 12; i++) {
            product.data[i] = tmp[i];
        }
    }

    // ========== UTILS FOR SHIFTING / EXTRACTING PARTS ==========

    /**
     * @dev Extract the lower 2048 bits from a 3072-bit product.
     *      That is limbs [4..11] if we treat the array as big-endian with 12 limbs total.
     */
    function lower2048Of3072(Uint3072 memory x)
        internal
        pure
        returns (Uint2048 memory result)
    {
        // x.data[0]..x.data[3] => top bits
        // x.data[4]..x.data[11] => bottom 2048 bits
        for (uint256 i = 0; i < 8; i++) {
            result.data[i] = x.data[i + 4];
        }
    }

    /**
     * @dev Extract the top 1024 bits from a 2048-bit big-endian number
     *      i.e. x.data[0..3].
     */
    function top1024Of2048(Uint2048 memory x)
        internal
        pure
        returns (Uint1024 memory top)
    {
        for (uint256 i = 0; i < 4; i++) {
            top.data[i] = x.data[i];
        }
    }

    /**
     * @dev Extract the bottom 1024 bits from a 2048-bit big-endian number
     *      i.e. x.data[4..7].
     */
    function bottom1024Of2048(Uint2048 memory x)
        internal
        pure
        returns (Uint1024 memory bottom)
    {
        for (uint256 i = 0; i < 4; i++) {
            bottom.data[i] = x.data[i + 4];
        }
    }

    // ========== ON-CHAIN COMPUTATION OF MU ==========

    /**
     * @dev Returns 2^2048 - 1 as a 2048-bit number. (All bits set.)
     *      We'll use this to approximate 2^(2*k).
     */
    function maxUint2048() internal pure returns (Uint2048 memory x) {
        for (uint256 i = 0; i < 8; i++) {
            x.data[i] = type(uint256).max;
        }
    }

    /**
     * @dev Perform big-limb division: (dividend / m) => quotient, ignoring remainder.
     *      dividend is 2048 bits, m is 1024 bits, quotient can be up to 1024 bits.
     *
     *      We'll do a simplified "long division" approach in big-endian form:
     *         1) Start Q=0 (1024 bits).
     *         2) For shift in [0..some range], shift m left and see if <= dividend.
     *         3) Subtract and set the corresponding bit in Q.
     *      This is quite expensive in pure Solidity, but is purely on-chain.
     *
     *      The result is floor(dividend/m).
     */
    function bigDiv2048By1024(Uint2048 memory dividend, Uint1024 memory m)
        internal
        pure
        returns (Uint1024 memory quotient)
    {
        // We'll accumulate the result in quotient. We'll do up to 1025 bits of iteration
        // (since dividend is 2048 bits, m is 1024 bits, the quotient can be up to 1024 bits).
        // We'll treat each bit from most to least significant.
        // A typical approach is to left-shift m, compare, subtract if possible, set bit in Q.

        // Let temp = m << shift, while shift from (1024) down to 0 maybe.
        // Because m is 1024 bits, shifting left up to 1024 bits => up to 2048 bits in total.
        // We'll store that in a Uint2048 for comparison with the dividend.

        for (int256 shift = 1023; shift >= 0; shift--) {
            // shift m by 'shift' bits => 2048 bits
            Uint2048 memory mShifted = shiftLeft1024to2048(m, uint256(shift));

            // if dividend >= mShifted, then subtract and set this bit in quotient
            if (compare2048(dividend, mShifted) >= 0) {
                // subtract
                dividend = sub2048(dividend, mShifted);

                // set bit # shift in quotient => that means the (1023 - shift)th bit from the right
                // Actually simpler approach: we set that bit in a 1024-bit number
                // So if shift=10 => means 1 << 10
                // But we have to store it in big-endian [0..3].
                // It's actually easier to store in normal "bit-little" form for the final?

                // We'll do a small helper that sets the "shift"th bit in a 1024-bit number:
                setBitIn1024(quotient, uint256(shift));
            }
        }
        // At the end, quotient is floor(original_dividend / m).
    }

    /**
     * @dev Shift a 1024-bit number left by 'shiftBits' (0..1024) and store in a 2048-bit struct.
     *      We'll do limb-based shifting in multiples of 256 plus the leftover bits.
     */
    function shiftLeft1024to2048(Uint1024 memory x, uint256 shiftBits)
        internal
        pure
        returns (Uint2048 memory result)
    {
        // Each limb is 256 bits. We'll shift by shiftBits // 256 limbs, and shiftBits % 256 bits within a limb.
        uint256 limbShift = shiftBits >> 8;      // shiftBits / 256
        uint256 bitShift  = shiftBits & 0xff;    // shiftBits % 256

        // Start by placing x in the correct limbs offset by limbShift
        // e.g. if limbShift=4, x goes to the top 4 limbs are empty, then x in limbs [0..3]? 
        // But we are big-endian, so we must be consistent. 
        // Easiest might be to first gather x into a 2048 in the "lowest" 4 limbs, then shift those up.

        // 1) Put x in the bottom 4 limbs of result (i.e. [4..7]) to replicate your current usage
        for (uint256 i = 0; i < 4; i++) {
            result.data[i + 4] = x.data[i];
        }

        // 2) Now we do an additional left-limb shift by limbShift 
        //    meaning we move data[i] => data[i - limbShift], if i-limbShift >=0.
        //    But we'll do it carefully from top to bottom.
        if (limbShift > 0) {
            if (limbShift >= 8) {
                // Then everything is shifted out. We get zero.
                for (uint256 i = 0; i < 8; i++) {
                    result.data[i] = 0;
                }
            } else {
                for (uint256 i = 0; i < 8; i++) {
                    if (i + limbShift < 8) {
                        result.data[i] = result.data[i + limbShift];
                    } else {
                        result.data[i] = 0;
                    }
                }
            }
        }

        // 3) Now bitShift the entire 2048 left by bitShift. This is standard big-endian shift.
        if (bitShift > 0) {
            for (uint256 i = 0; i < 8; i++) {
                uint256 before = result.data[i];
                // We'll shift left
                // The bits that flow out go to next data[i-1] if i>0
                uint256 carry = 0;
                if (i < 7) {
                    carry = result.data[i + 1] >> (256 - bitShift);
                }
                // Shift the current limb
                result.data[i] = (before << bitShift) & type(uint256).max;
                // OR in the carry
                if (i < 7) {
                    result.data[i] |= carry;
                }
            }
        }
    }

    /**
     * @dev Set the `bitIndex` (0..1023) in a 1024-bit big-endian number.
     *      If bitIndex=0 => the LSB. If bitIndex=1023 => the MSB.
     *      We have 4 limbs, each 256 bits => total 1024 bits.
     *      data[0] is top-limb, data[3] is bottom-limb in big-endian.
     *
     *      We'll interpret bitIndex=0 as the least significant bit in data[3].
     */
    function setBitIn1024(Uint1024 memory x, uint256 bitIndex)
        internal
        pure
    {
        // Identify which limb => limb = 3 - (bitIndex >> 8) for big-endian
        // Then which bit within that limb => bit = bitIndex & 0xff
        // But in the *actual* 256-bit word, bit 0 is LSB.
        // So let's do:
        uint256 limbIndex = 3 - (bitIndex >> 8);
        uint256 bitInLimb = bitIndex & 0xff; // 0..255
        // Now set that bit:
        // x.data[limbIndex] |= (1 << bitInLimb)
        x.data[limbIndex] |= (uint256(1) << bitInLimb);
    }

    /**
     * @dev Compute mu = floor((2^2048 - 1) / m).
     *      This is an approximation of 2^(2k)/m (k=1024 bits).
     *      It's slightly less than 2^2048 / m, but for Barrett it works fine
     *      as long as we allow an extra subtraction at the end.
     */
    function computeMuOnChain(Uint1024 memory m)
        internal
        pure
        returns (Uint2048 memory mu)
    {
        // 1) Let dividend = 2^2048 - 1
        Uint2048 memory dividend = maxUint2048();
        // 2) quotient = bigDiv2048By1024(dividend, m) => 1024 bits
        Uint1024 memory q = bigDiv2048By1024(dividend, m);
        // 3) Store q in a 2048-bit with top 4 limbs = 0, bottom 4 limbs = q
        //    since q can be up to 1024 bits
        for (uint256 i = 0; i < 4; i++) {
            mu.data[i] = 0;
            mu.data[i + 4] = q.data[i];
        }
    }

    // ========== BARRETT REDUCTION ==========

    /**
     * @dev Barrett reduce a 2048-bit x modulo a 1024-bit m, given mu (2048 bits).
     *
     *  Algorithm (slight variant):
     *    1) q1 = top_1024_of_2048(x)  (the upper 1024 bits of x)
     *    2) q2 = q1 * mu (=> up to 3072 bits). Take the lower 2048 bits: call it q2low
     *    3) q3 = top_1024_of_2048(q2low)
     *    4) r = x - (q3 * m)
     *    5) while r >= m, r = r - m
     *
     *  Typically that only needs 0 or 1 sub, but we do a loop for safety.
     */
    function barrettReduce2048To1024Mod(
        Uint2048 memory x,
        Uint1024 memory m,
        Uint2048 memory mu
    )
        internal
        pure
        returns (Uint1024 memory remainder)
    {
        // Step 1: q1 = top 1024 bits of x
        Uint1024 memory q1 = top1024Of2048(x);

        // Step 2: q2 = q1 * mu => up to 3072 bits
        Uint3072 memory q2full = mul1024x2048(q1, mu);
        // Take the bottom 2048 of that => q2low
        Uint2048 memory q2low = lower2048Of3072(q2full);

        // Step 3: q3 = top 1024 bits of q2low
        Uint1024 memory q3 = top1024Of2048(q2low);

        // Step 4: r = x - (q3*m)
        Uint2048 memory q3m = mul1024x1024(q3, m);
        Uint2048 memory rFull = sub2048(x, q3m);

        // Step 5: fix-up if needed
        //    r = bottom1024Of2048(rFull) is the final candidate
        remainder = bottom1024Of2048(rFull);
        while (compare1024(remainder, m) >= 0) {
            remainder = sub1024(remainder, m);
        }
    }

    // ========== TOP-LEVEL MULTIPLY & POW3 ==========

    /**
     * @dev Multiply a and b (each 1024 bits) => 2048 bits => Barrett reduce => 1024 bits mod m
     */
    function mul1024Mod(
        Uint1024 memory a,
        Uint1024 memory b,
        Uint1024 memory m,
        Uint2048 memory mu
    )
        internal
        pure
        returns (Uint1024 memory result)
    {
        // 1. Multiply => 2048 bits
        Uint2048 memory x = mul1024x1024(a, b);

        // 2. Barrett reduce
        result = barrettReduce2048To1024Mod(x, m, mu);
    }

    /**
     * @dev Compute x^3 mod m using two multiplications with Barrett reduction.
     *      We pass in mu for the modulus m as well.
     */
    function pow3mod(
        Uint1024 memory x,
        Uint1024 memory m,
        Uint2048 memory mu
    )
        internal
        pure
        returns (Uint1024 memory)
    {
        // r1 = x^2 mod m
        Uint1024 memory r1 = mul1024Mod(x, x, m, mu);
        // r2 = r1 * x = x^3 mod m
        Uint1024 memory r2 = mul1024Mod(r1, x, m, mu);
        return r2;
    }
}


/**
 * @title XcubeModBarrett
 * @notice Replaces the original XcubeMod with a version that uses BarrettBigModExp.
 *         Also includes the on-chain computation of `mu`.
 */
abstract contract XcubeModBarrett {
    using BarrettBigModExp for BarrettBigModExp.Uint1024;

    /**
     * @dev Helper that reads 32 bytes from `data` at offset `start` and returns a uint256.
     *      We assume the bytes are already in “big-endian” order that aligns with how `mload`
     *      interprets them. 
     */
    function sliceToUint256(bytes memory data, uint256 start)
        internal
        pure
        returns (uint256 result)
    {
        require(data.length >= start + 32, "slice out of range");
        assembly {
            result := mload(add(data, add(32, start)))
        }
    }

    /**
     * @dev Converts a 128-byte array (big-endian) into a `Uint1024`.
     */
    function parseBytesToUint1024(bytes memory data)
        internal
        pure
        returns (BarrettBigModExp.Uint1024 memory x)
    {
        require(data.length == 128, "Need exactly 128 bytes for 1024-bit");
        x.data[0] = sliceToUint256(data, 0);
        x.data[1] = sliceToUint256(data, 32);
        x.data[2] = sliceToUint256(data, 64);
        x.data[3] = sliceToUint256(data, 96);
    }

    /**
     * @dev Converts a `Uint1024` back to a 128-byte big-endian array.
     */
    function convertUint1024ToBytes(BarrettBigModExp.Uint1024 memory x)
        internal
        pure
        returns (bytes memory result)
    {
        result = new bytes(128);
        assembly {
            let ptr := add(result, 32)
            mstore(ptr, mload(x))
            mstore(add(ptr, 32), mload(add(x, 32)))
            mstore(add(ptr, 64), mload(add(x, 64)))
            mstore(add(ptr, 96), mload(add(x, 96)))
        }
    }

    /**
     * @dev Compute base^3 mod modulus using Barrett reduction,
     *      returning the 128-byte big-endian result.
     *
     *      This function also computes `mu` on-chain (very expensive).
     */
    function computeXcubedModBytes(
        bytes memory baseBytes,
        bytes memory modulusBytes
    )
        internal
        pure
        returns (bytes memory resultBytes)
    {
        // 1) parse
        BarrettBigModExp.Uint1024 memory baseVal = parseBytesToUint1024(baseBytes);
        BarrettBigModExp.Uint1024 memory modVal  = parseBytesToUint1024(modulusBytes);

        // 2) compute mu on-chain
        BarrettBigModExp.Uint2048 memory mu = BarrettBigModExp.computeMuOnChain(modVal);

        // 3) compute x^3 mod n
        BarrettBigModExp.Uint1024 memory rawResult = baseVal.pow3mod(modVal, mu);

        // 4) convert back
        resultBytes = convertUint1024ToBytes(rawResult);
    }
}



abstract contract RsaVerify is RsaMessagePacking, XcubeModBarrett {

    /**
     * @dev Contains the exponent and modulus of the RSA key.
     * @param exponent The exponent part of the RSA key.
     * @param modulus The modulus part of the RSA key.
     */
    struct RsaKey {
        bytes exponent;
        bytes modulus;
    }

    /**
     * @dev Verifies the authenticity of a message using RSA signature.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param validFrom The time from which a credential is valid.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param signature The signature.
     * @param backdoor The backdoor data.
     * @return True if the verification is successful, false otherwise.
     */
    function verifyAuthMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 validFrom,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) internal view returns (bool) {
        bytes memory message = packAuthMessage(tradingAddress, policyId, validFrom, validUntil, cost, backdoor);
        return pkcs1Sha256Raw(message, signature, key);
    }


    /**
     * @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _sha256 is the sha256 of the data
     * @param _s is the signature
     * @param _m is the modulus
     * @return true if success, false otherwise
     */
    function pkcs1Sha256(bytes32 _sha256, bytes memory _s, bytes memory _m)
        public
        view
        returns (bool)
    {
        uint8[17] memory sha256ExplicitNullParam =
            [0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00];

        uint8[15] memory sha256ImplicitNullParam =
            [0x30, 0x2f, 0x30, 0x0b, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01];

        // decipher

        uint256 decipherlen = _m.length;
        bytes memory decipher = new bytes(decipherlen);
        // assembly {
        //     pop(staticcall(sub(gas(), 2000), 5, add(input, 0x20), inputlen, add(decipher, 0x20), decipherlen))
        // }
        // 1) compute s^e mod m in pure Solidity
        decipher = computeXcubedModBytes(_s, _m);

        // Check that is well encoded:
        //
        // 0x00 || 0x01 || PS || 0x00 || DigestInfo
        // PS is padding filled with 0xff
        // DigestInfo ::= SEQUENCE {
        //    digestAlgorithm AlgorithmIdentifier,
        //      [optional algorithm parameters]
        //    digest OCTET STRING
        // }

        bool hasNullParam;
        uint256 digestAlgoWithParamLen;

        if (uint8(decipher[decipherlen - 50]) == 0x31) {
            hasNullParam = true;
            digestAlgoWithParamLen = sha256ExplicitNullParam.length;
        } else if (uint8(decipher[decipherlen - 48]) == 0x2f) {
            hasNullParam = false;
            digestAlgoWithParamLen = sha256ImplicitNullParam.length;
        } else {
            return false;
        }

        uint256 paddingLen = decipherlen - 5 - digestAlgoWithParamLen - 32;

        if (decipher[0] != 0 || decipher[1] != 0x01) {
            return false;
        }
        for (uint256 i = 2; i < 2 + paddingLen; i++) {
            if (decipher[i] != 0xff) {
                return false;
            }
        }
        if (decipher[2 + paddingLen] != 0) {
            return false;
        }

        // check digest algorithm

        if (digestAlgoWithParamLen == sha256ExplicitNullParam.length) {
            for (uint256 i = 0; i < digestAlgoWithParamLen; i++) {
                if (decipher[3 + paddingLen + i] != bytes1(sha256ExplicitNullParam[i])) {
                    return false;
                }
            }
        } else {
            for (uint256 i = 0; i < digestAlgoWithParamLen; i++) {
                if (decipher[3 + paddingLen + i] != bytes1(sha256ImplicitNullParam[i])) {
                    return false;
                }
            }
        }

        // check digest

        if (
            decipher[3 + paddingLen + digestAlgoWithParamLen] != 0x04
                || decipher[4 + paddingLen + digestAlgoWithParamLen] != 0x20
        ) {
            return false;
        }

        for (uint256 i = 0; i < _sha256.length; i++) {
            if (decipher[5 + paddingLen + digestAlgoWithParamLen + i] != _sha256[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Verifies a PKCSv1.5 SHA256 signature
     * @param _data to verify
     * @param _s is the signature
     * @param _m is the modulus
     * @return 0 if success, >0 otherwise
     */
    function pkcs1Sha256Raw(bytes memory _data, bytes memory _s, bytes memory _m)
        public
        view
        returns (bool)
    {
        return pkcs1Sha256(sha256(_data), _s, _m);
    }
}


