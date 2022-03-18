//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Event.sol";
import "hardhat/console.sol";

contract EventFactory {
    address public facilitator; // The address that should receive the cut
    uint256 public facilitatorCut; // in hundredths of a % (example: 325 == 3.25%)
    Event public eventContract; // The base Event contract that is deployed
    
    mapping(address => string) public artistMap;
    mapping(address => string) public venueMap;
    address[] public events;
    address[] public artists;
    address[] public venues;

    constructor(address _facilitator, uint256 _facilitatorCut) {
        facilitator = _facilitator;
        facilitatorCut = _facilitatorCut;
        eventContract = new Event();
    }

    function createEvent(
        uint256 capacity,
        uint256 price,
        uint256 artistCut,
        uint256 venueCut,
        uint256 resaleRoyalty,
        uint256 maxPerAddress,
        address payable artistAddress,
        address payable venueAddress,
        address payable facilitatorAddress,
        string memory name,
        string memory symbol
    ) public {
        eventContract.logOwner();
        address clonedEventContract = eventContract.createEvent();
        events.push(clonedEventContract);
        console.log("clone: ", clonedEventContract);
        Event(clonedEventContract).logOwner();
        Event(clonedEventContract).initialize(
            capacity,
            price,
            artistCut,
            venueCut,
            resaleRoyalty,
            maxPerAddress,
            artistAddress,
            venueAddress,
            facilitatorAddress,
            name,
            symbol
        );
        Event(clonedEventContract).logOwner();
    }

    function allEvents() public view returns (address[] memory) {
        return events;
    }

    function allArtists() public view returns (address[] memory) {
        return artists;
    }

    function allVenues() public view returns (address[] memory) {
        return venues;
    }

    function addArtist(address artistAddress, string memory ipfsHash) public {
        require(bytes(artistMap[artistAddress]).length == 0, "artistAddress already exists");

        artistMap[artistAddress] = ipfsHash;
        artists.push(artistAddress);
    }

    function addVenue(address venueAddress, string memory ipfsHash) public {
        require(bytes(venueMap[venueAddress]).length == 0, "venueAddress already exists");

        venueMap[venueAddress] = ipfsHash;
        venues.push(venueAddress);
    }
}