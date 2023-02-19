// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {RedirectAll, ISuperToken, ISuperfluid, IConstantFlowAgreementV1} from "./RedirectAll.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "./libraries/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

/// @title Tradeable Cashflow NFT
/// @notice Inherits the ERC721 NFT interface from Open Zeppelin and the RedirectAll logic to
/// redirect all incoming streams to the current NFT holder.
contract TradeableCashflow1 is ERC721URIStorage, RedirectAll {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string baseSvg =
        "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    event NewNFTMinted(address sender, uint256 tokenId);

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken
    ) ERC721("ETHforAll", "EFA") RedirectAll(acceptedToken, host, cfa) {
        console.log(
            "This line should be printed when the contract is deployed"
        );
    }

    // ---------------------------------------------------------------------------------------------
    // BEFORE TOKEN TRANSFER CALLBACK

    /// @dev Before transferring the NFT, set the token receiver to be the stream receiver as
    /// defined in `RedirectAll`.
    /// @param to New receiver.
    function _beforeTokenTransfer(
        address from, // from
        address to,
        uint256 tokenId, // tokenId
        uint256 //open zeppelin's batchSize param
    ) internal override {
        _changeReceiver(to, tokenId);
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mintNFT(string memory _name, string memory _description) public {
        uint256 newItemId = _tokenIds.current();

        string memory finalSvg = string(
            abi.encodePacked(baseSvg, _name, "</text></svg>")
        );

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', _name,
                        '", "description":', _description, 
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log("\n--------------------");
        console.log(finalTokenUri);
        console.log("--------------------\n");

        updateMapping(msg.sender, newItemId);
        
        // Mint NFT to the user
        _safeMint(msg.sender, newItemId);

        // Set NFT data
        _setTokenURI(newItemId, finalTokenUri);

        // Increment the counter for when the next NFT is minted.
        _tokenIds.increment();

        console.log(
            "An NFT with ID %s has been minted to %s",
            newItemId,
            msg.sender
        );

        emit NewNFTMinted(msg.sender, newItemId);
    }

    // function updateURI(tokenId, newURI) public {
    //     _setTokenURI(tokenId, newURI);
    // }
}