pragma solidity >=0.6.2;

interface ISwapsNFTX {
    function factoryMint(address _user, uint256 _amount) external;
    function factoryBurn(address _user, uint256 _amount) external returns (bool);
}
