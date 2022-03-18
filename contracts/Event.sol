//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EventFactory.sol";

contract Event is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    using SafeMath for uint256;

    uint256 public capacity;

    uint256 public price;

    uint256 public artistCut;

    uint256 public venueCut;

    uint256 public resaleRoyalty;

    uint256 public maxPerAddress;

    uint256 public startingBlock;

    uint256 public endingBlock;

    address payable public artistAddress;

    address payable public venueAddress;

    address payable public facilitatorAddress;

    bytes32 public constant ARTIST_ROLE = 0x00;

    bytes32 public constant FACILITATOR_ROLE = 0x00;

    bytes32 public constant VENUE_ROLE = 0x00;

    uint256 private artistBalance;

    uint256 private venueBalance;

    uint256 private facilitatorBalance;

    constructor () initializer {
        __Context_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function createEvent() public returns (address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized to create event");
        return ClonesUpgradeable.clone(address(this));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function logOwner() public view {
        console.log("admin: ", hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        console.log("artist: ", hasRole(ARTIST_ROLE, artistAddress));
        console.log("facilitator: ", hasRole(ARTIST_ROLE, facilitatorAddress));
        console.log("venue: ", hasRole(ARTIST_ROLE,venueAddress));
        console.log("msgSender: ", msg.sender);
    }

    function initialize(
        uint256 _capacity,
        uint256 _price,
        uint256 _artistCut,
        uint256 _venueCut,
        uint256 _resaleRoyalty,
        uint256 _maxPerAddress,
        address payable _artistAddress,
        address payable _venueAddress,
        address payable _facilitatorAddress,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Context_init_unchained();
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        capacity = _capacity;
        price = _price;
        artistCut = _artistCut;
        venueCut = _venueCut;
        resaleRoyalty = _resaleRoyalty;
        maxPerAddress = _maxPerAddress;
        artistAddress = _artistAddress;
        venueAddress = _venueAddress;
        facilitatorAddress = _facilitatorAddress;
        grantRole(ARTIST_ROLE, _artistAddress);
        grantRole(VENUE_ROLE, _venueAddress);
        grantRole(FACILITATOR_ROLE, _facilitatorAddress);
    }

    function mint(uint256 mintAmount) public payable {
        _verifyMintTicket(mintAmount);
        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 index = totalSupply();
            if (index < capacity){
                _safeMint(msg.sender, index);
            }
            
        }  
        _updateBalancesFromMint();
    }

    function _verifyMintTicket(uint256 amount) private {
        require(amount > 0, "must mint more than 0");
        require(amount <= maxPerAddress, "minting more than allowed amount");
        require(
            totalSupply().add(amount) <= capacity,
            "purchase exceeds max supply"
        );
        require(
            price.mul(amount) <= msg.value,
            "not enough ether sent"
        );
        require(startingBlock > 0, "starting block not set");
        require(block.number >= startingBlock, "minting has not started");
        require(block.number <= endingBlock, "minting has ended");
    }

    function _updateBalancesFromMint() private {
        artistBalance = artistBalance.add(msg.value.mul(artistCut).div(100));
        venueBalance = venueBalance.add(msg.value.mul(venueCut).div(100));
        facilitatorBalance = facilitatorBalance.add(msg.value.mul(15).div(100));
    }

    function venueWithdrawal() public {
        require(hasRole(VENUE_ROLE, msg.sender), "Unauthorized to withdrawal");
        uint256 amountToTransfer = venueBalance;
        venueBalance = 0;
        artistAddress.transfer(amountToTransfer);
    }

    function artistWithdrawal() public {
        require(hasRole(ARTIST_ROLE, msg.sender), "Unauthorized to withdrawal");
        uint256 amountToTransfer = artistBalance;
        artistBalance = 0;
        artistAddress.transfer(amountToTransfer);
    }

    function facilitatorWithdrawal() public {
        require(hasRole(FACILITATOR_ROLE, msg.sender), "Unauthorized to withdrawal");
        uint256 amountToTransfer = facilitatorBalance;
        facilitatorBalance = 0;
        artistAddress.transfer(amountToTransfer);
    }

    function setStartingblock(uint256 blockNumber) public {
        require(startingBlock == 0, "starting block is already set");
        require(hasRole(FACILITATOR_ROLE, msg.sender), "Unauthorized to set starting block");
        startingBlock = blockNumber;
    }

    function setEndingblock(uint256 blockNumber) public {
        require(endingBlock == 0, "ending block is already set");
        require(hasRole(FACILITATOR_ROLE, msg.sender), "Unauthorized to set ending block");
        endingBlock = blockNumber;
    }

}