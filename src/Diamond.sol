// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./libraries/LibDiamondStorage.sol";

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

contract Diamond {

    constructor(address _owner, address _init, bytes memory _initCalldata) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        ds.owner = _owner;

        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_initCalldata);
            require(success, "Init failed");
        }
    }

    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        address facet = ds.facets[msg.sig];
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(msg.sender == ds.owner, "Must be owner");
        
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            IDiamondCut.FacetCut memory cut = _diamondCut[i];
            
            if (cut.action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(cut.facetAddress, cut.functionSelectors);
            } else if (cut.action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(cut.facetAddress, cut.functionSelectors);
            } else if (cut.action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(cut.facetAddress, cut.functionSelectors);
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_calldata);
            require(success, "DiamondCut: initialization failed");
        }
    }

    function addFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_facetAddress != address(0), "DiamondCut: facet address cannot be zero");
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(ds.facets[selector] == address(0), "DiamondCut: function already exists");
            ds.facets[selector] = _facetAddress;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_facetAddress != address(0), "DiamondCut: facet address cannot be zero");
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(ds.facets[selector] != address(0), "DiamondCut: function doesn't exist");
            ds.facets[selector] = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        require(_facetAddress == address(0), "DiamondCut: facet address must be zero");
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(ds.facets[selector] != address(0), "DiamondCut: function doesn't exist");
            delete ds.facets[selector];
        }
    }
}