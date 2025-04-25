// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/facets/TokenFacetV2.sol";
import "../src/libraries/LibDiamondStorage.sol";

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

contract UpgradeDiamond is Script {

    address constant DIAMOND_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        TokenFacetV2 tokenFacetV2 = new TokenFacetV2();
        
        // 替换现有函数
        bytes4[] memory existingSelectors = new bytes4[](2);
        existingSelectors[0] = TokenFacetV2.transfer.selector;
        existingSelectors[1] = TokenFacetV2.balanceOf.selector;

        // 添加新函数
        bytes4[] memory newSelectors = new bytes4[](1);
        newSelectors[0] = TokenFacetV2.burn.selector;

        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](2);
        
        // 替换现有函数
        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(tokenFacetV2),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: existingSelectors
        });

        // 添加新函数
        facetCuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(tokenFacetV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: newSelectors
        });

        IDiamondCut(DIAMOND_ADDRESS).diamondCut(facetCuts, address(0), "");

        console.log("TokenFacetV2 deployed at:", address(tokenFacetV2));
        vm.stopBroadcast();
    }
}
