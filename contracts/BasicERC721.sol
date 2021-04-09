//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "hardhat/console.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


contract BasicERC721 is ERC721, Ownable {
  using SafeMath for uint256;


  constructor(string memory name, string memory symbol) ERC721(name, symbol) public {

  }

  function adminMint(uint256 _amount) external onlyOwner {
    for(uint256 x = 0; x < _amount; x++){
      _mint(msg.sender, ERC721.totalSupply());
    }
  }

}
