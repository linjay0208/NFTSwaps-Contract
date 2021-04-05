//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
 
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract SwapsNFTX is ERC20 {
  using SafeMath for uint256;

  IERC721 pairedNFT;

  constructor(string memory name, string memory symbol, address _NFT) ERC20(name, symbol) {
    pairedNFT = IERC721(_NFT);
  }

  function factoryMint(address _user, uint256 _amount) public{
    _mint(_user, _amount * 1 ether);
  }


}
