// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "@monedero/contracts/Staking.sol";


contract DeployProtocolScript is Script {
    Staking public staking;

    struct DeclarationsMethod {
        address masterWallet;
        uint256 apy;
        address aavePool;
        address USDCAddress;
        address swapRouterAddress;
    }

    DeclarationsMethod declarationsMethodEthSepolia =
        DeclarationsMethod({
            masterWallet: 0xF11f8301C76F46733d855ac767BE741FFA9243Bd,
            apy: 250,
            aavePool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,
            USDCAddress: 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8,
            swapRouterAddress: 0xE592427A0AEce92De3Edee1F18E0157C05861564
        });

    DeclarationsMethod declarationsMethodBaseTest =
        DeclarationsMethod({
            masterWallet: 0xF11f8301C76F46733d855ac767BE741FFA9243Bd,
            apy: 250,
            aavePool: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b,
            USDCAddress: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
            swapRouterAddress: 0x2626664c2603336E57B271c5C0b26F421741e481
        });

    address masterWallet = 0xF11f8301C76F46733d855ac767BE741FFA9243Bd;
    uint256 apy = 250; // 2.5%
    address aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address USDCAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        staking = new Staking(
            declarationsMethodBaseTest.masterWallet,
            declarationsMethodBaseTest.apy,
            declarationsMethodBaseTest.aavePool,
            declarationsMethodBaseTest.USDCAddress,
            declarationsMethodBaseTest.swapRouterAddress
        );

        vm.stopBroadcast();
    }
}