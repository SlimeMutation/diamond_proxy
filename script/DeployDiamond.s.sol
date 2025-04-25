// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Diamond.sol";
import "../src/facets/TokenFacet.sol";
import "../src/libraries/LibDiamondStorage.sol";

contract DeployDiamond is Script {

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // 部署 TokenFacet
        TokenFacet tokenFacet = new TokenFacet();

        // 部署 Diamond
        Diamond diamond = new Diamond(
            payable(msg.sender),
            address(0),
            ''
        );

        console.log("Diamond deployed at:", address(diamond));
        console.log("TokenFacet deployed at:", address(tokenFacet));

        // 通过 DiamondCut 添加 TokenFacet
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TokenFacet.transfer.selector;
        selectors[1] = TokenFacet.balanceOf.selector;
        selectors[2] = TokenFacet.initToken.selector;

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(tokenFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cuts, address(tokenFacet), abi.encodeWithSignature("initToken(uint256)", 1000));

        vm.stopBroadcast();
    }
}
