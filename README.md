# ERC721E
## An ERC721A Extension
### Which is an ERC721 Extension
#### ERC721A is coded by https://github.com/chiru-labs/ERC721A
#### ERC721E is coded by thecookingsenpai (aka drotodev aka tcsenpai aka drotosclerosi)

#### What is ERC721E
ERC721E is first of all a fork of ERC721A used by the Azuki Team and coded as described above.
For this reason, ERC721E retain the extreme gas efficiency of ERC721A while adding some new functions.

#### On Chain Metadata
As NFTs are meant to be on-chain and decentralized, ERC721E provides an optional way to store metadata
on-chain instead of using IPFS and without relying on chains like arweave.
This is done by creating a struct that is publicy accessible, mimicking NFT metadata json structure and
being mappable to token IDs.
This struct is capable of containing just metadata but also a SVG image, always optionally. Theoretically, so, is
possible to store the whole NFT collection on chain.
This is done to improve decentralization and data stability as IPFS is really an unelegant solution.