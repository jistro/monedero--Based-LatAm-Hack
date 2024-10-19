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
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    //Error Handling
    //▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
    error Unauthorized();
    error NotEnoughBalance();
    /**
     * @dev Permite almacenar la información de los roles 
     *      dentro del contrato.
     * @param actual Dirección del rol actual.
     * @param proposed Dirección del rol propuesto.
     * @param timeToClaim Tiempo en el que se puede reclamar 
     *                      el rol propuesto.
     */
    struct RoleTypeData {
        address actual;
        address proposed;
        uint256 timeToClaim;
    }
    /**
     * @dev Permite almacenar la información de los usuarios para
     *      el cálculo de rendimientos.
     * @param lastUpdateTimestamp Última vez que se actualizó el rendimiento.
     * @param lastAPY Rendimiento del usuario.
     */
    struct UserData {
        uint256 lastUpdateTimestamp;
        uint256 lastAPY;
    }

    RoleTypeData private stakingContract;
    RoleTypeData private administrator;
    mapping(address => UserData) private userData;

    constructor(
        address _stakingContract,
        address _administrator
    ) ERC20("Monedero USDC", "mUSDC") {
        stakingContract.actual = _stakingContract;
        administrator.actual = _administrator;
    }

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

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address owner = _msgSender();
        _hookTransferYieldUpdate(owner, to);
        _transfer(owner, to, value);
        return true;
    }

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
            (365 days * 10000);

        // Mintear el rendimiento calculado
        if (yield > 0) {
            _mint(_user, yield);
        }
    }

    function _hookTransferYieldUpdate(address _from, address _to) internal {
        _hookUpdateYield(_from);
        _hookUpdateYield(_to);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

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

    function approve(address spender, uint256 value) public override returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        return false;
    }
}
