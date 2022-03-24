// contracts/Exchange.sol
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Exchange is ERC20{
  address public tokenAddress;

  constructor(address _token) ERC20("EverestSwap-V1", "EVRST-V1"){
    require(_token != address(0), "invalid token address");

    tokenAddress = _token;
  }

  function addLiquidity(uint256 _tokenAmount) public payable 
  returns (uint256)
  {
      //Here ,we’re not depositing all tokens provided by user but only an amount calculated based on current reserves ratio.
      if (getReserve() == 0){
           IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;   
      } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

   function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
        }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();

        return _getAmount(_ethSold, address(this).balance, tokenReserve);
        }



    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

        return _getAmount(_tokenSold, tokenReserve, address(this).balance);
        }


    function ethToTokenSwap(uint256 _minTokens) public payable {//_minTokens - 
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = _getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
        }

    
    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = _getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
        }


    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
        }



    function _getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
        ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
        }


    // LP-tokens are basically ERC20 tokens issued to liquidity providers in exchange for their liquidity. In fact, LP-tokens are shares:

    // You get LP-tokens in exchange for your liquidity.
    // The amount of tokens you get is proportional to the share of your liquidity in pool’s reserves.
    // Fees are distributed proportionally to the amount of tokens you hold.
    // LP-tokens can be exchanged back for liquidity + accumulated fees.



}