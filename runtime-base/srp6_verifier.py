#!/usr/bin/env python3
"""
Generate SRP6 salt and verifier for CMaNGOS account creation.

Replicates the C++ implementation in:
  - AccountMgr::CalculateShaPassHash  (sources/*/cmangos/src/game/Accounts/AccountMgr.cpp)
  - SRP6::CalculateVerifier           (sources/*/cmangos/src/shared/Auth/SRP6.cpp)

Usage: srp6_verifier.py <username> <password>
Output: SALT_HEX<TAB>VERIFIER_HEX
"""
import sys
import secrets
import hashlib

# SRP6 parameters from SRP6.cpp
N = 0x894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7
G = 7
SALT_BYTES = 32  # s_BYTE_SIZE = 32


def calculate(username, password):
    """
    Calculate SRP6 salt (s) and verifier (v) for a CMaNGOS account.

    Returns (salt_hex, verifier_hex) as uppercase strings matching BN_bn2hex output.
    """
    # Step 1: CalculateSHA1(UPPER(username) + ":" + UPPER(password))
    sha1 = hashlib.sha1()
    sha1.update((username.upper() + ":" + password.upper()).encode("ascii"))
    I_digest = sha1.digest()

    # Step 2: Generate salt matching OpenSSL BN_rand(256, top=0, bottom=1):
    # MSB set (always 32 bytes after BN_hex2bn) and odd.
    salt = bytearray(secrets.token_bytes(SALT_BYTES))
    salt[0] |= 0x80
    salt[-1] |= 0x01
    salt = bytes(salt)

    # Step 3: x = SHA1(salt_LE || I_digest)
    #
    # CMaNGOS byte order (SRP6::CalculateVerifier):
    #   s.AsByteArray(reverse=true) → LE bytes of salt number
    #   I_bn after reverse/memcpy/mReverse → recovers original SHA1 digest bytes (BE)
    #   sha.UpdateData(salt_le), sha.UpdateData(I_digest_bytes)
    #
    # BigNumber::SetBinary interprets input as LE, so the SHA1 digest of this
    # intermediate hash is interpreted as a little-endian integer for x.
    salt_le = bytes(reversed(salt))

    x_sha = hashlib.sha1()
    x_sha.update(salt_le)
    x_sha.update(I_digest)
    x_digest = x_sha.digest()

    # Step 4: x as BigNumber (SetBinary = LE interpretation)
    x_int = int.from_bytes(x_digest, byteorder="little")

    # Step 5: v = g^x mod N
    v_int = pow(G, x_int, N)

    # Step 6: Format as uppercase hex (matching BN_bn2hex / to_bytes)
    s_hex = salt.hex().upper()
    v_hex = v_int.to_bytes((v_int.bit_length() + 7) // 8, "big").hex().upper()

    return s_hex, v_hex


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <username> <password>", file=sys.stderr)
        sys.exit(1)

    s, v = calculate(sys.argv[1], sys.argv[2])
    print(f"{s}\t{v}")
