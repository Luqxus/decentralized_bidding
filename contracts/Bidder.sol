// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Bidder {
    struct Bid {
        uint bidId;
        address bidder;
        bool isOpen;
        uint256 bidAmount;
        uint prodId;
        bool accepted;
    }

    struct ListedProduct {
        uint prodId;
        address owner;
        bool isOpen;
        string name;
        string descriptions;
        string thumbnail;
        string[] imageUrls;
        uint256 initialPrice;
        Bid standingBid;
        bool allowBidLessThanInitialPrice;
    }

    ListedProduct[] listedProds;
    Bid[] bids;

    mapping(address => uint[]) prodOwners;
    mapping(address => uint[]) bidders;

    // maps product id to list of bids for that product | for convinience
    mapping(uint => Bid[]) prodBids;

    function listProduct(
        string calldata _prodName,
        string calldata _description,
        string[] calldata _imageUrls,
        string calldata _thumbnail,
        uint256 _initialPrice,
        bool _allowBidLessThanInitialPrice
    ) external returns (uint) {
        uint id = listedProds.length - 1;
        ListedProduct memory prod;

        prod.owner = msg.sender;
        prod.prodId = id;
        prod.descriptions = _description;
        prod.imageUrls = _imageUrls;
        prod.initialPrice = _initialPrice;
        prod.isOpen = true;
        prod.thumbnail = _thumbnail;
        prod.name = _prodName;
        prod.allowBidLessThanInitialPrice = _allowBidLessThanInitialPrice;

        listedProds.push(prod);
        prodOwners[msg.sender].push(id);

        return id - 1;
    }

    function bid(uint _prodId) external payable returns (uint) {
        ListedProduct memory _listedProd = listedProds[_prodId];

        // require(_listedProd.owner != 0x0, "invalid listing");
        require(
            _listedProd.isOpen == true,
            "cannot open bid on closed listing"
        );

        if (!_listedProd.allowBidLessThanInitialPrice) {
            require(msg.value >= _listedProd.initialPrice);
        }

        require(msg.value > bids[_listedProd.standingBid.bidId].bidAmount);

        uint _id = bids.length - 1;

        Bid memory _bid;
        _bid.bidAmount = msg.value;
        _bid.bidder = msg.sender;
        _bid.isOpen = true;
        _bid.prodId = _listedProd.prodId;
        _bid.bidId = _id;
        _bid.accepted = false;

        bids.push(_bid);
        prodBids[_prodId].push(_bid);
        bidders[msg.sender].push(_id);

        if (_bid.bidAmount > _listedProd.standingBid.bidAmount) {
            _listedProd.standingBid = _bid;
            listedProds[_prodId] = _listedProd;
        }

        return _id;
    }

    function acceptBid(uint _prodId) external {
        ListedProduct memory _listedProd = listedProds[_prodId];
        listedProds[_prodId].isOpen = false;

        require(_listedProd.owner == msg.sender);
        require(_listedProd.isOpen == true);

        for (uint _i = 0; _i < prodBids[_prodId].length; _i++) {
            if (
                prodBids[_prodId][_i].bidId != _listedProd.standingBid.bidId &&
                prodBids[_prodId][_i].isOpen
            ) {
                prodBids[_prodId][_i].isOpen = false;
                bids[prodBids[_prodId][_i].bidId].isOpen = false;

                payable(prodBids[_prodId][_i].bidder).transfer(
                    prodBids[_prodId][_i].bidAmount
                );

                continue;
            }

            prodBids[_prodId][_i].accepted = true;
            bids[prodBids[_prodId][_i].bidId].accepted = true;

            prodBids[_prodId][_i].isOpen = false;
            bids[prodBids[_prodId][_i].bidId].isOpen = false;
        }
    }

    function getListings() external view returns (ListedProduct[] memory) {
        return listedProds;
    }

    function getBids(uint _prodId) external view returns (Bid[] memory) {
        return prodBids[_prodId];
    }

    function getMyBids() external view returns (Bid[] memory) {
        Bid[] memory _bids = new Bid[](bidders[msg.sender].length);

        for (uint _i = 0; _i < bidders[msg.sender].length; _i++) {
            _bids[_i] = bids[bidders[msg.sender][_i]];
        }

        return _bids;
    }

    function getProduct(
        uint _prodId
    ) external view returns (ListedProduct memory) {
        return listedProds[_prodId];
    }
}
