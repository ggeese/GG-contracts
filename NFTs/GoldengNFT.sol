    // SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.24;

    import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/utils/Strings.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "./IVault.sol"; // Importa la interfaz

    contract GoldengNFT is ERC721, Ownable, ReentrancyGuard {
        uint public counter;
        address public feeWallet;
        uint public feeAmount;
        string public baseTokenURI; 
        uint public mintingStartTime;
        IVault public vault; // Referencia al contrato de la bóveda usando la interfaz
        uint public constant MAX_NFTS = 1370; // Límite de NFTs

        // Estructura para almacenar la información del NFT
        struct NFTInfo {
            address minter;
            bytes publicKey; // La clave pública en formato bytes
        }

        // Array para almacenar la información de los primeros NFTs
        NFTInfo[MAX_NFTS] public nftInfoArray;
        uint public storedNFTCount; // Contador para el número de NFTs almacenados

        // Definición del error personalizado
        error InvalidTokenId(uint tokenId);
        error ArrayFull();

        constructor(
            address _feeWallet, 
            uint _feeAmount, 
            string memory _baseTokenURI, 
            uint _mintingStartTime,
            address _vaultAddress // Dirección de la bóveda
            ) 

        ERC721("GoldenG", "GG") {
            feeWallet = _feeWallet;
            feeAmount = _feeAmount;
            baseTokenURI = _baseTokenURI;
            mintingStartTime = _mintingStartTime; // Hora de inicio del minting en formato timestamp
            vault = IVault(_vaultAddress); // Inicializar la bóveda con la interfaz correcta

        }

        function mintTo(address _to, bytes memory _publicKey) public payable nonReentrant {
            require(block.timestamp >= mintingStartTime, "Minting has not started yet");
            require(msg.value >= feeAmount, "Insufficient fee");
            
            counter++;
            _safeMint(_to, counter);

            // Solo almacenar en el array si hay espacio
            if (storedNFTCount < MAX_NFTS) {
                nftInfoArray[storedNFTCount] = NFTInfo({
                    minter: msg.sender,
                    publicKey: _publicKey // Almacenar la clave pública proporcionada
                });
                storedNFTCount++;
                vault.distributeTokens(_to);
            } 
            
            if (msg.value > feeAmount) {
                payable(msg.sender).transfer(msg.value - feeAmount);
            }
            payable(feeWallet).transfer(feeAmount);
        }

        function tokenURI(uint tokenId) public view override returns (string memory) {
            if (!_exists(tokenId)) {
                revert InvalidTokenId(tokenId);
            }
            if (tokenId > MAX_NFTS) {
                return string(abi.encodePacked(baseTokenURI, "0.json")); 
            }
            // Caso contrario, devuelve el URI normal basado en el tokenId
            return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId), ".json"));
        }

        function getMintCount() public view returns (uint) {
            return counter;
        }

        // Función para obtener toda la información de los NFTs almacenados (solo el owner puede acceder)
        function getAllNFTInfos() public view onlyOwner returns (NFTInfo[] memory) {
            NFTInfo[] memory infos = new NFTInfo[](storedNFTCount);
            for (uint i = 0; i < storedNFTCount; i++) {
                infos[i] = nftInfoArray[i];
            }
            return infos;
        }
    }
