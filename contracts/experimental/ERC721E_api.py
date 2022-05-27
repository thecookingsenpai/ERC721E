import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from web3 import Web3

provider_url = "https://speedy-nodes-nyc.moralis.io/531d9b8c155df8f63b358a83/eth/mainnet"

w3 = Web3(Web3.HTTPProvider(provider_url))

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.get("/retrieve")
async def retrieve_nft(nft, id):
    # Initializing contract
    ca = ""
    with open("ERC721E.abi", "r") as abi_file:
        Abi = abi_file.read()
    contract = w3.eth.contract(address = ca, abi = Abi)
    # Getting properties
    IMAGE_URI = ""
    SVG_IMAGE = ""
    PROPERTIES = []
    ATTRIBUTES = []
    IMAGE_URI, SVG_IMAGE, PROPERTIES, ATTRIBUTES = contract.functions.retrieveMetadata(id).call()
    NAME = contract.functions.name().call()
    # Building attributes dictionary
    ATTRIBUTES_DICT = {}
    counter = 0
    for property in PROPERTIES:
        ATTRIBUTES_DICT[property] = ATTRIBUTES[counter]
        counter += 1
    # Deciding image
    if not IMAGE_URI == "":
        FINAL_IMAGE = IMAGE_URI
    else:
        FINAL_IMAGE = SVG_IMAGE
    # Building metadata
    METADATA = {
                "description": NAME + " NFT Contract", 
                "external_url": "", 
                "image": FINAL_IMAGE, 
                "name": NAME,
                "attributes": ATTRIBUTES_DICT, 
                }
    # Returning a ERC721 compliant JSON
    return METADATA
