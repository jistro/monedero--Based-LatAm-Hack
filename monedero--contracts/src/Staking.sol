// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗ 
██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝ 
███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗
╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║
███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 

 * @title mUSDC
 * @author jistro.eth & Ariutokintumi.eth
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {mUSDC} from "@monedero/contracts/mUSDC.sol";
import {TriggeredSwaps} from "@monedero/contracts/TriggeredSwaps.sol";
import {Pool} from "@aave-dao/aave-v3-origin/contracts/protocol/pool/Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    //variables
    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    error Unauthorized();
    error NotEnoughAllowance();
    error NotEnoughBalance();
    error TransferFailed();
    error ApproveFailed();

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
    struct UintStructData {
        uint256 actual;
        uint256 proposed;
        uint256 timeToClaim;
    }

    ///@dev apy has 2 decimals
    UintStructData private apy;
    AddressStructData private aavePool;
    AddressStructData private mUSDCAddress;
    AddressStructData private USDCAddress;
    AddressStructData private masterWallet;
    AddressStructData private triggerSwaps;

    uint256 private lastUnstakingProcessTime;

    mapping(address => uint256) private pendingUnstaking24Hours;

    address[] private listPendingUnstaking24Hours;

    mapping(address => bool) private Unstaking24HoursAdminList;

    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    //Modifiers
    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄

    modifier onlyMasterWallet() {
        if (msg.sender != masterWallet.actual) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyUnstaking24HoursAdmin() {
        if (!Unstaking24HoursAdminList[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyTriggerSwaps() {
        if (msg.sender != triggerSwaps.actual) {
            revert Unauthorized();
        }
        _;
    }

    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    //Constructor
    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    constructor(
        address _masterWallet,
        uint256 _apy,
        address _aavePool,
        address _USDCAddress,
        address _swapRouterAddress
    ) {
        triggerSwaps.actual = address(
            new TriggeredSwaps(_masterWallet, address(this), _swapRouterAddress)
        );
        mUSDCAddress.actual = address(
            new mUSDC(address(this), _masterWallet, triggerSwaps.actual)
        );
        TriggeredSwaps(triggerSwaps.actual).constructorTokens(
            mUSDCAddress.actual,
            _USDCAddress
        );
        //se infinite allowance a aavePool and triggerSwaps
        if (!IERC20(_USDCAddress).approve(_aavePool, type(uint256).max)){
            revert ApproveFailed();
        }
        if(!IERC20(_USDCAddress).approve(triggerSwaps.actual, type(uint256).max)){
            revert ApproveFailed();
        }
        masterWallet.actual = _masterWallet;
        apy.actual = _apy;
        aavePool.actual = _aavePool;
        USDCAddress.actual = _USDCAddress;
        lastUnstakingProcessTime = block.timestamp;
    }

    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
    //External functions
    //▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄

    /**
     * @notice This function allows the user to stake USDC and mint mUSDC.
     * @param _amount Amount of USDC to stake.
     * @return bool Returns true if the operation was successful.
     */
    function stakingUSDC(uint256 _amount) external nonReentrant returns (bool) {
        if (
            IERC20(USDCAddress.actual).allowance(msg.sender, address(this)) <
            _amount
        ) {
            revert NotEnoughAllowance();
        }
        // staking logic
        if (
            !IERC20(USDCAddress.actual).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        ) {
            revert TransferFailed();
        }

        Pool(aavePool.actual).supply(
            USDCAddress.actual,
            _amount,
            address(this),
            0
        );

        mUSDC(mUSDCAddress.actual).mint(msg.sender, _amount, apy.actual);

        return true;
    }

    /**
     * @notice This function allows the user to unstake USDC and burn mUSDC
     *         inmediatly.
     * @param _amount Amount of USDC to unstake.
     * @return bool Returns true if the operation was successful.
     */
    function unstakingNowUSDC(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        if (mUSDC(mUSDCAddress.actual).balanceOf(msg.sender) < _amount) {
            revert NotEnoughBalance();
        }
        mUSDC(mUSDCAddress.actual).burn(msg.sender, _amount, apy.actual);

        Pool(aavePool.actual).withdraw(
            USDCAddress.actual,
            _amount,
            address(this)
        );

        if(!IERC20(USDCAddress.actual).transfer(msg.sender, _amount)){
            revert TransferFailed();
        }

        return true;
    }

    /**
     * @notice This function allows the user to unstake USDC and burn mUSDC
     *         in a gas friendly way, but the user will have to wait 24 hours
     *         to be processed.
     * @param _amount Amount of USDC to unstake.
     * @return bool Returns true if the operation was successful.
     */
    function unstaking24HoursUSDC(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        if (mUSDC(mUSDCAddress.actual).balanceOf(msg.sender) < _amount) {
            revert NotEnoughBalance();
        }

        listPendingUnstaking24Hours.push(msg.sender);
        pendingUnstaking24Hours[msg.sender] = _amount;

        return true;
    }

    /**
     * @notice This function allows the admin to process all the unstaking
     *         requests that have been waiting for 24 hours.
     * @notice Only administators of this function can call it.
     * @return bool Returns true if the operation was successful.
     */
    function processUnstaking24Hours()
        external
        nonReentrant
        onlyUnstaking24HoursAdmin
        returns (bool)
    {
        //verifica si ya paso 24 horas desde el ultimo proceso
        if (block.timestamp - lastUnstakingProcessTime < 1 days) {
            return false;
        }

        for (uint256 i = 0; i < listPendingUnstaking24Hours.length; i++) {
            address user = listPendingUnstaking24Hours[i];
            uint256 amount = pendingUnstaking24Hours[user];

            mUSDC(mUSDCAddress.actual).burn(user, amount, apy.actual);

            Pool(aavePool.actual).withdraw(
                USDCAddress.actual,
                amount,
                address(this)
            );

            if (!IERC20(USDCAddress.actual).transfer(user, amount)) {
                revert TransferFailed();
            }

            delete pendingUnstaking24Hours[user];
        }

        delete listPendingUnstaking24Hours;

        lastUnstakingProcessTime = block.timestamp;

        return true;
    }

    function burnAndTransferToTriggerSwaps(
        address _user,
        uint256 _amount
    ) external onlyTriggerSwaps nonReentrant {
        mUSDC(mUSDCAddress.actual).burn(_user, _amount, apy.actual);
        Pool(aavePool.actual).withdraw(
            USDCAddress.actual,
            _amount,
            address(this)
        );
        if(!IERC20(USDCAddress.actual).transfer(triggerSwaps.actual, _amount)){
            revert TransferFailed();
        }
    }

    //•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙
    //Admin functions
    //•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙

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

    function propose_MasterWallet(address _proposed) external onlyMasterWallet {
        masterWallet.proposed = _proposed;
        masterWallet.timeToClaim = block.timestamp + 1 days;
    }

    function cancel_ProposeMasterWallet() external onlyMasterWallet {
        masterWallet.proposed = address(0);
        masterWallet.timeToClaim = 0;
    }

    function claim_MasterWallet() external {
        if (masterWallet.timeToClaim < block.timestamp) {
            revert Unauthorized();
        }

        masterWallet.actual = masterWallet.proposed;
        masterWallet.proposed = address(0);
        masterWallet.timeToClaim = 0;
    }

    function propose_Apy(uint256 _proposed) external onlyMasterWallet {
        apy.proposed = _proposed;
        apy.timeToClaim = block.timestamp + 1 days;
    }

    function cancel_ProposeApy() external onlyMasterWallet {
        apy.proposed = 0;
        apy.timeToClaim = 0;
    }

    function claim_Apy() external onlyMasterWallet {
        if (apy.timeToClaim < block.timestamp) {
            revert Unauthorized();
        }

        apy.actual = apy.proposed;
        apy.proposed = 0;
        apy.timeToClaim = 0;
    }

    function propose_AavePool(address _proposed) external onlyMasterWallet {
        aavePool.proposed = _proposed;
        aavePool.timeToClaim = block.timestamp + 1 days;
    }

    function cancel_ProposeAavePool() external onlyMasterWallet {
        aavePool.proposed = address(0);
        aavePool.timeToClaim = 0;
    }

    function claim_AavePool() external onlyMasterWallet {
        if (aavePool.timeToClaim < block.timestamp) {
            revert Unauthorized();
        }

        aavePool.actual = aavePool.proposed;
        aavePool.proposed = address(0);
        aavePool.timeToClaim = 0;
    }

    function propose_mUSDCAddress(address _proposed) external onlyMasterWallet {
        mUSDCAddress.proposed = _proposed;
        mUSDCAddress.timeToClaim = block.timestamp + 1 days;
    }

    function cancelPropose_mUSDCAddress() external onlyMasterWallet {
        mUSDCAddress.proposed = address(0);
        mUSDCAddress.timeToClaim = 0;
    }

    function claim_mUSDCAddress() external onlyMasterWallet {
        if (mUSDCAddress.timeToClaim < block.timestamp) {
            revert Unauthorized();
        }

        IERC20(mUSDCAddress.actual).approve(mUSDCAddress.actual, 0);
        IERC20(mUSDCAddress.actual).approve(mUSDCAddress.actual, 0);
        IERC20(mUSDCAddress.actual).approve(
            mUSDCAddress.proposed,
            type(uint256).max
        );
        IERC20(mUSDCAddress.actual).approve(
            mUSDCAddress.proposed,
            type(uint256).max
        );

        mUSDCAddress.actual = mUSDCAddress.proposed;
        mUSDCAddress.proposed = address(0);
        mUSDCAddress.timeToClaim = 0;
    }

    function propose_USDCAddress(address _proposed) external onlyMasterWallet {
        USDCAddress.proposed = _proposed;
        USDCAddress.timeToClaim = block.timestamp + 1 days;
    }

    function cancel_ProposeUSDCAddress() external onlyMasterWallet {
        USDCAddress.proposed = address(0);
        USDCAddress.timeToClaim = 0;
    }

    function claim_USDCAddress() external onlyMasterWallet {
        if (USDCAddress.timeToClaim < block.timestamp) {
            revert Unauthorized();
        }

        USDCAddress.actual = USDCAddress.proposed;
        USDCAddress.proposed = address(0);
        USDCAddress.timeToClaim = 0;
    }

    function add_Unstaking24HoursAdmin(
        address _proposed
    ) external onlyMasterWallet {
        Unstaking24HoursAdminList[_proposed] = true;
    }

    function remove_ProposeUnstaking24HoursAdmin(
        address _proposed
    ) external onlyMasterWallet {
        Unstaking24HoursAdminList[_proposed] = false;
    }

    //•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙
    //Getters
    //•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙•⋅∙

    function getApy() external view returns (uint256) {
        return apy.actual;
    }

    function getAavePool() external view returns (address) {
        return aavePool.actual;
    }

    function getmUSDCAddress() external view returns (address) {
        return mUSDCAddress.actual;
    }

    function getUSDCAddress() external view returns (address) {
        return USDCAddress.actual;
    }

    function getMasterWallet() external view returns (address) {
        return masterWallet.actual;
    }

    function getPendingUnstaking24Hours(
        address _user
    ) external view returns (uint256) {
        return pendingUnstaking24Hours[_user];
    }

    function getListPendingUnstaking24Hours()
        external
        view
        returns (address[] memory)
    {
        return listPendingUnstaking24Hours;
    }

    function getUnstaking24HoursAdminList(
        address _admin
    ) external view returns (bool) {
        return Unstaking24HoursAdminList[_admin];
    }

    function getLastUnstakingProcessTime() external view returns (uint256) {
        return lastUnstakingProcessTime;
    }

    function getProposedApy() external view returns (uint256) {
        return apy.proposed;
    }

    function getProposedAavePool() external view returns (address) {
        return aavePool.proposed;
    }

    function getProposedmUSDCAddress() external view returns (address) {
        return mUSDCAddress.proposed;
    }

    function getProposedUSDCAddress() external view returns (address) {
        return USDCAddress.proposed;
    }

    function getProposedMasterWallet() external view returns (address) {
        return masterWallet.proposed;
    }

    function getProposedTimeToClaimApy() external view returns (uint256) {
        return apy.timeToClaim;
    }

    function getProposedTimeToClaimAavePool() external view returns (uint256) {
        return aavePool.timeToClaim;
    }

    function getProposedTimeToClaimmUSDCAddress()
        external
        view
        returns (uint256)
    {
        return mUSDCAddress.timeToClaim;
    }

    function getProposedTimeToClaimUSDCAddress()
        external
        view
        returns (uint256)
    {
        return USDCAddress.timeToClaim;
    }

    function getProposedTimeToClaimMasterWallet()
        external
        view
        returns (uint256)
    {
        return masterWallet.timeToClaim;
    }
}
