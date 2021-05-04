//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./interfaces/ISwapsNFTX.sol";
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
  IPancakeRouter02 pancakeV1;
  address weth;
  address swapAddress;

  bytes32 internal keyHash;
  uint256 internal fee;
  address internal requester;
  uint256 public randomResult;
  mapping(bytes32 => address) public withdrawalToken;
  mapping(bytes32 => bool) public nameMap;

  event NewPair(address nft, string symbol, address erc20, uint256 amount);
  event TokenMint(address nft, uint256 id, uint256 amount);
  event TokenConvert(address nft, uint256 id);

  constructor(
    address _vrfCoordinator, //	0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31
    address _linkToken, //0x404460C6A5EdE2D891e8297795264fDe62ADBB75
    address _swapAddress
    )
    VRFConsumerBase(_vrfCoordinator, _linkToken) public {
      pancake = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//0x10ED43C718714eb63d5aA57B78B54704E256024E //0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
      pancakeV1 = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
      keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
      fee = 0.2 ether;
      weth = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
      swapAddress = _swapAddress;
      ISwapsNFTX(weth).approve(address(pancake), (2**256)-1);
  }

  function setPancakeV1(address _newAddress) external onlyOwner{
    pancakeV1 = IPancakeRouter02(_newAddress);
  }

  function setLink(uint256 _amount) external onlyOwner {
    fee = _amount;
  }

  function claimRandomNFT(address _withdrawalToken, uint256 userProvidedSeed) external returns (bytes32 requestId) {
      require(TokenPairs[_withdrawalToken] != address(0), "Invalid Token");
      require(keyHash != bytes32(0), "Must have valid key hash");
      LINK.transferFrom(msg.sender, address(this), 0.2 ether);
      require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
      requester = msg.sender;
      requestId = requestRandomness(keyHash, fee, userProvidedSeed);
      withdrawalToken[requestId] = TokenPairs[_withdrawalToken];
      require(ISwapsNFTX(_withdrawalToken).factoryBurn(msg.sender, 1), "Insufficient Tokens");
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      randomResult = randomness % tokenCounts[withdrawalToken[requestId]];
      uint256 nftPicked = tokenPools[withdrawalToken[requestId]][randomResult];
      if(tokenCounts[withdrawalToken[requestId]] > 1){
        tokenPools[withdrawalToken[requestId]][randomResult] = tokenPools[withdrawalToken[requestId]][tokenCounts[withdrawalToken[requestId]]];
      }
      tokenPools[withdrawalToken[requestId]][tokenCounts[withdrawalToken[requestId]]] = 0;
      tokenCounts[withdrawalToken[requestId]]--;
      emit TokenConvert(withdrawalToken[requestId], nftPicked);
      IERC721(withdrawalToken[requestId]).transferFrom(address(this), requester, nftPicked);
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return (result);
  }

  function _checkString(string memory str) internal view returns (bool) {
    if(bytes(str).length > 6){
      return false;
    }

    if(keccak256(substring(str, bytes(str).length - 1, bytes(str).length)) != keccak256(bytes("X"))) {
      return false;
    }

    if(nameMap[keccak256(abi.encodePacked(str))]) {
      return false;
    }

    return true;
  }

  function createToken(string calldata _name, string calldata _symbol, address _NFT, uint256[] calldata tokenIds) external {
    require(_checkString(_symbol), "Invalid Symbol Name");
    require(owner() == msg.sender || Ownable(_NFT).owner() == msg.sender);
    require(tokenIds.length > 0, "Must send at least one NFT");
    require(NftPairs[_NFT] == address(0), "Pair Exists");
    SwapsNFTX swapContract = new SwapsNFTX(_name, _symbol, _NFT);
    NftPairs[_NFT] = address(swapContract);
    TokenPairs[address(swapContract)] = _NFT;
    nameMap[keccak256(abi.encodePacked(_symbol))] = true;

    emit NewPair(_NFT, _symbol, address(swapContract), tokenIds.length);

    for(uint256 x = 0; x < tokenIds.length; x++){
      tokenPools[_NFT][tokenCounts[_NFT]] = tokenIds[x];
      tokenCounts[_NFT] += 1;
      IERC721(_NFT).transferFrom(msg.sender, address(this), tokenIds[x]);
    }

    swapContract.approve(address(pancake), (2**256)-1);
    swapContract.factoryMint(msg.sender, tokenIds.length);
  }

  function mintToken(address _NFT, uint256[] calldata tokenIds) external {
    require(tokenIds.length > 0, "Must send at least one NFT");
    require(NftPairs[_NFT] != address(0), "Pair Doesnt Exist");
    ISwapsNFTX swapContract = ISwapsNFTX(NftPairs[_NFT]);
    for(uint256 x = 0; x < tokenIds.length; x++){
      tokenPools[_NFT][tokenCounts[_NFT]] = tokenIds[x];
      tokenCounts[_NFT] += 1;
      emit TokenMint(_NFT, tokenIds[x], 1);
      IERC721(_NFT).transferFrom(msg.sender, address(this), tokenIds[x]);
    }
    swapContract.factoryMint(msg.sender, tokenIds.length);
  }

  function buyTokenPancake(address token) external payable {
    require(msg.value > 0, "Cannot Trade 0 ETH!");
    address payable owner = payable(owner());
    uint256 rebuy = msg.value.mul(3).div(400);

    address[] memory pathSwaps = new address[](2);
    pathSwaps[0] = weth;
    pathSwaps[1] = swapAddress;
    pancakeV1.swapExactETHForTokens{value: rebuy}(0, pathSwaps, address(this), block.timestamp + 600);
    ISwapsNFTX(swapAddress).transfer(owner, ISwapsNFTX(swapAddress).balanceOf(address(this)).div(5));
    ISwapsNFTX(swapAddress).transfer(0x000000000000000000000000000000000000dEaD, ISwapsNFTX(swapAddress).balanceOf(address(this)).mul(4).div(5));

    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = token;
    pancake.swapExactETHForTokens{value: msg.value.mul(397).div(400)}(0, path, msg.sender, block.timestamp + 600);
  }

  function sellTokenPancake(address token, uint256 _amount) external {
    ISwapsNFTX(token).transferFrom(msg.sender, address(this), _amount);
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = weth;
    pancake.swapExactTokensForETH(_amount.mul(397).div(400), 0, path, msg.sender, block.timestamp + 600);
  }

  function withdrawTokens(address token, uint256 _amount) external onlyOwner {
    ISwapsNFTX(token).transfer(msg.sender, _amount);
  }

}
