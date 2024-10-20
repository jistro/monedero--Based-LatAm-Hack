// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
    $$\                  $$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$\  
 $$$$$$\                $$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\ 
$$  __$$\ $$$$$$\$$$$\  $$ |  $$ |$$ /  \__|$$ |  $$ |$$ /  \__|
$$ /  \__|$$  _$$  _$$\ $$ |  $$ |\$$$$$$\  $$ |  $$ |$$ |      
\$$$$$$\  $$ / $$ / $$ |$$ |  $$ | \____$$\ $$ |  $$ |$$ |      
 \___ $$\ $$ | $$ | $$ |$$ |  $$ |$$\   $$ |$$ |  $$ |$$ |  $$\ 
$$\  \$$ |$$ | $$ | $$ |\$$$$$$  |\$$$$$$  |$$$$$$$  |\$$$$$$  |
\$$$$$$  |\__| \__| \__| \______/  \______/ \_______/  \______/ 
 \_$$  _/                                                       
   \ _/                                                         

 * @title mUSDC
 * @author jistro.eth & Ariutokintumi.eth
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mUSDC is ERC20 {
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //variables
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    error Unauthorized();
    error NotEnoughBalance();
    /**
     * @dev Allows storing role information within the contract.
     * @param actual Address of the current role.
     * @param proposed Address of the proposed role.
     * @param timeToClaim Time when the proposed role can be claimed.
     */
    struct RoleTypeData {
        address actual;
        address proposed;
        uint256 timeToClaim;
    }
    /**
     * @dev Stores user information for yield calculation.
     * @param lastUpdateTimestamp Last time the yield was updated.
     * @param lastAPY User's yield.
     */
    struct UserData {
        uint256 lastUpdateTimestamp;
        uint256 lastAPY;
    }

    RoleTypeData private stakingContract;
    RoleTypeData private administrator;
    RoleTypeData public mUSDCAddress;
    RoleTypeData public masterWallet; 
    RoleTypeData public manualAPY;
    mapping(address => UserData) private userData;
    address[] public whitelistedAddresses;

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //Modifiers
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    modifier onlyStakingContract() {
        if (msg.sender != stakingContract.actual) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyAdministrator() {
        if (msg.sender != administrator.actual) {
            revert Unauthorized();
        }
        _;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //Constructor
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    constructor(
        address _stakingContract,
        address _administrator
    ) ERC20("Monedero USDC", "mUSDC") {
        stakingContract.actual = _stakingContract;
        administrator.actual = _administrator;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //External functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    
    //•••••••••••••••••••••••••••••••••
    //ERC20 functions
    //•••••••••••••••••••••••••••••••••
    /**
     * @dev This function allows Staking.sol to mint mUSDC tokens
     *      and at the same time update the user's yield (if has
     *     any balance).
     * @param to the address to mint the tokens
     * @param amount the amount of tokens to mint
     * @param newAPY the new APY for the user
     */
    function mint(
        address to,
        uint256 amount,
        uint256 newAPY
    ) external onlyStakingContract {
        _hookUpdateYield(to);

        _mint(to, amount);

        userData[to] = UserData({
            lastUpdateTimestamp: block.timestamp,
            lastAPY: newAPY
        });
    }

    /**
     * @dev This function allows Staking.sol to burn mUSDC tokens
     *      and at the same time update the user's yield (if has
     *     any balance).
     * @param from the address to burn the tokens
     * @param amount the amount of tokens to burn
     * @param newAPY the new APY for the user
     */
    function burn(
        address from,
        uint256 amount,
        uint256 newAPY
    ) external onlyStakingContract {
        _hookUpdateYield(from);

        _burn(from, amount);

        if (balanceOf(from) == 0) {
            delete userData[from];
        } else {
            userData[from] = UserData({
                lastUpdateTimestamp: block.timestamp,
                lastAPY: newAPY
            });
        }
    }

    /**
     * @dev This function allows users to transfer mUSDC tokens
     *      and at the same time update the yield for both
     *      the sender and the receiver.
     * @param to the address to transfer the tokens
     * @param value the amount of tokens to transfer
     */
    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address owner = _msgSender();
        _hookTransferYieldUpdate(owner, to);
        _transfer(owner, to, value);
        return true;
    }

    //•••••••••••••••••••••••••••••••••
    //Admin functions
    //•••••••••••••••••••••••••••••••••

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


    function proposeNewStakingContractAddress(
        address _newAddress
    ) external onlyAdministrator {
        stakingContract.proposed = _newAddress;
        stakingContract.timeToClaim = block.timestamp + 1 days;
    }

    function cancelNewStakingContractAddress() external onlyAdministrator {
        stakingContract.proposed = address(0);
        stakingContract.timeToClaim = 0;
    }

    function claimNewStakingContractAddress() external onlyAdministrator {
        if (block.timestamp > stakingContract.timeToClaim) {
            stakingContract = RoleTypeData({
                actual: stakingContract.proposed,
                proposed: address(0),
                timeToClaim: 0
            });
        }
    }

    function proposeNewAdministratorAddress(
        address _newAddress
    ) external onlyAdministrator {
        administrator.proposed = _newAddress;
        administrator.timeToClaim = block.timestamp + 1 days;
    }

    function cancelNewAdministratorAddress() external onlyAdministrator {
        administrator.proposed = address(0);
        administrator.timeToClaim = 0;
    }

    function claimNewAdministratorAddress() external {
        if (
            block.timestamp > administrator.timeToClaim &&
            msg.sender == administrator.proposed
        ) {
            administrator = RoleTypeData({
                actual: administrator.proposed,
                proposed: address(0),
                timeToClaim: 0
            });
        }
    }

    //•••••••••••••••••••••••••••••••••
    //Getters
    //•••••••••••••••••••••••••••••••••

    function getUserData(address _user)
        external
        view
        returns (UserData memory)
    {
        return userData[_user];
    }

    function getStakingContractAddress() external view returns (address) {
        return stakingContract.actual;
    }

    function getAdministratorAddress() external view returns (address) {
        return administrator.actual;
    }

    function getRoleProposedAdministrator() external view returns (address) {
        return administrator.proposed;
    }

    function getRoleProposedStakingContract() external view returns (address) {
        return stakingContract.proposed;
    }

    function getRoleProposedTimeToClaimAdministrator() external view returns (uint256) {
        return administrator.timeToClaim;
    }

    function getRoleProposedTimeToClaimStakingContract() external view returns (uint256) {
        return stakingContract.timeToClaim;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //Public functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //Internal functions
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    function _hookUpdateYield(address _user) internal {
        // Verificar si la dirección tiene saldo
        uint256 balance = balanceOf(_user);
        if (balance == 0) {
            return;
        }
        // Calcular el tiempo transcurrido desde la última actualización
        uint256 timeElapsed = block.timestamp -
            userData[_user].lastUpdateTimestamp;

        // Calcular el rendimiento
        uint256 yield = (balance * userData[_user].lastAPY * timeElapsed) /
            (365 days * 1000000);  // Cambia 10000 por 1000000

        // Mintear el rendimiento calculado
        if (yield > 0) {
            _mint(_user, yield);
        }
    }

    function _hookTransferYieldUpdate(address _from, address _to) internal {
        _hookUpdateYield(_from);
        _hookUpdateYield(_to);
    }

    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //ERC20 functions not implemented (overrides)
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    function approve(address spender, uint256 value) public override returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        return false;
    }

}
