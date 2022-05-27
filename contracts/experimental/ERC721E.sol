// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;

import "../../contracts/ERC721A.sol";


contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

abstract contract ERC721E is ERC721A, protected {
 
    struct OnChainMetadata {
        string SVG_Image; // Optional
        string Image_Uri; // Optional (has priority)
        string[] properties;
        mapping(string => string) attributes; // properties -> attributes
    }

    mapping(uint => OnChainMetadata) Token_Metadata; // tokenID -> metadata

    /*

    tokenURI can be set as https://apiurl.com/retrieve?nft=0xcontractaddress&id=tokenID

    The API will contain a web3 call with ERC721E abi contract and the below method
    returning ERC721 compatible json with imageURI being the url or the svg based on content

    */

    function setMetadata(string memory SVG_Image, string memory Image_Uri, string[] memory properties, string[] memory attributes) internal {
        uint _currentIndex = _totalMinted();
        Token_Metadata[_currentIndex].Image_Uri = Image_Uri;
        Token_Metadata[_currentIndex].SVG_Image = SVG_Image;
        Token_Metadata[_currentIndex].properties = properties;
        for (uint i; i < attributes.length; i++) {
            Token_Metadata[_currentIndex].attributes[properties[i]] = attributes[i];
        }
    }

    function retrieveMetadata(uint tokenID) public view returns(string memory SVG, string memory URI, string[] memory properties, string[] memory attributes) {
        string memory _svg = Token_Metadata[tokenID].SVG_Image;
        string memory _uri = Token_Metadata[tokenID].Image_Uri;
        string[] memory _properties = Token_Metadata[tokenID].properties;
        string[] memory _attributes;
        for(uint a; a < properties.length; a++) {
            _attributes[a] = (Token_Metadata[tokenID].attributes[properties[a]]);
        }
        return(_svg, _uri, _properties, _attributes);
    }

}