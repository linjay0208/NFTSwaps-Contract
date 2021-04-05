//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract BasicERC721 is ERC721Enumerable, Ownable {
  using SafeMath for uint256;


  constructor(string memory name, string memory symbol) ERC721(name, symbol) {

  }

  function adminMint(uint256 _amount) external onlyOwner {
    for(uint256 x = 0; x < _amount; x++){
      _mint(msg.sender, ERC721Enumerable.totalSupply());
    }
  }

}
