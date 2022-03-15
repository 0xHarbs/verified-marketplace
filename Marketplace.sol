// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetMarketplace is ERC721, Ownable {
    uint256 assetCounter;
    uint256 tokenCounter;
    uint256 verifierCounter;
    uint256 ownerCounter;
    uint256 listingFee = 10;

    struct Asset {
        uint256 id;
        uint256 logbookHash;
        string name;
        string assetType;
        string assetBrand;
        string yearMade;
        uint256 ownerCount;
        address owner;
        address verifier;
        bool verified;
        bool forSale;
        uint256 price;
    }

    struct Owner {
        uint256 identificationHash;
        address verifier;
        bool verified;
        bool isExist;
    }

    struct Verifier {
        address verifierAddress;
        string identificationHash;
        string name;
        string acceptanceDate;
        bool stillVerified;
    }

    event newAsset(uint256 _id, string _name, address _address);
    event newVerifier(address _verifier, string _name, string _date);
    event assetListingCreated(
        uint256 _tokenId,
        address _sender,
        uint256 _price
    );
    event assetSold(uint256 _tokenId, uint256 _price, string _seller);

    Asset[] public assets;
    Verifier[] public verifiers;
    Owner[] public owners;

    mapping(uint256 => Asset) public tokenIdToAsset;
    mapping(uint256 => address) public assetToOwner;
    mapping(address => bool) public addressVerified;
    mapping(address => Owner) public addressToOwnerProfile;

    constructor() ERC721("AssetNFT", "ANFT") {
    }

    modifier onlyVerifier() {
        require(addressVerified[msg.sender] == true);
        _;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function createAsset(
        uint256 _logbookHash,
        string memory _name,
        string memory _assetType,
        string memory _assetBrand,
        string memory _yearMade,
        uint256 _ownerCount
    ) public {
        assets.push(
            Asset(
                assetCounter,
                _logbookHash,
                _name,
                _assetType,
                _assetBrand,
                _yearMade,
                _ownerCount,
                payable(msg.sender),
                msg.sender,
                false,
                false,
                0
            )
        );
        assetToOwner[assetCounter] = msg.sender;
        assetCounter++;
        emit newAsset(assetCounter, _name, msg.sender);
    }

    function mintToken(uint256 _assetId) internal {
        Asset storage myAsset = assets[_assetId];
        address owner = myAsset.owner;
        _mint(owner, tokenCounter);
        tokenIdToAsset[tokenCounter] = myAsset;
        tokenCounter++;
    }

    function createOwner(uint256 _identificationHash) public {
        require(!addressToOwnerProfile[msg.sender].isExist);
        owners.push(Owner(_identificationHash, msg.sender, false, true));
        addressToOwnerProfile[msg.sender] = owners[ownerCounter];
        ownerCounter++;
    }

    function updateOwnerIdentification(uint256 _identificationHash) public {
        require(addressToOwnerProfile[msg.sender].isExist);
        Owner storage ownerInfo = addressToOwnerProfile[msg.sender];
        ownerInfo.identificationHash = _identificationHash;
    }

    function createVerifier(
        address _verifier,
        string memory _identificationHash,
        string memory _name,
        string memory _date
    ) external onlyOwner {
        verifiers.push(
            Verifier(_verifier, _identificationHash, _name, _date, true)
        );
        addressVerified[_verifier] = true;
        verifierCounter++;
        emit newVerifier(_verifier, _name, _date);
    }

    function verifyOwner(uint256 _ownerId) public onlyVerifier {
        Owner storage owner = owners[_ownerId];
        owner.verified = true;
        owner.verifier = msg.sender;
    }

    function verifyAsset(uint256 _assetId) public onlyVerifier {
        Asset storage verifiedAsset = assets[_assetId];
        verifiedAsset.verified = true;
        verifiedAsset.verifier = msg.sender;
        mintToken(_assetId);
    }

    function denyVerifyAsset(uint256 _assetId) public onlyVerifier {
        Asset storage verifiedAsset = assets[_assetId];
        verifiedAsset.verified = false;
        verifiedAsset.verifier = msg.sender;
    }

    function listAsset(uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "Price must be at least 1 wei");
        require(msg.sender == ownerOf(_tokenId));
        Asset storage asset = tokenIdToAsset[_tokenId];
        require(asset.verified);
        asset.forSale = true;
        asset.price = _price;
        assets[asset.id] = asset;

        approve(address(this), _tokenId);
        emit assetListingCreated(_tokenId, msg.sender, _price);
    }

    function delistAsset(uint256 _tokenId) public {
        Asset storage asset = tokenIdToAsset[_tokenId];
        asset.forSale = false;
        asset.price = 0;
        assets[asset.id] = asset;
        safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function buyAsset(uint256 _tokenId) public payable {
        Asset storage asset = tokenIdToAsset[_tokenId];
        require(asset.forSale == true);
        require(
            msg.value == asset.price,
            "Please pay more than the asking price for this item"
        );

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
        
    
        asset.forSale = false;
        asset.price = 0;
        assets[asset.id] = asset;

        assetToOwner[asset.id] = msg.sender;
    }
}
