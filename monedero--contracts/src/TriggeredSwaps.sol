// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
  ______     _                                _______                         
 /_  __/____(_)___ _____ ____  ________  ____/ / ___/      ______ _____  _____
  / / / ___/ / __ `/ __ `/ _ \/ ___/ _ \/ __  /\__ \ | /| / / __ `/ __ \/ ___/
 / / / /  / / /_/ / /_/ /  __/ /  /  __/ /_/ /___/ / |/ |/ / /_/ / /_/ (__  ) 
/_/ /_/  /_/\__, /\__, /\___/_/   \___/\__,_//____/|__/|__/\__,_/ .___/____/  
           /____//____/                                        /_/            

 * @title triggerSwap
 * @author jistro.eth & Ariutokintumi.eth
 */

import {Staking} from "@monedero/contracts/Staking.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {mUSDC} from "@monedero/contracts/mUSDC.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract TriggeredSwaps is ReentrancyGuard {
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    //Variables
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    error UserHasNotEnoughmUSDC();
    error OrderAlreadyCanceled();
    error AccessDenied();
    error NotTimeToClaimYet();
    error TransferFailed();

    struct Order {
        address userAddress;
        uint256 mUSDCAmount;
        address tokenAddress_target;
        uint256 targetPrice;
        uint256 expirationTimestamp;
        bool isActive;
    }

    /**
     * @dev Allows storing address with time to claim.
     * @param actual Address of the current address.
     * @param proposed Address of the proposed address.
     * @param timeToClaim Time when the proposed address can be claimed.
     */
    struct AddressStructData {
        address actual;
        address proposed;
        uint256 timeToClaim;
    }

    /**
     * @dev Allows storing uint256 with time to claim.
     * @param actual uint256 of the current uint256.
     * @param proposed uint256 of the proposed uint256.
     * @param timeToClaim Time when the proposed uint256 can be claimed.
     */
    struct Uint24StructData {
        uint24 actual;
        uint24 proposed;
        uint256 timeToClaim;
    }

    bytes1 private triggerConstructorTokens = 0x00;

    uint256 firstPositiveOrderID = 0;

    AddressStructData private StakingAddress;
    AddressStructData private mUSDCAddress;
    AddressStructData private USDCAddress;
    AddressStructData private masterWallet;
    AddressStructData private swapRouterAddress;
    Uint24StructData private poolFee;

    Order[] public orders;

    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    //modifiers
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    modifier onlyMasterWallet() {
        if (msg.sender != masterWallet.actual) {
            revert AccessDenied();
        }
        _;
    }

    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    //Constructors
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    constructor(
        address _masterWallet,
        address _stakingAddress,
        address _swapRouterAddress
    ) {
        masterWallet.actual = _masterWallet;
        StakingAddress.actual = _stakingAddress;
        swapRouterAddress.actual = _swapRouterAddress;
        poolFee.actual = 15000;
    }

    function constructorTokens(
        address _mUSDCAddress,
        address _USDCAddress
    ) external {
        if (triggerConstructorTokens != 0x00) {
            revert();
        }
        mUSDCAddress.actual = _mUSDCAddress;
        USDCAddress.actual = _USDCAddress;
        triggerConstructorTokens = 0x01;
    }

    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    //External functions
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    /**
     * @notice Create a new order that use mUSDC to trigger a swap
     * @param _mUSDCAmount amount of mUSDC to use
     * @param _tokenAddress_target token address to buy
     * @param _targetPrice target price to buy the token
     * @param _expirationTimestamp expiration timestamp of the order
     */
    function createTrigger(
        uint256 _mUSDCAmount,
        address _tokenAddress_target,
        uint256 _targetPrice,
        uint256 _expirationTimestamp
    ) external nonReentrant returns (uint256 orderID) {
        if (IERC20(mUSDCAddress.actual).balanceOf(msg.sender) >= 10000) {
            revert UserHasNotEnoughmUSDC();
        }

        Staking(StakingAddress.actual).burnAndTransferToTriggerSwaps(
            msg.sender,
            10000
        );

        orders.push(
            Order({
                userAddress: msg.sender,
                mUSDCAmount: _mUSDCAmount,
                tokenAddress_target: _tokenAddress_target,
                targetPrice: _targetPrice,
                expirationTimestamp: _expirationTimestamp,
                isActive: true
            })
        );

        Staking(StakingAddress.actual).stakingUSDC(10000);

        if (!IERC20(mUSDCAddress.actual).transfer(masterWallet.actual, 10000)) {
            revert TransferFailed();
        }

        return orders.length - 1;
    }

    /**
     * @notice Cancel an order
     * @param _orderID the orderID owned by the user to cancel
     */
    function cancelTrigger(uint256 _orderID) external nonReentrant {
        if (!orders[_orderID].isActive) {
            revert OrderAlreadyCanceled();
        }

        orders[_orderID].isActive = false;
    }

    /**
     * @notice Dispach various orders
     * @param _orderIDs the orderIDs owned by the user to cancel
     */
    function triggerOrder(uint256[] calldata _orderIDs) external nonReentrant {
        for (uint256 i = 0; i < _orderIDs.length; i++) {
            _makeTriggerOrder(_orderIDs[i]);
        }
    }

    /**
     * @notice Dispach all the active and not expired orders
     */
    function flushTrigger() external nonReentrant {
        bool flagOrderActiveDecided = false;
        // comienza desde el primer orderID positivo (firstPositiveOrderID)
        for (uint256 i = firstPositiveOrderID; i < orders.length; i++) {
            _makeTriggerOrder(i);
            //aprovecha y busca el siguiente orderID positivo
            if (orders[i].isActive && !flagOrderActiveDecided) {
                firstPositiveOrderID = i;
                flagOrderActiveDecided = true;
            }
        }
    }

    /**
     * @notice Cancel all the expired orders
     */
    function removeExpired() external nonReentrant {
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].expirationTimestamp < block.timestamp) {
                orders[i].isActive = false;
            }
        }
    }

    //●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●
    //Admin functions
    //●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●

    /**
     * @dev the next functions allow the administrator to
     *      propose a change in some important variables
     *      of the contract.
     *
     *      The process is as follows:
     *      a) The administrator proposes a change and executes
     *          1. The administrator proposes a change.
     *          2. The administrator waits for a day.
     *          3. The administrator claims the change.
     *
     *      b) The administrator proposes a change and cancels
     *          1. The administrator proposes a change.
     *          2. The administrator cancels the change.
     */

    function propose_StakingAddress(
        address _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        StakingAddress.proposed = _proposed;
        StakingAddress.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_StakingAddress() external onlyMasterWallet {
        StakingAddress.proposed = StakingAddress.actual;
        StakingAddress.timeToClaim = 0;
    }

    function claim_StakingAddress() external onlyMasterWallet {
        if (StakingAddress.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }

        StakingAddress.actual = StakingAddress.proposed;
    }

    function propose_mUSDCAddress(
        address _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        mUSDCAddress.proposed = _proposed;
        mUSDCAddress.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_mUSDCAddress() external onlyMasterWallet {
        mUSDCAddress.proposed = mUSDCAddress.actual;
        mUSDCAddress.timeToClaim = 0;
    }

    function claim_mUSDCAddress() external onlyMasterWallet {
        if (mUSDCAddress.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }
        mUSDCAddress.actual = mUSDCAddress.proposed;
    }

    function propose_USDCAddress(
        address _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        USDCAddress.proposed = _proposed;
        USDCAddress.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_USDCAddress() external onlyMasterWallet {
        USDCAddress.proposed = USDCAddress.actual;
        USDCAddress.timeToClaim = 0;
    }

    function claim_USDCAddress() external onlyMasterWallet {
        if (USDCAddress.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }
        USDCAddress.actual = USDCAddress.proposed;
    }

    function propose_masterWallet(
        address _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        masterWallet.proposed = _proposed;
        masterWallet.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_masterWallet() external onlyMasterWallet {
        masterWallet.proposed = masterWallet.actual;
        masterWallet.timeToClaim = 0;
    }

    function claim_masterWallet() external {
        if (masterWallet.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }

        if (msg.sender != masterWallet.proposed) {
            revert AccessDenied();
        }
        masterWallet.actual = masterWallet.proposed;
    }

    function propose_swapRouterAddress(
        address _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        swapRouterAddress.proposed = _proposed;
        swapRouterAddress.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_swapRouterAddress() external onlyMasterWallet {
        swapRouterAddress.proposed = swapRouterAddress.actual;
        swapRouterAddress.timeToClaim = 0;
    }

    function claim_swapRouterAddress() external onlyMasterWallet {
        if (swapRouterAddress.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }
        swapRouterAddress.actual = swapRouterAddress.proposed;
    }

    function propose_poolFee(
        uint24 _proposed,
        uint256 _timeToClaim
    ) external onlyMasterWallet {
        poolFee.proposed = _proposed;
        poolFee.timeToClaim = block.timestamp + _timeToClaim;
    }

    function cancel_poolFee() external onlyMasterWallet {
        poolFee.proposed = poolFee.actual;
        poolFee.timeToClaim = 0;
    }

    function claim_poolFee() external onlyMasterWallet {
        if (poolFee.timeToClaim < block.timestamp) {
            revert NotTimeToClaimYet();
        }
        poolFee.actual = poolFee.proposed;
    }

    //●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●
    //getter functions
    //●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●○●

    function getOrders() external view returns (Order[] memory) {
        return orders;
    }

    function getSingleOrder(
        uint256 _orderID
    ) external view returns (Order memory) {
        return orders[_orderID];
    }

    function getStakingAddress()
        external
        view
        returns (AddressStructData memory)
    {
        return StakingAddress;
    }

    function getmUSDCAddress()
        external
        view
        returns (AddressStructData memory)
    {
        return mUSDCAddress;
    }

    function getUSDCAddress() external view returns (AddressStructData memory) {
        return USDCAddress;
    }

    function getMasterWallet()
        external
        view
        returns (AddressStructData memory)
    {
        return masterWallet;
    }

    function getSwapRouterAddress()
        external
        view
        returns (AddressStructData memory)
    {
        return swapRouterAddress;
    }

    function getPoolFee() external view returns (Uint24StructData memory) {
        return poolFee;
    }

    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    //Internal functions
    //▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△
    function _makeTriggerOrder(uint256 orderID) internal nonReentrant {
        /// @dev Check if the order is not expired
        if (orders[orderID].expirationTimestamp < block.timestamp) {
            orders[orderID].isActive = false;
            return;
        }
        /// @dev Check if the order is not already canceled
        if (!orders[orderID].isActive) {
            return;
        }

        ///@dev Check if the user has enough mUSDC
        if (
            IERC20(mUSDCAddress.actual).balanceOf(orders[orderID].userAddress) <
            orders[orderID].mUSDCAmount
        ) {
            orders[orderID].isActive = false;
            return;
        }

        Staking(StakingAddress.actual).burnAndTransferToTriggerSwaps(
            orders[orderID].userAddress,
            orders[orderID].mUSDCAmount
        );

        uint256 amountIn = swapExactOutputSingle(
            USDCAddress.actual,
            orders[orderID].tokenAddress_target,
            orders[orderID].mUSDCAmount,
            orders[orderID].targetPrice
        );

        if(!IERC20(orders[orderID].tokenAddress_target).transfer(
            orders[orderID].userAddress,
            amountIn
        )) {
            revert TransferFailed();
        }

        orders[orderID].isActive = false;
    }

    function swapExactOutputSingle(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _amountInMaximum
    ) internal returns (uint256 amountIn) {
        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            _amountInMaximum
        );

        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(
            _tokenIn,
            swapRouterAddress.actual,
            _amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee.actual,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: _amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = ISwapRouter(swapRouterAddress.actual).exactOutputSingle(
            params
        );

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < _amountInMaximum) {
            TransferHelper.safeApprove(_tokenIn, swapRouterAddress.actual, 0);
            TransferHelper.safeTransfer(
                _tokenIn,
                msg.sender,
                _amountInMaximum - amountIn
            );
        }
    }
}
