const swapper = artifacts.require("Swapper");

module.exports = async function (deployer,accounts) {
  const ZERO_X_ADDRESS = "0xdef1c0ded9bec7f1a1670819833240f027b25eff";  // Replace with actual addresses
  const ONEINCHADDRESS = "0xdef1c0ded9bec7f1a1670819833240f027b25eff";  // Replace with actual addresses
  const OPENOCEANADDRESS = "0xdef1c0ded9bec7f1a1670819833240f027b25eff";  // Replace with actual addresses
  const PARASWAPADDRESS = "0xdef1c0ded9bec7f1a1670819833240f027b25eff";  // Replace with actual addresses
  const AdmiWalletAddress = accounts[0];  // Use the first account as the admin wallet (or any other wallet)

  // Deploy the contract
  const SwapperInstance = await deployer.deploy(swapper, ZERO_X_ADDRESS, ONEINCHADDRESS, OPENOCEANADDRESS, PARASWAPADDRESS, AdmiWalletAddress, { gas: 5000000 });
  console.log("Swapper contract deployed at address:", SwapperInstance.address);
};





// 0xdef1c0ded9bec7f1a1670819833240f027b25eff