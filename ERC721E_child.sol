// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;

import "./contracts/experimental/ERC721E.sol";

abstract contract ComplETH_Pieces is ERC721E {

  struct PUZZLE {
    uint[] token_ids_included;
    mapping(uint => bool) is_id_included;
    string url;
    string base_url_pieces;
  }

  mapping(uint => PUZZLE) public puzzles;
  uint public last_puzzle;

  /// @dev Retrieve a puzzle status for an address
  function has_puzzle_pieces(uint puzzle_id) public view returns (bool completed) {
    bool all = true;
    // Iterate over the puzzle pieces and to save gas return on the first not owned piece
    for(uint i = 0; i < puzzles[puzzle_id].token_ids_included.length; i++) {
      if(!(ownerOf(puzzles[puzzle_id].token_ids_included[i])==msg.sender)) {
        all = false;
        return all;
      }
    }
    return all;
  }

  /// @dev Setting a new puzzle
  function new_puzzle(uint[] memory ids, string memory url, string memory url_pieces) public onlyAuth {
    puzzles[last_puzzle].token_ids_included = ids;
    // Register the mapping for easy access
    for(uint i = 0; i < ids.length; i++) {
      puzzles[last_puzzle].is_id_included[ids[i]] = true;
    }
    // Setting urls
    puzzles[last_puzzle].url = url;
    puzzles[last_puzzle].base_url_pieces = url_pieces;
  }

}

contract ComplETH is ComplETH_Pieces {

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