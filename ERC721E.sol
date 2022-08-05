// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;


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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ModernTypes {
    // ANCHOR Uint to string conversion
    function UINT_TO_STRING(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}


contract ERC721E is protected, ModernTypes {

    /* ANCHOR Common properties */
    string public name;
    string public symbol;

     /* ANCHOR Events */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ANCHOR Safety */
    modifier Contract {
        require(msg.sender==address(this), "Only the contract can call this function");
        _;
    }

    /* ANCHOR Constructor */
    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    // SECTION Structures for on chain metadata

    struct ATTRIBUTE {
        string value_type;
        string value;
    }

    struct ATTRIBUTES {
        ATTRIBUTE[] attributes;
        mapping (string => uint) attributes_by_name;
        mapping (uint => string) attributes_by_index;
        uint attributes_head; // 0 is reserved
    }

    struct TOKEN {
        string description;
        string external_url;
        string image;
        string name;
        ATTRIBUTES attributes;
    }

    // !SECTION

    // SECTION Gas saving datatypes for iterable mappings and mapped arrays
    mapping(uint =>  TOKEN) tokens; // uint => token (tokenID)
    mapping(uint => address) token_owner; // uint => owner (owner of token ID)
    uint public tokens_head; // last unused tokenID
    mapping(address => uint[]) tokens_owned; // address => array of tokenIDs owned by address
    mapping(address => mapping(uint => uint)) tokens_index_in_owner; // address => tokenId => index in array of tokens_owned
    mapping(address => mapping(uint => bool)) public tokens_ownership; // holder -> tokenIDs (ownership)
    // !SECTION

    // SECTION On Chain Metadata Operations

    // SECTION Manipulate token metadata
    function _set_tokenMetadata(uint token, 
                                 string memory image,  
                                 string memory description, 
                                 string memory external_url, 
                                 string memory _name)
                                 public Contract{
        tokens[token].image = image;
        tokens[token].description = description;
        tokens[token].external_url = external_url;
        tokens[token].name = _name;
    }
    // !SECTION Manipulate token metadata

    // SECTION Setting attributes
    function _set_tokenAttributes(uint token, string[] memory types, string[] memory values)
                                  public Contract {
        require(types.length == values.length, "Types and values must be the same length");
        uint converted_index;
        for (uint i = 0; i < types.length; i++) {           
              // We can check if is already there
              if (tokens[token].attributes.attributes_by_name[types[i]] == 0) {
                // If not, we add it to the list
                converted_index = tokens[token].attributes.attributes_head;
                tokens[token].attributes.attributes_by_name[types[i]] = converted_index;
                tokens[token].attributes.attributes_by_index[converted_index] = types[i];
                tokens[token].attributes.attributes[converted_index].value_type = types[i];
                tokens[token].attributes.attributes[converted_index].value = values[i];
                // We also update the array to reflect attributes
                tokens[token].attributes.attributes[converted_index].value_type = types[i];
                tokens[token].attributes.attributes[converted_index].value = values[i];
                // And we update the head
                tokens[token].attributes.attributes_head = converted_index+1;
              } 
              else {
                    // If it is, we update it
                    converted_index = tokens[token].attributes.attributes_by_name[types[i]];
                    tokens[token].attributes.attributes[converted_index].value = values[i];
                    // And we update the array too
                    tokens[token].attributes.attributes[converted_index].value = values[i];
              }
        }
    }

    // !SECTION Setting attributes

    // SECTION Returns a token metadata
    // NOTE You can define tokenURI as a call to this function 
    function get_token(uint token)
                       public view returns(string memory metadata_json)  {
        string memory token_name = tokens[token].name;
        string memory token_description = tokens[token].description;
        string memory token_external_url = tokens[token].external_url;
        string memory token_image = tokens[token].image;
        // NOTE Getting attributes scanning the array by index
        string memory token_attributes = "";
        uint total_attributes = tokens[token].attributes.attributes_head;
        for (uint i = 0; i < total_attributes; i++) {
            token_attributes = string.concat(
                token_attributes,
                '{ "trait_type": "',
                tokens[token].attributes.attributes[i].value_type,
                '", "value": "',
                tokens[token].attributes.attributes[i].value,
                '" }',
                ','
            );
        }
        string[13] memory delimited;
        delimited = [
                        '{ "name": ', token_name,
                        ', "description": ', token_description,
                        ', "external_url": ', token_external_url,
                        ', "image": ', token_image,
                        ', "attributes": [',
                            token_attributes,
                            ' {"trait_type": "ID", "value": "', UINT_TO_STRING(token), '"}' // NOTE Avoid problems with commas too
                        '   ]'
                        ' }'
                    ];

        // ANCHOR Concatenating properties in a json
        string memory json;
        for (uint i = 0; i < delimited.length; i++) {
            json = string.concat(json, delimited[i]);
        }
       return json;
    }
    // !SECTION Returns a token metadata

    // !SECTION On Chain Metadata Operations

    /* ANCHOR ERC721 compliance */

    // SECTION Variables

    mapping(uint => address) _allowances; // tokenID => address (who is allowed to spend it)
    mapping(address => mapping(address => bool)) _operatorApprovals; // address => address (who is allowed to spend)
    // !SECTION Variables

    // SECTION ERC165 Logic 
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
    // !SECTION ERC165 Logic

    // NOTE Returns the total number of circulating tokens
    function totalSupply() public view returns (uint256) {
        return tokens_head;
    }

    // NOTE Returns the metadata-fetchable url for a given ID
    function tokenURI(uint256 tokenId) public view returns (string memory) {

    }

    // SECTION ERC721Enumerable Logic

    // NOTE Returns the ID of a token by index of owned tokens 
    // e.g. tokenIdByIndex(0) returns the ID of the first token owned by the caller
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view  
    returns (uint256 tokenId) {
        require(tokens_owned[_owner].length > 0, "No tokens owned");
        require(index < tokens_owned[_owner].length, "Index out of range");
        return tokens_owned[owner][index];
    }

    // NOTE Return a token ID if exists
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < tokens_head, "Index out of range");
        return index;    
    }

    // !SECTION ERC721Enumerable Logic

    // SECTION ERC721 Logic

    // NOTE Return the balance of a single address
    function balanceOf(address _owner) public view returns (uint256) {
         return tokens_owned[_owner].length;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return token_owner[tokenId];
    }

    // NOTE Approve spending of an ID to a single address
    function approve(address to, uint256 tokenId) public returns(bool) {
        address _owner = token_owner[tokenId];
        if (!isApprovedForAll(_owner, msg.sender)) {
            require(_owner == msg.sender, "Only the owner can approve");
        }
        require(!(to==msg.sender), "Cannot approve to yourself");
        _allowances[tokenId] = to;
        emit Approval(_owner, to, tokenId);
        return true;
    }

    // Get approved address for a given ID
    function getApproved(uint256 tokenId) public view  returns (address) {
        require(tokenId < tokens_head, "Token ID out of range");
        return _allowances[tokenId];
    }

    // NOTE Allows a single address to spend tokens on behalf of another address
    function setApprovalForAll(address operator, bool approved) public  {
        require(!(operator == msg.sender), "Cannot set approval to yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // NOTE Checks if an operator can act on behalf of an owner
    function isApprovedForAll(address _owner, address operator) 
                              public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    // NOTE Transfer a token or transfer on behalf of an address
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public  {
        // Safety checks
        require(tokenId < tokens_head, "Token does not exists");
        require(ownerOf(tokenId) == from, "Only the owner can transfer");
        require(to != address(0), "Cannot transfer to the null address");

        // Approvals check
        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));
        require(isApprovedOrOwner, "Only the owner or the approved address can transfer");

        // Delete token approvals from previous owner
        _allowances[tokenId] = address(0);

        // Assign the new ownership
        token_owner[tokenId] = to;
        tokens_ownership[to][tokenId] = true;
        // Deleting the old ownership by replacing it with the last one owned if any
        tokens_ownership[from][tokenId] = false;
        if(tokens_owned[from].length > 1) {
            uint index_in_owner = tokens_index_in_owner[from][tokenId];
            uint last_id_owned = tokens_owned[from][tokens_owned[from].length - 1];
            tokens_index_in_owner[from][last_id_owned] = index_in_owner;
            tokens_owned[from][index_in_owner] = last_id_owned;
            delete tokens_owned[from][tokens_owned[from].length - 1];
        } 
        // Otherwise it just delete the only owned one
        else {
            delete tokens_index_in_owner[from][0];
        }

        emit Transfer(from, to, tokenId);
    }

    // NOTE Enable transfers to be checked against unreceivable contracts
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            require (reason.length != 0, "ERC721Receiver not found");

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // NOTE Empowers the previous method to enable safeTransfers (if anyone uses them)
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        safeTransferFrom(from, to, id, '');
    }

    // NOTE Overloaded: empowers the previous method to enable safeTransfers (if anyone uses them)
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public {
        transferFrom(from, to, id);

        require (_checkOnERC721Received(from, to, id, data), "Transfer failed on ERC721Receiver");
    }

    // !SECTION ERC721 Logic

    // SECTION Minting logic

    // NOTE Empowers safety checks for minting (only once to save gas)
    function safeMint(address to, uint256 qty) public  {
        safeMint(to, qty, '');
    }

    // NOTE Overloaded: empowers safety checks for minting (only once to save gas)
    function safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) public  {
        _mint(to, qty);

        require(_checkOnERC721Received(address(0), to, tokens_head, data), "Mint failed on ERC721Receiver");
    }

    function _mint(address to, uint256 qty) internal  {
        require (to != address(0), "Cannot mint to the null address");
        require (qty != 0, "Cannot mint 0 tokens");

        uint256 _currentIndex = tokens_head; // Reminder: tokens_head is the last UNUSED tokenID

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty - 1; i++) {
                // Assign the ownership
                token_owner[_currentIndex + i] = to; // +0, +1, +2, +3, ...
                // Insert the current token into the owner's array
                tokens_owned[to].push(_currentIndex + i);
                // Set the position of the current token in the owner array
                tokens_index_in_owner[to][_currentIndex + i] = tokens_owned[to].length - 1;
                // Set ownership to true for further checks
                tokens_ownership[to][_currentIndex + i] = true;
                // Event emission
                emit Transfer(address(0), to, _currentIndex + i);
            }
            // Plain increasing of total tokens
            tokens_head += qty;
        }

    }

    // !SECTION Minting Logic

}