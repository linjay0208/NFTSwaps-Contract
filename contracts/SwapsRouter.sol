//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./SwapsNFTX.sol";

contract SwapsRouter is Ownable {
  using SafeMath for uint256;

  mapping(address => address) public NftPairs;
  mapping(address => address) public TokenPairs;

  mapping(address => mapping (uint256 => uint256)) public tokenPools;
  mapping(address => uint256) public tokenCounts;

  constructor() {

  }

  function substring(string memory str, uint startIndex, uint endIndex) public returns (bytes memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return (result);
  }

  function _checkString(string memory str) public returns (bool) {
    if(bytes(str).length > 6){
      return false;
    }

    if(keccak256(substring(str, bytes(str).length - 1, bytes(str).length)) != keccak256(bytes("X"))) {
      return false;
    }

    return true;
  }

  function createToken(string memory _name, string memory _symbol, address _NFT, uint256[] memory tokenIds) public {
    require(_checkString(_symbol), "Invalid Symbol Name");
    require(owner() == msg.sender || Ownable(_NFT).owner() == msg.sender);
    require(tokenIds.length > 0, "Must send at least one NFT");
    require(NftPairs[_NFT] == address(0), "Pair Exists");

    SwapsNFTX swapContract = new SwapsNFTX(_name, _symbol, _NFT);
    NftPairs[_NFT] = address(swapContract);
    TokenPairs[address(swapContract)] = _NFT;

    for(uint256 x = 0; x < tokenIds.length; x++){
      tokenPools[_NFT][tokenCounts[_NFT]] = tokenIds[x];
      tokenCounts[_NFT] += 1;
    }

    swapContract.factoryMint(msg.sender, tokenIds.length);
  }


  function buyTokenPancake() public {

  }

  function sellTokenPancake() public {

  }

}
