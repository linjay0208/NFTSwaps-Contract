//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract SwapsMining is Ownable {
  using SafeMath for uint256;

  mapping(address => address) tokenEnabled;
  mapping(address => uint256) tokenStart;
  address[] public tokenList;

  struct userData {
    uint256 stakeTime;
    uint256 unclaimed;
    uint256 stakeAmount;
  }

  mapping(address => mapping(address => userData)) public userClaims;
  mapping(address => mapping(uint256 => uint256)) public timeframes;

  uint256 public payout = uint256(5000 ether).div(7);
  uint256 public payoutPartner = uint256(1250 ether).div(7);
  address public sockContract;
  address public socksx;

  constructor(address _sockContract, address _socksx) public {
    sockContract = _sockContract;
    socksx = _socksx;
  }

  function _updateClaim(address _user, address _lpToken) internal {
    if(userClaims[_user][_lpToken].stakeTime == 0){
      return;
    }
    uint256 pay = (_lpToken == socksx ? payout : payoutPartner);
    uint256 start = userClaims[_user][_lpToken].stakeTime.sub(tokenStart[_lpToken]).div(86400);
    uint256 end = block.timestamp.sub(tokenStart[_lpToken]).div(86400);
    if(_lpToken == socksx && end > 56){
      end = 56;
    }
    else if(_lpToken != socksx && end > 28){
      end = 28;
    }
    for(uint256 x = start; x < end; x++){
      if(timeframes[_lpToken][x] != 0){
        uint256 claim = userClaims[_user][_lpToken].stakeAmount.mul(pay).div(timeframes[_lpToken][x]);
        userClaims[_user][_lpToken].unclaimed = userClaims[_user][_lpToken].unclaimed.add(claim);
      }
    }
    userClaims[_user][_lpToken].stakeTime = block.timestamp;
  }

  function _updateTimeframes(address _lpToken, uint256 _amount, bool _add) internal {
    uint256 periodStart = block.timestamp.div(86400).sub(tokenStart[_lpToken].div(86400));
    if(_add){
      for(uint256 x = periodStart; x < 56; x++){
        timeframes[_lpToken][x] = timeframes[_lpToken][x].add(_amount);
      }
    }
    else{
      for(uint256 x = periodStart; x < 56; x++){
        timeframes[_lpToken][x] = timeframes[_lpToken][x].sub(_amount);
      }
    }
  }

  function addToken(address _lpAddress, address _tokenAddress) public onlyOwner {
    tokenList.push(_lpAddress);
    tokenEnabled[_lpAddress] = _tokenAddress;
    tokenStart[_lpAddress] = block.timestamp;
  }

  function removeToken(uint256 _index) public onlyOwner {
    address _lpAddress = tokenList[_index];
    if(tokenList.length - 1 > _index){
      tokenList[_index] = tokenList[tokenList.length - 1];
    }
    delete tokenList[tokenList.length - 1];
    tokenEnabled[_lpAddress] = address(0);
    tokenStart[_lpAddress] = 0;
  }

  function depositLPToken(address _lpToken, uint256 _amount) public {
    require((_lpToken == socksx && block.timestamp < tokenStart[_lpToken].add(86400 * 56)) or (_lpToken != socksx && block.timestamp < tokenStart[_lpToken].add(86400 * 28)) , "Staking Finished");
    require(tokenEnabled[_lpToken] != address(0), "Token Not Enabled");
    _updateClaim(msg.sender, _lpToken);
    userClaims[msg.sender][_lpToken].stakeAmount = userClaims[msg.sender][_lpToken].stakeAmount.add(_amount);
    userClaims[msg.sender][_lpToken].stakeTime = block.timestamp;
    _updateTimeframes(_lpToken, _amount, true);
    IERC20(_lpToken).transferFrom(msg.sender, address(this), _amount);
  }

  function withdrawLPToken(address _lpToken, uint256 _amount) public {
    require(tokenEnabled[_lpToken] != address(0), "Token Not Enabled");
    _updateClaim(msg.sender, _lpToken);
    userClaims[msg.sender][_lpToken].stakeAmount = userClaims[msg.sender][_lpToken].stakeAmount.sub(_amount);
    userClaims[msg.sender][_lpToken].stakeTime = block.timestamp;
    _updateTimeframes(_lpToken, _amount, false);
    IERC20(_lpToken).transfer(msg.sender, _amount);
  }

  function getClaim(address _lpToken, address _user) public view returns(uint256 claim){
    if(userClaims[_user][_lpToken].stakeTime == 0){
      return 0;
    }
    uint256 pay = (_lpToken == socksx ? payout : payoutPartner);
    claim = userClaims[_user][_lpToken].unclaimed;
    uint256 start = userClaims[_user][_lpToken].stakeTime.sub(tokenStart[_lpToken]).div(86400);
    uint256 end = block.timestamp.sub(tokenStart[_lpToken]).div(86400);
    if(_lpToken == socksx && end > 56){
      end = 56;
    }
    else if(_lpToken != socksx && end > 28){
      end = 28;
    }
    for(uint256 x = start; x < end; x++){
      if(timeframes[_lpToken][x] != 0){
        claim += userClaims[_user][_lpToken].stakeAmount.mul(pay).div(timeframes[_lpToken][x]);
      }
    }
  }

  function claimStake(address _lpToken) public {
    require(tokenEnabled[_lpToken] != address(0), "Token Not Enabled");
    _updateClaim(msg.sender, _lpToken);
    uint256 reward = userClaims[msg.sender][_lpToken].unclaimed;
    userClaims[msg.sender][_lpToken].unclaimed = 0;
    IERC20(sockContract).transfer(msg.sender, reward);
  }

}
