//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract SwapsSocks is ERC721, Ownable {
  using SafeMath for uint256;

  IERC20 sockSwapContract;
  mapping(address => bool) public blacklist;
  mapping(address => bool) public batchOne;
  mapping(address => uint256) public whitelist;
  mapping(uint256 => uint256) public isRare;
  uint256 public adminCommonMintCount;
  uint256 public adminRareMintCount;
  uint256 startTimestamp;

  event ClaimRequest(address owner, uint256 tokenId);

  constructor(string memory name, string memory symbol, address sockContract, address[] memory whitelisted, address[] memory blacklisted) ERC721(name, symbol) public {
    sockSwapContract = IERC20(sockContract);
    startTimestamp = block.timestamp;
    for(uint256 x = 0; x < whitelisted.length; x++){
      batchOne[whitelisted[x]] = true;
    }

    for(uint256 x = 0; x < blacklisted.length; x++){
      blacklist[blacklisted[x]] = true;
    }
  }

  function addToWhitelist(address[] calldata users, uint256[] calldata amount) external onlyOwner{
    for(uint256 x = 0; x < amount.length; x++){
      whitelist[users[x]] += amount[x];
    }
  }

  function adminMintRare(uint256 _amount) external onlyOwner {
    require(adminRareMintCount + _amount <= 10, "Max Rare Socks Minted!");
    for(uint256 x = 0; x < _amount; x++){
      isRare[ERC721.totalSupply()] = adminRareMintCount + x + 1;
      _mint(msg.sender, ERC721.totalSupply());
    }
    adminRareMintCount += _amount;
  }

  function adminMintCommon(uint256 _amount) external onlyOwner {
    require(adminCommonMintCount + _amount <= 390, "Max Common Socks Minted!");
    for(uint256 x = 0; x < _amount; x++){
      _mint(msg.sender, ERC721.totalSupply());
    }
    adminCommonMintCount += _amount;
  }

  function claimSocks(uint256 _amount) external payable {
      require(!blacklist[msg.sender], "ERC721: Sender Blacklisted");
      require(batchOne[msg.sender] && whitelist[msg.sender] >= _amount || whitelist[msg.sender] >= _amount && block.timestamp > startTimestamp + (86400 * 30), "ERC721: You cannot mint!");
      for(uint256 x = 0; x < _amount; x++){
        _mint(msg.sender, ERC721.totalSupply());
        whitelist[msg.sender]--;
      }
      sockSwapContract.transferFrom(msg.sender, address(0), _amount * (1000 ether));
      address(uint160(owner())).transfer(msg.value);
  }

  function claimPhysical(uint256 _tokenId) external payable {
      require(msg.value >= 0.25 ether);
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
