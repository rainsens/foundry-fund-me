// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { FundMe } from "../src/FundMe.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

// Deploy method 1:
// Deploy with hardcoding the address of the price feed
// address in DeployFundMe.s.sol and FundMeTest.t.sol
//
// contract DeployFundMe {
//     function run() external {
//         vm.startBroadcast();
//         new FundMe();
//         vm.stopBroadcast();
//     }
// }



// Deploy method 2:
// Deploy without partly hardcoding the address of the price feed
// address only in DeployFundMe.s.sol
//
// contract DeployFundMe is Script {
//     function run() external returns (FundMe) {
//         vm.startBroadcast();
//         FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
//         vm.stopBroadcast();
//         return fundMe;
//     }
// }



// Deploy method 3:
// Deploy without hardcoding the address of the price feed
contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Anything before vm.startBroadcast() will not send a real transaction
        // it's a simulated envirnment, therefore, it can save gas cost.
        HelperConfig helperConfig = new HelperConfig();
        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // Anthying after vm.startBroadcast() will be a real transaction

        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}