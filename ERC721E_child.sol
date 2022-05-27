// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;

import "./contracts/experimental/ERC721E.sol";


contract Azuki is ERC721E {

  string baseURI;
  constructor() ERC721A("ComplETH Collection", "COMPLETH") {}

  function _setBaseURI(string memory newURI) public onlyAuth {
      baseURI = newURI;
  }

  function _baseURI() internal view override returns (string memory) {
        return baseURI;
   }

  function mint(uint256 quantity) external payable {
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }
}