// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRouterWhitelist.sol";

contract MemeFactory is Ownable, ReentrancyGuard {

    address private _recipient_tax;
    address private _recipient_tokens_pool;
    address private _whitelistroutercontract;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    // Mapping to check if a token address has been created
    mapping(address => bool) public isMemeCreated;
    // Array to store the addresses of created tokens
    address[] public allMemes;
    address[] public PoolRoutersV2;
    IRouterWhitelist private _routerwhitelist;    


    //!!!!!!!events!!!!!!!!
    event MemeCreated(address indexed owner, address memeAddress);
    event LiquidityAdded(address indexed user, address indexed tokenAddress, uint256 ethAmount);

    constructor(address recipient_tax, address whitelistroutercontract) {
        _recipient_tax = recipient_tax;
        _recipient_tokens_pool = address(this);
        _whitelistroutercontract = whitelistroutercontract;
        _routerwhitelist = IRouterWhitelist(whitelistroutercontract); 

    }

    function createMeme(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address recipient_tokens,   
        uint256 BasetaxRate,
        uint256 protectTime

    ) external {

        require(BasetaxRate <= 100, "TAX_RATE_MUST_BE_LESS_THAN_100");
        require(maxSupply >= 10**18, "MAX_SUPPLY_SHOULD_BE_BIGGER_THAN_1");
        require(protectTime <= 72056520, "PROTECT_HOURS_SHOULD_BE_LESS_THAN_72_056_520");

        MemeCoin meme = new MemeCoin(name, symbol, maxSupply, _recipient_tax, _recipient_tokens_pool, recipient_tokens, BasetaxRate, protectTime, address(this), _whitelistroutercontract);
        
        _addLiquidity(address(meme), maxSupply / (10**18), 0);

        meme.renounceOwnership();

        emit MemeCreated(msg.sender, address(meme));

    }

    receive() external payable {}

    function _addLiquidity(address tokenAddress, uint256 tokenAmount, uint256 routerIndex) internal {
        address selectedRouter = _routerwhitelist.getPoolRouterAt(routerIndex);
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(selectedRouter);
        ERC20(tokenAddress).approve(address(uniswapRouter), tokenAmount);

        // Añadir liquidez al pool de GG
        uniswapRouter.addLiquidityETH{value: 3}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            burnAddress,
            block.timestamp
        );
    }

    function fastAddLiquidity(address tokenAddress, uint256 routerIndex) external payable nonReentrant {
        require(msg.value >= 0.001 * (10**18), "ETH_REQUIRED");
        address selectedRouter = _routerwhitelist.getPoolRouterAt(routerIndex);

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(selectedRouter);

        uint256 tokenAmount = ERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmount > 0, "NO_TOKENS_AVAILABLE");

        require(tokenAmount >= 100, "INSUFFICIENT_TOKENS_FOR_POOL");
        uint256 rewardpool = tokenAmount / 100 ;
        uint256 tokenspool = tokenAmount - rewardpool;
        //Require to be sure we have tokens to add liquidity
        require(tokenspool > 0, "NO_TOKENS_FOR_LIQUIDITY");

        ERC20(tokenAddress).approve(address(uniswapRouter), tokenspool);

        //Add liquidity
        uniswapRouter.addLiquidityETH{value: msg.value}(
            tokenAddress,
            tokenspool,
            0,
            0,
            burnAddress,
            block.timestamp
        );

        // Transfer reward to user
        require(ERC20(tokenAddress).transfer(msg.sender, rewardpool), "TRANSFER_FAILED");
        emit LiquidityAdded(msg.sender, tokenAddress, msg.value);
    }
        
    function withdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        ERC20(token).transfer(msg.sender, amount);
    }

    function receiveERC20(address token, uint256 amount) external {
        ERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function updateRecipientTax(address newRecipientTax) external onlyOwner {
        _recipient_tax = newRecipientTax;
    }
    
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function getMemeCount() external view returns (uint256) {
        return allMemes.length;
    }

    function checkIfMemeCreated(address tokenAddress) external view returns (bool) {
        return isMemeCreated[tokenAddress];
    }

    function addPoolRouter(address newRouter) external onlyOwner {
        // Verificar si el router ya existe en el array
        for (uint256 i = 0; i < PoolRoutersV2.length; i++) {
            require(PoolRoutersV2[i] != newRouter, "ROUTER_ALREADY_EXISTS");
        }
        // Añadir el nuevo router al array
        PoolRoutersV2.push(newRouter);
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

        PoolRoutersV2[indexToRemove] = PoolRoutersV2[PoolRoutersV2.length - 1];
        PoolRoutersV2.pop(); 
    }

}

contract MemeCoin is ERC20, Ownable {

    uint256 private _taxRate;
    address private _recipient_tax_tokens;
    address private _recipient_tokens_pool;
    address private _recipient_tokens;
    uint256 public _protectMinutes;
    uint256 public startTrade;
    uint256 public minuteUnix = 1 minutes;
    address private _memefactory;
    IRouterWhitelist private _routerwhitelist;    

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address recipient_tax_tokens,
        address recipient_tokens_pool,
        address recipient_tokens,
        uint256 BasetaxRate,
        uint256 protectMinutes,
        address memefactory,
        address routerwhitelist 


    ) ERC20(name, symbol) {

        _taxRate = BasetaxRate;
        _recipient_tax_tokens = recipient_tax_tokens;
        _recipient_tokens_pool = recipient_tokens_pool;
        _recipient_tokens = recipient_tokens;
        _protectMinutes = protectMinutes;
        _memefactory = memefactory;
        _routerwhitelist = IRouterWhitelist(routerwhitelist); 
        mint_tokens(maxSupply);

        startTrade = block.timestamp;

    }

    function mint_tokens(uint256 amount) internal onlyOwner {
        uint256 taxAmount_mint = amount * 1 / 100;
        uint256 poolAmount_mint = taxAmount_mint * 10 + (amount * 1 / (10**18));

        _mint(_recipient_tokens, amount);
        _mint(_recipient_tax_tokens, taxAmount_mint);
        _mint(_recipient_tokens_pool, poolAmount_mint);
    }
    //TXAddress is the contract pool of the meme-weth pair
    function isPairPool(address sender, address TxAddress) public view returns (bool) {
        if (sender == _memefactory) {
            return false;
        }
        try _routerwhitelist.CheckPoolPair(TxAddress, address(this)) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = 0;
        uint256 transferAmount = amount;
        uint256 MinutesTrade = (block.timestamp - startTrade) / minuteUnix;
        
        if (MinutesTrade < _protectMinutes) {

            if (isPairPool(_msgSender(), recipient)) {
                taxAmount = amount * getCurrentFee() / 10000;
                transferAmount = amount - taxAmount;
            }

            _transfer(_msgSender(), recipient, transferAmount);
            emit Transfer(_msgSender(), recipient, transferAmount);

            if (taxAmount > 0) {
                _transfer(_msgSender(), _recipient_tax_tokens, taxAmount);
                emit Transfer(_msgSender(), _recipient_tax_tokens, taxAmount);
            }

        } else {
            taxAmount = amount * _taxRate / 10000;
            transferAmount = amount - taxAmount;
            
            _transfer(_msgSender(), recipient, transferAmount);
            emit Transfer(_msgSender(), _recipient_tokens, taxAmount);  // Emitir evento para la transferencia de impuestos

            if (taxAmount > 0) {
                _transfer(_msgSender(), _recipient_tokens, taxAmount);
                emit Transfer(_msgSender(), _recipient_tokens, taxAmount);  // Emitir evento para la transferencia de impuestos

            }

        }

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = 0;
        uint256 transferAmount = amount;
        uint256 MinutesTrade = (block.timestamp - startTrade) / minuteUnix;

        //check borderless
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _approve(sender, _msgSender(), currentAllowance - amount);

        if (MinutesTrade < _protectMinutes) {

            if (isPairPool(sender, recipient)) {

                taxAmount = amount * getCurrentFee() / 10000;
                transferAmount = amount - taxAmount;
            }

            _transfer(sender, recipient, transferAmount);
            emit Transfer(sender, recipient, transferAmount);


            if (taxAmount > 0) {
                _transfer(sender, _recipient_tax_tokens, taxAmount);
                emit Transfer(sender, _recipient_tax_tokens, taxAmount);  // Emitir evento para la transferencia de impuestos

            }
        } else {
            taxAmount = amount * _taxRate / 10000;
            transferAmount = amount - taxAmount;

            _transfer(sender, recipient, transferAmount);
            emit Transfer(sender, recipient, transferAmount);

            if (taxAmount > 0) {
                _transfer(sender, _recipient_tokens, taxAmount);
                emit Transfer(sender, _recipient_tokens, taxAmount);
            }
        }

            return true;
    }
    
    // Nueva función para obtener el fee actual
    function getCurrentFee() public view returns (uint256) {
        uint256 MinutesTrade = (block.timestamp - startTrade) / minuteUnix;
        if (MinutesTrade < _protectMinutes) {
            return 10000 - (MinutesTrade * 10000 / _protectMinutes);
        }
        return _taxRate;
    }

    // Nueva función para obtener los días de protección
    function getProtectDetails() public view returns (uint256, uint256) {
        return (startTrade, _protectMinutes);
    }
}