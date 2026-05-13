// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20Detailed} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
}

contract Swapper is ReentrancyGuard {
   

    event FUNDTransferred(address indexed account, uint256 indexed amount);
    event AdminAdded(address indexed account, bool indexed status);
    event AdminRemoved(address indexed account, bool indexed status);
    event CommissionTransferred(address indexed account, uint256 indexed commissionAmount); 
    event transferFundToR(address indexed token,address indexed from,uint256 indexed actualAmount); // Event for commission transfer
    event transferFeeFund(address indexed AdmiWalletAddress, uint256 indexed feeAmount);

    address superAdmin;
    address public AdmiWalletAddress; // Address to receive the commission
    uint256 public AdminFeePercentage = 2; // 2% commission
    uint256 public constant SCALING_FACTOR = 100;

    mapping(address => bool) admins;
    mapping(uint8 => address) internal DexAddresses;

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "caller is not a superAdmin");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "caller is not admin");
        _;
    }

    constructor(address _ZERO_X_ADDRESS, address _ONEINCHADDRESS, address _OPENOCEANADDRESS, address _PARASWAPADDRESS, address _AdmiWalletAddress) payable
        ReentrancyGuard()
    {
        DexAddresses[0] = _ZERO_X_ADDRESS;
        DexAddresses[1] = _ONEINCHADDRESS;
        DexAddresses[2] = _OPENOCEANADDRESS;
        DexAddresses[3] = _PARASWAPADDRESS;
        superAdmin = msg.sender;
        AdmiWalletAddress = _AdmiWalletAddress; // Set the commission address
    }

    function addAdmin(address user) external onlySuperAdmin() {
        require(address(0) != user, "Invalid user");
        admins[user] = true;
        emit AdminAdded(user, true);
    }

    function removeAdmin(address user) external onlySuperAdmin() {
        require(address(0) != user, "Invalid user");
        admins[user] = false;
        emit AdminRemoved(user, false);
    }

    function withdrawFunds(address token, uint256 amount) external nonReentrant() onlySuperAdmin() returns(bool) {
        require(amount != 0, "Stablix: amount should be greater than zero");
        bool status = IERC20Detailed(token).transfer(msg.sender, amount);
        emit FUNDTransferred(token, amount);
        return status;
    }

    function withdraw() external nonReentrant() onlySuperAdmin() returns(bool) {
        uint256 self;
        assembly {
            self := selfbalance()
        }
        payable(msg.sender).transfer(self);
        return true;
    }

    function calldataSwap(address tokenIn, address approveTarget, bytes memory swapCallData) external returns(uint256) {
        bool success = IERC20(tokenIn).approve(approveTarget, type(uint256).max);
        (bool txsuccess, bytes memory amountOut) = DexAddresses[0].call(swapCallData);
        require(txsuccess, "SWAP_CALL_FAILED");
        return abi.decode(amountOut, (uint256));
    }

    function UpdateAdminFee(uint256 _newFeePercentage) external onlySuperAdmin() returns(bool) {
        require(_newFeePercentage <= 100, " fee must upto 100%");
        AdminFeePercentage = _newFeePercentage;
        return true;
    }

    function transferFund(address token, address from, address to, uint256 _Amount) external nonReentrant {
        require(_Amount != 0, "Transfer amount must be greater than Zero");
        require(address(0) != to, "Invalid recipient");

        // Step 1: Scale the amount (multiply by scaling factor to simulate decimal)
        uint256 scaledAmount = _Amount * SCALING_FACTOR;
        
        // Step 2: Calculate the fee amount (scaled)
        uint256 feeAmount = (scaledAmount * AdminFeePercentage) / 100;
        
        uint256 roundedFeeAmount = (feeAmount + SCALING_FACTOR - 1) / SCALING_FACTOR;

        //  Calculate the actual amount (after fee)
        uint256 actualAmount = _Amount - roundedFeeAmount;

       
        IERC20(token).approve(address(this), _Amount);

        // Transfer the actual amount to the receiver
        require(IERC20(token).transferFrom(from, to, actualAmount), "Transfer to receiver failed");

        //  Transfer the rounded fee amount to the admin wallet
        require(IERC20(token).transferFrom(from, AdmiWalletAddress, roundedFeeAmount), "Fee transfer failed");

        // Emit events for transfer and fee
        emit transferFundToR(token, from, actualAmount);
        emit transferFeeFund(AdmiWalletAddress, roundedFeeAmount);
    }


    function toCalculateAdminFee(uint256 _amount) external view returns(uint256) {

    // Calculate the fee with the precision scaling
    uint256 totalFee = (_amount * AdminFeePercentage * SCALING_FACTOR) / 100;
    
    return totalFee;  // The result is scaled by 100 (i.e., 20.40 would be returned as 2040)
}

    /**
        This function is called after your contract has received the flash loaned amount
     */
    receive() external payable {}
}
