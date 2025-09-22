pragma solidity ^0.8.0;

import "./lib/Account.sol";
import "./lib/ERC20.sol";
import {console} from "forge-std/Script.sol";

contract Vault is ERC20 {
    using Library for Account;

    Account public totalAsset;
    Account public totalBorrow;

    mapping(address => uint256) public userCollateralBalance;
    mapping(address => uint256) public userBorrowShares;
    mapping(address => uint256) public lastBorrow;
    uint256 public totalCollateral;

    ERC20 public immutable asset;
    ERC20 public immutable collateral;

    uint256 public fee;
    uint256 public tier;
    uint256 public minDepositAmount;

    constructor(ERC20 _asset, uint256[] memory params) ERC20("", "") payable {
        asset = _asset;
        collateral = _asset;

        fee = params[0];
        tier = params[1];
        minDepositAmount = params[2] * 10 ** 6;

        _mint(address(this), minDepositAmount);
        totalAsset.shares += uint128(minDepositAmount);
    }

    function totalAssets() public view returns (uint256) {
        return totalAsset.amount;
    }

    function totalShares() public view returns (uint256) {
        return totalAsset.shares;
    }

    function _deposit(Account memory _totalAsset, uint128 _amount, uint128 _shares, address _receiver) internal {
        _totalAsset.amount += _amount;
        _totalAsset.shares += _shares;

        _mint(_receiver, _shares);
        totalAsset = _totalAsset;
        
        asset.transferFrom(msg.sender, address(this), _amount);
    }

    function previewDeposit(uint256 _assets) external view returns (uint256 _sharesReceived) {
        Account memory _totalAsset = totalAsset;
        _sharesReceived = _totalAsset.toShares(_assets, false);
    }

    function deposit(uint256 _amount, address _receiver) external returns (uint256 _sharesReceived) {
        Account memory _totalAsset = totalAsset;

        _sharesReceived = _totalAsset.toShares(_amount, false);

        _deposit(_totalAsset, uint128(_amount), uint128(_sharesReceived), _receiver);
    }

    function previewMint(uint256 _shares) external view returns (uint256 _amount) {
        Account memory _totalAsset = totalAsset;
        _amount = _totalAsset.toAmount(_shares, false);
    }

    function mint(uint256 _shares, address _receiver) external returns (uint256 _amount) {
        Account memory _totalAsset = totalAsset;

        _amount = _totalAsset.toAmount(_shares, false);

        _deposit(_totalAsset, uint128(_amount), uint128(_shares), _receiver);
    }

    function _redeem(
        Account memory _totalAsset,
        uint128 _amountToReturn,
        uint128 _shares,
        address _receiver,
        address _owner
    ) internal {
        console.log("HERE1");
        if (msg.sender != _owner) {
            uint256 allowed = allowance(_owner, msg.sender);
            if (allowed != type(uint256).max) _approve(_owner, msg.sender, allowed - _shares);
        }

        uint256 _assetsAvailable = _totalAsset.amount;
        if (_assetsAvailable < _amountToReturn) {
            console.log("HERE ERROR");
            revert ERC20InsufficientBalance(address(this), _assetsAvailable, _amountToReturn);
        }
        console.log("HERE2");
        
        _totalAsset.amount -= _amountToReturn;
        _totalAsset.shares -= _shares;

        totalAsset = _totalAsset;
        console.log("HERE3");
        _burn(_owner, _shares);
        console.log("HERE4");
        console.log(asset.balanceOf(address(this)));
        asset.transfer(_receiver, _amountToReturn);
    }

    function previewRedeem(uint256 _shares) external view returns (uint256 _assets) {
        Account memory _totalAsset = totalAsset;
        _assets = _totalAsset.toAmount(_shares, false);
    }

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 _amountToReturn) {
        Account memory _totalAsset = totalAsset;

        _amountToReturn = _totalAsset.toAmount(_shares, false);
        console.log(_amountToReturn);
        _redeem(_totalAsset, uint128(_amountToReturn), uint128(_shares), _receiver, _owner);
    }

    function previewWithdraw(uint256 _amount) external view returns (uint256 _sharesToBurn) {
        Account memory _totalAsset = totalAsset;
        _sharesToBurn = _totalAsset.toShares(_amount, true);
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) external returns (uint256 _sharesToBurn) {
        Account memory _totalAsset = totalAsset;
        console.log("HI");
        _sharesToBurn = _totalAsset.toShares(_amount, true);
        console.log(_sharesToBurn);
        _redeem(_totalAsset, uint128(_amount), uint128(_sharesToBurn), _receiver, _owner);
    }

    function _totalAssetAvailable(
        Account memory _totalAsset,
        Account memory _totalBorrow
    ) internal pure returns (uint256) {
        return _totalAsset.amount - _totalBorrow.amount;
    }
    function _borrowAsset(uint128 _borrowAmount, address _receiver) internal returns (uint256 _sharesAdded) {
        Account memory _totalBorrow = totalBorrow;

        uint256 _assetsAvailable = _totalAssetAvailable(totalAsset, _totalBorrow);
        if (_assetsAvailable < _borrowAmount) {
            revert();
        }

        _sharesAdded = _totalBorrow.toShares(_borrowAmount, true);

        _totalBorrow.amount += _borrowAmount;
        _totalBorrow.shares += uint128(_sharesAdded);

        totalBorrow = _totalBorrow;
        userBorrowShares[msg.sender] += _sharesAdded;
        lastBorrow[msg.sender] = block.number;

        if (_receiver != address(this)) {
            asset.transfer(_receiver, _borrowAmount);
        }
    }

    function borrowAsset(
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _receiver
    ) external returns (uint256 _shares) {

        {
            Account memory _totalBorrow = totalBorrow;
            uint256 existingBorrowAmount = _totalBorrow.toAmount(userBorrowShares[msg.sender], false);
            uint256 projectedBorrowAmount = existingBorrowAmount + _borrowAmount;
            uint256 availableCollateral = userCollateralBalance[msg.sender] + _collateralAmount;
            if (projectedBorrowAmount > availableCollateral) {
                revert();
            }
        }


        if (_collateralAmount > 0) {
            _addCollateral(msg.sender, _collateralAmount, msg.sender);
        }

        _shares = _borrowAsset(uint128(_borrowAmount), _receiver);
    }

    function _addCollateral(address _sender, uint256 _collateralAmount, address _borrower) internal {
        userCollateralBalance[_borrower] += _collateralAmount;
        totalCollateral += _collateralAmount;

        if (_sender != address(this)) {
            collateral.transferFrom(_sender, address(this), _collateralAmount);
        }
    }

    function addCollateral(uint256 _collateralAmount, address _borrower) external {
        _addCollateral(msg.sender, _collateralAmount, _borrower);
    }

    function _removeCollateral(uint256 _collateralAmount, address _receiver, address _borrower) internal {
        userCollateralBalance[_borrower] -= _collateralAmount;
        totalCollateral -= _collateralAmount;

        if (_receiver != address(this)) {
            collateral.transfer(_receiver, _collateralAmount);
        }
    }

    function removeCollateral(
        uint256 _collateralAmount,
        address _receiver
    ) external {
        if (userBorrowShares[msg.sender] > 0) {
            Account memory _totalBorrow = totalBorrow;
            uint256 existingBorrowAmount = _totalBorrow.toAmount(userBorrowShares[msg.sender], false);
            uint256 availableCollateral = userCollateralBalance[msg.sender];
            if (_collateralAmount > existingBorrowAmount - availableCollateral) {
                revert();
            }
        }
        _removeCollateral(_collateralAmount, _receiver, msg.sender);
    }

    function _repayAsset(
        Account memory _totalBorrow,
        uint128 _amountToRepay,
        uint128 _shares,
        address _payer,
        address _borrower
    ) internal {
        _totalBorrow.amount -= _amountToRepay;
        _totalBorrow.shares -= _shares;

        userBorrowShares[_borrower] -= _shares;
        totalBorrow = _totalBorrow;

        uint256 fees = block.number - lastBorrow[_borrower];
        totalAsset.amount += uint128(fees);

        if (_payer != address(this)) {
            asset.transferFrom(_payer, address(this), _amountToRepay + fees);
        }
    }

    function repayAsset(uint256 _shares, address _borrower) external returns (uint256 _amountToRepay) {
        Account memory _totalBorrow = totalBorrow;
        _amountToRepay = _totalBorrow.toAmount(_shares, true);

        _repayAsset(_totalBorrow, uint128(_amountToRepay), uint128(_shares), msg.sender, _borrower);
    }
}