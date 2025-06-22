// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNFT is ERC721 {
    error BasicNft_TokenUriNotFound();
    uint256 private s_tokenCounter;
    mapping(uint256 tokenId => string tokenUri) private s_tokenIdToUri;

    constructor() ERC721("Dogie", "DOG"){
        s_tokenCounter = 0;
    }

    function mint (string memory _tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = _tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function tokenURI (uint256 _tokenId) public view override returns(string memory){
        if (ownerOf(_tokenId) == address(0)){
            revert BasicNft_TokenUriNotFound();
        }
        return s_tokenIdToUri[_tokenId];
    }

    function getTokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }
}