// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    // Función para distribuir tokens
    function distributeTokens(address recipient) external;
}
