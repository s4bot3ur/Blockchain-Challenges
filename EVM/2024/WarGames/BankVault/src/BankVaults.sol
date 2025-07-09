// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address allowanceOwner, address spender) external view returns (uint256);
}

interface IERC4626 {
    function withdraw(uint256 assets, address receiver, address withdrawOwner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address redeemOwner) external returns (uint256 assets);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function maxMint(address receiver) external view returns (uint256);
    function maxWithdraw(address withdrawOwner) external view returns (uint256);
    function maxRedeem(address redeemOwner) external view returns (uint256);
}

interface IFlashLoanReceiver {
    function executeFlashLoan(uint256 amount) external;
}

contract BankVaults is IERC4626 {
    IERC20 public immutable asset;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeTimestamps;
    mapping(address => bool) public isStaker;
    address public contractOwner;
    uint256 public constant MINIMUM_STAKE_TIME = 2 * 365 days;

    string public name = "BankVaultToken";
    string public symbol = "BVT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public vaultTokenBalances;
    mapping(address => mapping(address => uint256)) public allowances;

    modifier onlyStaker() {
        require(isStaker[msg.sender], "Caller is not a staker");
        _;
    }

    constructor(IERC20 _asset) payable {
        asset = _asset;
        contractOwner = msg.sender;

        
        uint256 initialSupply = 10_000_000 ether; 
        vaultTokenBalances[contractOwner] = initialSupply;
        totalSupply = initialSupply;
    }

    // Native ETH staking
    function stake(address receiver) public payable returns (uint256 shares) {
        require(msg.value > 0, "Must deposit more than 0"); 

        shares = convertToShares(msg.value); 
        balances[receiver] += msg.value; 
        stakeTimestamps[receiver] = block.timestamp; 

        vaultTokenBalances[receiver] += shares; 
        totalSupply += shares; 

        isStaker[receiver] = true; 

        return shares;
    }

    function withdraw(uint256 assets, address receiver, address owner) public override onlyStaker returns (uint256 shares) {
        
        require(vaultTokenBalances[owner] >= assets, "Insufficient vault token balance");
        uint256 yield = (assets * 1) / 100;
        uint256 totalReturn = assets + yield;
        require(address(this).balance >= assets, "Insufficient contract balance");
        
        
        shares = convertToShares(assets);
        vaultTokenBalances[owner] -= assets;
        totalSupply -= assets;
        balances[owner] -= assets;
        isStaker[receiver] = false;

        
        payable(receiver).transfer(assets);

        return shares;
    }

    function calculateYield(uint256 assets, uint256 duration) public pure returns (uint256) {
        if (duration >= 365 days) {
            return (assets * 5) / 100; 
        } else if (duration >= 180 days) {
            return (assets * 3) / 100; 
        } else {
            return (assets * 1) / 100; 
        }
    }


    function flashLoan(uint256 amount, address receiver, uint256 timelock) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] > 0, "No stake found for the user");

        unchecked {
            require(timelock >= stakeTimestamps[msg.sender] + MINIMUM_STAKE_TIME, "Minimum stake time not reached");
        }

        require(address(this).balance >= amount, "Insufficient ETH for flash loan");

        uint256 balanceBefore = address(this).balance;

        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "ETH transfer failed");

        IFlashLoanReceiver(receiver).executeFlashLoan(amount);

        uint256 balanceAfter = address(this).balance;

        require(balanceAfter >= balanceBefore, "Flash loan wasn't fully repaid in ETH");
    }


    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        require(shares > 0, "Must redeem more than 0");
        require(vaultTokenBalances[owner] >= shares, "Insufficient vault token balance");
        require(block.timestamp >= stakeTimestamps[owner] + MINIMUM_STAKE_TIME, "Minimum stake time not reached");

        assets = convertToAssets(shares);

        vaultTokenBalances[owner] -= shares;
        totalSupply -= shares;
        balances[owner] -= assets;

        require(asset.transfer(receiver, assets), "Redemption failed");
        return assets;
    }

    function rebalanceVault(uint256 threshold) public returns (bool) {
        require(threshold > 0, "Threshold must be greater than 0");
        uint256 assetsInVault = asset.balanceOf(address(this));
        uint256 sharesToBurn = convertToShares(assetsInVault / 2);
        totalSupply -= sharesToBurn; 
        return true; 
    }

    function dynamicConvert(uint256 assets, uint256 multiplier) public pure returns (uint256) {
        return (assets * multiplier) / 10;
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        return assets;
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return shares;
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function maxDeposit(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address withdrawOwner) public view override returns (uint256) {
        return vaultTokenBalances[withdrawOwner];
    }

    function maxRedeem(address redeemOwner) public view override returns (uint256) {
        return vaultTokenBalances[redeemOwner];
    }

    receive() external payable {}
}
