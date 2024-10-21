// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vault is Ownable, ReentrancyGuard {
    // Estructura para almacenar información de cada token
    struct TokenInfo {
        IERC20 token; // El contrato del token ERC-20
        uint amountPerMint; // La cantidad de este token a distribuir por mint
    }

    // Mapeo para almacenar los tokens usando su dirección como clave
    mapping(address => TokenInfo) public tokens;
    address[] public tokenAddresses; // Lista de direcciones de tokens para referencia

    // Mapeo para controlar los contratos autorizados a distribuir tokens
    mapping(address => bool) public authorizedContracts;

    // Eventos para el registro de depósitos y distribuciones
    event TokensDistributed(address indexed recipient, address tokenAddress, uint amount);
    event EtherDeposited(address indexed sender, uint amount);

    constructor() {}
    
    // Función receive para aceptar ETH
    receive() external payable {
        // Emitir evento cuando el contrato reciba Ether
        emit EtherDeposited(msg.sender, msg.value);
    }
    // El admin agrega un nuevo token ERC-20 y su cantidad a distribuir por mint
    function addToken(address _tokenAddress, uint _amountPerMint) external onlyOwner {
        if (tokens[_tokenAddress].token == IERC20(address(0))) {
            // Si el token no está registrado, lo añadimos
            tokens[_tokenAddress] = TokenInfo({
                token: IERC20(_tokenAddress),
                amountPerMint: _amountPerMint
            });
            tokenAddresses.push(_tokenAddress); // Añadir la dirección a la lista si es un nuevo token
        } else {
            // Si ya está registrado, actualizamos el amountPerMint
            tokens[_tokenAddress].amountPerMint = _amountPerMint;
        }
    }
    // Elimina un token tanto del mapeo de tokens como de la lista de direcciones
    function removeToken(address _tokenAddress) external onlyOwner {
        require(tokens[_tokenAddress].token != IERC20(address(0)), "Token no registrado");

        // Eliminar del mapeo de tokens
        delete tokens[_tokenAddress];

        // Eliminar de la lista de direcciones (sin dejar huecos)
        for (uint i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _tokenAddress) {
                tokenAddresses[i] = tokenAddresses[tokenAddresses.length - 1]; // Mover el último a la posición actual
                tokenAddresses.pop(); // Eliminar el último elemento
                break;
            }
        }
    }


    // Función para autorizar o revocar un contrato para que pueda usar la funcion distributetokens
    function setAdminAuthorization(address _contractAddress, bool _isAuthorized) external onlyOwner {
        authorizedContracts[_contractAddress] = _isAuthorized;
    }

    // Obtener la lista de todas las direcciones de tokens registrados, sus cantidades y si están autorizados
    function getTokensDetails() 
        external 
        view 
        returns (
            address[] memory tokenAddressesList, 
            uint[] memory amountsPerMint
        ) 
    {
        uint length = tokenAddresses.length;
        tokenAddressesList = new address[](length);
        amountsPerMint = new uint[](length);
        
        for (uint i = 0; i < length; i++) {
            address tokenAddress = tokenAddresses[i];
            TokenInfo storage tokenInfo = tokens[tokenAddress];
            
            tokenAddressesList[i] = tokenAddress;
            amountsPerMint[i] = tokenInfo.amountPerMint;
        }
    }


    // Función llamada por el contrato NFT para distribuir tokens al mintear
    function distributeTokens(address recipient) external nonReentrant {
        require(authorizedContracts[msg.sender] || msg.sender == owner(), "Vault: No autorizado");
        for (uint i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            TokenInfo storage tokenInfo = tokens[tokenAddress];
            
            require(
                tokenInfo.token.balanceOf(address(this)) >= tokenInfo.amountPerMint, 
                "Vault: No hay suficientes tokens para distribuir"
            );

            // Transferir la cantidad correspondiente de cada token al destinatario
            tokenInfo.token.transfer(recipient, tokenInfo.amountPerMint);
            emit TokensDistributed(recipient, tokenAddress, tokenInfo.amountPerMint);
        }
    }
}