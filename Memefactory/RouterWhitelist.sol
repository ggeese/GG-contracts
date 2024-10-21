// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract RouterWhitelist is Ownable {
    address[] public PoolRoutersV2;

    function addPoolRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0), "INVALID_ADDRESS"); // Asegurarse de que no se use la dirección cero
        require(isContract(newRouter), "ADDRESS_IS_NOT_A_CONTRACT");

        for (uint256 i = 0; i < PoolRoutersV2.length; i++) {
            require(PoolRoutersV2[i] != newRouter, "ROUTER_ALREADY_EXISTS");
        }
        
        PoolRoutersV2.push(newRouter);
    }

    // Función auxiliar para verificar si una dirección es un contrato
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr) // Obtiene el tamaño del código en la dirección
        }
        return size > 0; // Si el tamaño es mayor a 0, es un contrato
    }


    function removePoolRouter(address routerToRemove) external onlyOwner {
        uint256 indexToRemove = PoolRoutersV2.length;
        for (uint256 i = 0; i < PoolRoutersV2.length; i++) {
            if (PoolRoutersV2[i] == routerToRemove) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove < PoolRoutersV2.length, "ROUTER_NOT_FOUND");

        // Crear un nuevo array con un tamaño reducido
        address[] memory newPoolRouters = new address[](PoolRoutersV2.length - 1);
        for (uint256 i = 0; i < PoolRoutersV2.length; i++) {
            if (i != indexToRemove) {
                newPoolRouters[i < indexToRemove ? i : i - 1] = PoolRoutersV2[i];
            }
        }
        PoolRoutersV2 = newPoolRouters; // Reemplazar la lista original
    }


    function CheckPoolPair(address TxAddress, address meme) public view returns (bool) {
        for (uint256 i = 0; i < PoolRoutersV2.length; i++) {
            address router = PoolRoutersV2[i];

            try IUniswapV2Router02(router).factory() returns (address factoryAddress) {
                try IUniswapV2Router02(router).WETH() returns (address wethAddress) {
                    address token0 = meme < wethAddress ? meme : wethAddress;
                    address token1 = meme < wethAddress ? wethAddress : meme;

                    try IUniswapV2Factory(factoryAddress).getPair(token0, token1) returns (address pair) {
                        if (pair == TxAddress) {
                            return true;
                        }
                    } catch {
                        continue;
                    }
                } catch {
                    continue; 
                }
            } catch {
                continue;
            }
        }
        return false;
    }


    function getPoolRouterAt(uint256 index) external view returns (address) {
        require(index < PoolRoutersV2.length, "INDEX_OUT_OF_BOUNDS"); // Verifica que el índice sea válido
        return PoolRoutersV2[index]; // Devuelve la dirección del contrato en la posición indicada
    }
    
    function getPoolRouters() external view returns (address[] memory) {
        return PoolRoutersV2;
    }
}
