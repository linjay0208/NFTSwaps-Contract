//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./SwapsNFTX.sol";
import './interfaces/IPancakeRouter02.sol';
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract SwapsRouter is Ownable, VRFConsumerBase {


  mapping(address => address) public NftPairs;
  mapping(address => address) public TokenPairs;

  mapping(address => mapping (uint256 => uint256)) public tokenPools;
  mapping(address => uint256) public tokenCounts;

  IPancakeRouter02 pancake;
  address weth;

  bytes32 internal keyHash;
  uint256 internal fee;
  address internal requester;
  uint256 public randomResult;
  address public withdrawalToken;

  constructor(
    address _pancake,
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint256 _fee)
    VRFConsumerBase(_vrfCoordinator, _linkToken) public {
    pancake = IPancakeRouter02(_pancake);
    keyHash = _keyHash;
    fee = _fee;
  }

  function claimRandomNFT(address _withdrawalToken, uint256 userProvidedSeed) public returns (bytes32 requestId) {
      require(TokenPairs[_withdrawalToken] != address(0), "Invalid Token");
      require(SwapsNFTX(_withdrawalToken).factoryBurn(msg.sender, 1), "Insufficient Tokens");
      require(keyHash != bytes32(0), "Must have valid key hash");
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      requester = msg.sender;
      withdrawalToken = TokenPairs[_withdrawalToken];
      return requestRandomness(keyHash, fee, userProvidedSeed);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      randomResult = randomness % tokenCounts[withdrawalToken];
      uint256 nftPicked = tokenPools[withdrawalToken][randomResult];
      if(tokenCounts[withdrawalToken] > 1){
        tokenPools[withdrawalToken][randomResult] = tokenPools[withdrawalToken][tokenCounts[withdrawalToken]];
      }
      tokenPools[withdrawalToken][tokenCounts[withdrawalToken]] = 0;
      tokenCounts[withdrawalToken]--;
      IERC721(withdrawalToken).transferFrom(address(this), requester, nftPicked);
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


  function buyTokenPancake(address token) public payable {
    require(msg.value > 0, "Cannot Trade 0 ETH!");
    address payable owner = payable(owner());
    owner.transfer(msg.value.mul(3).div(400));
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = token;
    pancake.swapExactETHForTokens(0, path, msg.sender, block.timestamp + 600);
  }

  function sellTokenPancake(address token, uint256 _amount) public {
    SwapsNFTX(token).transferFrom(msg.sender, address(this), _amount);
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = weth;
    pancake.swapExactTokensForETH(_amount.mul(397).div(400), 0, path, msg.sender, block.timestamp + 600);
  }

  function withdrawTokens(address token, uint256 _amount) public onlyOwner {
    SwapsNFTX(token).transfer(msg.sender, _amount);
  }

}
