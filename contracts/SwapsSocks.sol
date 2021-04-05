//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract SwapsSocks is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  string public defaultTokenURI;
  IERC20 sockSwapContract;
  mapping(address => bool) public blacklist;
  mapping(address => bool) public batchOne;
  mapping(uint256 => bool) public isRare;
  uint256 public adminCommonMintCount;
  uint256 public adminRareMintCount;
  uint256 startTimestamp;

  event ClaimRequest(address owner, uint256 tokenId);

  constructor(string memory name, string memory symbol, address sockContract, address[] memory whitelisted, address[] memory blacklisted) ERC721(name, symbol) {
    sockSwapContract = IERC20(sockContract);
    for(uint256 x = 0; x < whitelisted.length; x++){
      batchOne[whitelisted[x]] = true;
    }

    for(uint256 x = 0; x < blacklisted.length; x++){
      blacklist[blacklisted[x]] = true;
    }
  }

  function setDefaultTokenURI(string memory newDefaultTokenUri) external onlyOwner {
      defaultTokenURI = newDefaultTokenUri;
  }

  function adminMintRare(uint256 _amount) external onlyOwner {
    require(adminRareMintCount + _amount <= 10, "Max Rare Socks Minted!");
    for(uint256 x = 0; x < _amount; x++){
      isRare[ERC721Enumerable.totalSupply()] = true;
      _mint(msg.sender, ERC721Enumerable.totalSupply());
    }
    adminRareMintCount += _amount;
  }

  function adminMintCommon(uint256 _amount) external onlyOwner {
    require(adminCommonMintCount + _amount <= 390, "Max Common Socks Minted!");
    for(uint256 x = 0; x < _amount; x++){
      _mint(msg.sender, ERC721Enumerable.totalSupply());
    }
    adminCommonMintCount += _amount;
  }

  function claimSocks(uint256 _amount) external {
      require(!blacklist[msg.sender], "ERC721: Sender Blacklisted");
      require(batchOne[msg.sender] || block.timestamp > startTimestamp + (86400 * 30), "ERC721: You cannot mint yet!");
      require(sockSwapContract.transferFrom(msg.sender, address(0), _amount * (1000 ether)));
      for(uint256 x = 0; x < _amount; x++){
        _mint(msg.sender, ERC721Enumerable.totalSupply());
      }

  }

  function claimPhysical(uint256 _tokenId) external {
      require(!blacklist[msg.sender], "ERC721: Sender Blacklisted");
      transferFrom(msg.sender, address(this), _tokenId);

      _burn(_tokenId);
      emit ClaimRequest(msg.sender, _tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(!blacklist[from], "ERC721: Sender Blacklisted");
        require(!blacklist[to], "ERC721: Receiver Blacklisted");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

  /**
   * @dev See {IERC721-safeTransferFrom} modified to discriminate for blacklist.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(!blacklist[from], "ERC721: Sender Blacklisted");
        require(!blacklist[to], "ERC721: Receiver Blacklisted");
        _safeTransfer(from, to, tokenId, _data);
    }



}
