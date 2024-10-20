// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "@monedero/contracts/Staking.sol";


contract DeployProtocolScript is Script {
    Staking public staking;

    address masterWallet = 0xF11f8301C76F46733d855ac767BE741FFA9243Bd;
    uint256 apy = 250; // 2.5%
    address aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address USDCAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        staking = new Staking(
            masterWallet,
            apy,
            aavePool,
            USDCAddress
        );

        vm.stopBroadcast();
    }
}