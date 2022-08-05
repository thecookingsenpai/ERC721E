# ERC721E

## Another low gas ERC721 implementation

### But this time with on-chain metadata

ERC721A was cheap on gas.
ERC721B was even cheaper and smarter.
ERC721E is cheaper, smarter and fully on-chain.

#### Why is cheaper?

Because minting, enumerating and many other features are implemented using efficient types and ignoring the usual practices, especially regarding enumeration of owned tokens and enumeration of token ids.

#### Why metadata on chain?

Because IPFS isn't that much decentralized and your NFTs could easily disappear (actually they does usually after a while) if the metadata isn't pinned or the gateway is not available.

With on chain metadata, you can be sure that the metadata is always available.

#### But images can't be on chain!

Well, probably is better to store images externally (which by the way does not damage your metadata as it can be updated easily if the image is gone).

Anyway, you could even store SVG textual data into the image url and have them on chain too.

#### Is this compatible with Opensea?

Yes of couse.

#### How to use?

Import the contract in your contract and write something to call _mint (as it is internal by default) with your own rules.

Example:

```
import './ERC721E.sol'

contract MyNFT is ERC721E {

    [YOU MIGHT WANT TO SET NAME AND SYMBOL HERE]
    name = "My NFT";
    symbol = "MNFT";

    constructor() {
        [...]
    }

    mint(uint qty) payable public {
        [YOUR RULES]
        _mint(msg.sender, qty);
    }

    [YOUR OTHER STUFF]

}
```

### Credits

https://github.com/chiru-labs/ERC721A for the original inspiration

https://github.com/beskay/ERC721B for further inspiration

https://stackoverflow.com for the multiple inputs especially on types conversion