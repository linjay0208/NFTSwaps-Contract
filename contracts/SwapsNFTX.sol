//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract SwapsNFTX is ERC20, Ownable {
  using SafeMath for uint256;

  IERC721 pairedNFT;

  constructor(string memory name, string memory symbol, address _NFT) ERC20(name, symbol) public {
    pairedNFT = IERC721(_NFT);
    transferOwnership(msg.sender);
  }

  function factoryMint(address _user, uint256 _amount) public onlyOwner{
    _mint(_user, _amount * 1 ether);
  }

  function factoryBurn(address _user, uint256 _amount) public onlyOwner returns (bool){
    _burn(_user, _amount * 1 ether);
    return true;
  }


}
