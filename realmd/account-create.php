<?php
// https://github.com/TrinityCore/TrinityCore/issues/25157

// Credit: https://gist.github.com/Treeston/db44f23503ae9f1542de31cb8d66781e
function calculateSRP6Verifier($username, $password, $salt)
{
    // algorithm constants
    $g = gmp_init(7);
    $N = gmp_init('894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7', 16);

    // calculate first hash
    $h1 = sha1(strtoupper($username . ':' . $password), TRUE);

    // calculate second hash
	$h2 = sha1(strrev($salt) . $h1, TRUE);

    // convert to integer (little-endian)
    $h2 = gmp_import($h2, 1, GMP_LSW_FIRST);

    // g^h2 mod N
    $verifier = gmp_powm($g, $h2, $N);

    // convert back to a byte array (little-endian)
    $verifier = gmp_export($verifier, 1, GMP_LSW_FIRST);

    // pad to 32 bytes, remember that zeros go on the end in little-endian!
    $verifier = str_pad($verifier, 32, chr(0), STR_PAD_RIGHT);

    // done!
	return strrev($verifier);
}

// Credit: https://gist.github.com/Treeston/40b99dd71f55d55c68857919088b2e41
// Returns SRP6 parameters to register this username/password combination with
function getRegistrationData($username, $password)
{
    // generate a random salt
    $salt = random_bytes(32);

    // calculate verifier using this salt
    $verifier = calculateSRP6Verifier($username, $password, $salt);

    // done - this is what you put in the account table!
	$salt = strtoupper(bin2hex($salt));
	$verifier = strtoupper(bin2hex($verifier));

    return array($salt, $verifier);
}

echo implode( ' ', getRegistrationData( $_SERVER['argv'][1], $_SERVER['argv'][2] ) );