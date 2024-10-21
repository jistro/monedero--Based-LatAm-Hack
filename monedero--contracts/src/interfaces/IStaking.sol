// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    // External functions
    function stkingUSDC(uint256 _amount) external returns (bool);
    function unstakingNowUSDC(uint256 _amount) external returns (bool);
    function unstaking24HoursUSDC(uint256 _amount) external returns (bool);
    function processUnstaking24Hours() external returns (bool);

    // View functions
    function getApy() external view returns (uint256);
    function getAavePool() external view returns (address);
    function getmUSDCAddress() external view returns (address);
    function getUSDCAddress() external view returns (address);
    function getMasterWallet() external view returns (address);
    function getPendingUnstaking24Hours(address _user) external view returns (uint256);
    function getListPendingUnstaking24Hours() external view returns (address[] memory);
    function getUnstaking24HoursAdminList(address _admin) external view returns (bool);
    function getLastUnstakingProcessTime() external view returns (uint256);
    function getProposedApy() external view returns (uint256);
    function getProposedAavePool() external view returns (address);
    function getProposedmUSDCAddress() external view returns (address);
    function getProposedUSDCAddress() external view returns (address);
    function getProposedMasterWallet() external view returns (address);
    function getProposedTimeToClaimApy() external view returns (uint256);
    function getProposedTimeToClaimAavePool() external view returns (uint256);
    function getProposedTimeToClaimmUSDCAddress() external view returns (uint256);
    function getProposedTimeToClaimUSDCAddress() external view returns (uint256);
    function getProposedTimeToClaimMasterWallet() external view returns (uint256);
}
