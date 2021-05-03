//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract SwapsNFTX is ERC20, Ownable {
  using SafeMath for uint256;

  IERC721 pairedNFT;

  constructor(string memory _name, string memory _symbol, address _NFT) ERC20(_name, _symbol) public {
    pairedNFT = IERC721(_NFT);
    transferOwnership(msg.sender);
  }

  function factoryMint(address _user, uint256 _amount) external onlyOwner{
    _mint(_user, _amount * 1 ether);
  }

  function factoryBurn(address _user, uint256 _amount) external onlyOwner returns (bool){
    _burn(_user, _amount * 1 ether);
    return true;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}
