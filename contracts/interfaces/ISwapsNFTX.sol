pragma solidity >=0.6.2;

interface ISwapsNFTX {
    function factoryMint(address _user, uint256 _amount) external;
    function factoryBurn(address _user, uint256 _amount) external returns (bool);
    function approve(address _user, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _user, uint256 _amount) external returns (bool);
    function balanceOf(address _user) external view returns (uint256);
    function burn(uint256 _amount) external;
}
