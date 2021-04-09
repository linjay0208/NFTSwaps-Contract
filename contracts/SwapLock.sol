//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract SwapLock {
  IERC20 tokenContract;
  mapping (address => uint256) public lockList;
  uint256 public totalLocked;
  bool public unlocked;
  address _owner = 0x2f5296f74B5D46F195a3cFC254B4cAD6EdF111ff;

  event FundsLocked(address _user, uint256 _amount);

  modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

  constructor(address _tokenContract) public {
    tokenContract = IERC20(_tokenContract);
  }

  function unlockTokens() public onlyOwner {
    unlocked = !unlocked;
  }

  function lockSwaps(uint256 _amount) public {
    require(lockList[msg.sender] + _amount <= 15000 ether, "Amount Exceeds Limit");
    require(lockList[msg.sender] + _amount >= 5000 ether, "Amount Under Minimum");
    require(tokenContract.transferFrom(msg.sender, address(this), _amount), "Insufficient Tokens Approved");
    lockList[msg.sender] += _amount;
    totalLocked += _amount;
    emit FundsLocked(msg.sender, _amount);
  }

  function claimSwaps(uint256 _amount) public {
    require(lockList[msg.sender] >= _amount, "Insufficient Locked Tokens");
    require(unlocked, "Lock Timer Incomplete");
    totalLocked -= _amount;
    lockList[msg.sender] -= _amount;
    tokenContract.transfer(msg.sender, _amount);
  }

}
