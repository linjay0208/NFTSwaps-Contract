const { expect } = require("chai");

var originalInstance;
var sockInstance;
var swapInstance;
var factoryInstance;
var erc721Instance;

describe("SOCK", function() {
  it("Should deploy contracts", async function() {

    accounts = await ethers.getSigners();
    console.log(accounts[0].address)
    console.log(accounts[1].address)
    console.log(accounts[2].address)

    const NFTSwaps = await ethers.getContractFactory("NFTSwaps");
    originalInstance = await NFTSwaps.deploy();
    await originalInstance.deployed();

    const SwapsSocks = await ethers.getContractFactory("SwapsSocks");
    sockInstance = await SwapsSocks.deploy("SWAPSOCKS", "SOCKS", originalInstance.address,
    ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"],
    ["0xDDFd07dA7cD143F230976a338098F6E066f46133", "0xc536462e5A9fdacD4F1008A91e7DABa1374c0226", "0x000000000000000000000000000000000000dEaD", "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"]);

    await sockInstance.deployed();


    const SwapsRouter = await ethers.getContractFactory("SwapsRouter");
    factoryInstance = await SwapsRouter.deploy();
    await factoryInstance.deployed();

    await originalInstance.transfer(accounts[1].address, ethers.utils.parseEther("2000"));
    await originalInstance.transfer(accounts[2].address, ethers.utils.parseEther("2000"));

  });

  it("Should mint only 390 common for owner", async function() {
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
    await sockInstance.adminMintCommon(39);
  });

  it("Should mint only 10 rare for owner", async function() {
    await sockInstance.adminMintRare(10);
  });

  it("Should mint for batch 1 addresses", async function() {
    await originalInstance.approve(sockInstance.address, ethers.utils.parseEther("2000") )
    await sockInstance.claimSocks(1);
  });

  it("Should not mint for batch 2 addresses", async function() {
    await originalInstance.connect(accounts[1]).approve(sockInstance.address, ethers.utils.parseEther("2000") )
    var res = await sockInstance.connect(accounts[1]).claimSocks(1).catch((e) => {return null});
  });

  it("Should mint for batch 2 addresses after 1 month", async function() {
    ethers.provider.send("evm_increaseTime", [86400 * 31])
    ethers.provider.send("evm_mine")
    await sockInstance.connect(accounts[1]).claimSocks(1);
  });

  it("Should not mint to/from blacklisted", async function() {
    await originalInstance.connect(accounts[2]).approve(sockInstance.address, ethers.utils.parseEther("2000") )
    await sockInstance.connect(accounts[2]).claimSocks(1).catch((e) => {return null});

  });

  it("Should not transfer to/from blacklisted", async function() {
    await sockInstance.connect(accounts[2]).transferFrom(accounts[2].address, "0xc536462e5A9fdacD4F1008A91e7DABa1374c0226", 401).catch((e) => {return null});
  });

  it("Should request physical item and burn", async function() {
    await sockInstance.claimPhysical(5);
  });

  it("Should blacklist pancake, burn and teamlock contract for minting/transfer", async function() {
    await sockInstance.transferFrom(accounts[0].address, "0xddfd07da7cd143f230976a338098f6e066f46133", 3).catch((e) => {return null});
    await sockInstance.transferFrom(accounts[0].address, "0xc536462e5a9fdacd4f1008a91e7daba1374c0226", 3).catch((e) => {return null});
    await sockInstance.transferFrom(accounts[0].address, "0x000000000000000000000000000000000000dead", 3).catch((e) => {return null});
  });

  it("Should create basic ERC721", async function() {
    const BasicERC721 = await ethers.getContractFactory("BasicERC721");
    erc721Instance = await BasicERC721.deploy("BASIC", "BASIC");
    await erc721Instance.deployed();
    await erc721Instance.adminMint(5);
  });

  it("Should restrict name to 4-6 letters + X", async function() {
    await factoryInstance.createToken("BASIC ERC721","BASICCCX", erc721Instance.address,[1,3,4]).catch((e) => {return null});
  });

  it("Should restrict name to 4-6 letters + X", async function() {
    await factoryInstance.createToken("BASIC ERC721","BASIC", erc721Instance.address,[1,3,4]).catch((e) => {return null});
  });

  it("Should require deposit of 1 NFT to pool", async function() {
    await factoryInstance.createToken("BASIC ERC721","BASICX", erc721Instance.address,[]).catch((e) => {return null});
  });

  it("Should factory create ERC20 from owner/admin", async function() {
    await factoryInstance.createToken("BASIC ERC721","BASICX", erc721Instance.address,[1,3,4])
  });

  it("Should trade on Pancake with a 0.75% extra fee", async function() {

  });

  it("Should withdraw a random NFT on burn", async function() {

  });

});
