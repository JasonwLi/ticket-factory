//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract PaymentWallet is Ownable{
    bool public convertToStable;
    bool public pauseWithdrawal;
    bool public pauseBridging;
    address payable eoaWallet;
    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address private constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    constructor(address payable _eoaWallet) {
        eoaWallet = _eoaWallet;
        convertToStable = true;
        pauseWithdrawal = true;
        pauseBridging = false;
    }

    function autoConvertETH() public payable {
        require(convertToStable == true);
        uint256 amount = msg.value;
        address[] memory tradePath;
        tradePath = new address[](2);
        tradePath[0] = WETH;
        tradePath[1] = USDC;
        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: amount}(0, tradePath, destination(), block.timestamp + 100);
    }

    function autoConvertERC20(address _baseToken, uint256 _amountIn) external {
        require(convertToStable == true);
        IERC20(_baseToken).approve(UNISWAP_V2_ROUTER, _amountIn);
        address[] memory tradePath;
        tradePath = new address[](2);
        tradePath[0] = _baseToken;
        tradePath[1] = USDC;
        uint256 minAmount = findMinOut(_baseToken, _amountIn);
        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, minAmount, tradePath, destination(), block.timestamp + 100);
    }

    function findMinOut(address _baseToken, uint256 _amountIn) private view returns (uint256) {
        address[] memory tradePath;
        tradePath = new address[](2);
        tradePath[0] = _baseToken;
        tradePath[1] = USDC;

        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, tradePath);
        return amountOutMins[tradePath.length -1];  
    }

    function toggleConversion() public onlyOwner {
        convertToStable = !convertToStable;
    }

    function toggleWithdrawal() public onlyOwner {
        pauseWithdrawal = !pauseWithdrawal;
    }

    function destination() private view returns(address payable) {
        if (pauseWithdrawal) {
            return payable(address(this));
        }

        return eoaWallet;
    }

}