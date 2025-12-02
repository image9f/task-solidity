// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 拍卖合约
contract Auction {
    // 存储ERC20代币地址到其对应的Chainlink价格聚合器接口的映射
    mapping(address => AggregatorV3Interface) public priceFeeds;
    // ETH/USD价格聚合器接口
    AggregatorV3Interface public ethUsdPriceFeed;

    // 拍卖物品结构体
    struct AuctionItem {
        uint256 auctionId; // 拍卖ID
        address seller; // 卖家地址
        IERC721 nftContract; // NFT合约地址
        uint256 tokenId; // NFT的Token ID
        uint256 startPrice; // 起拍价
        uint256 endTimestamp; // 拍卖结束时间戳
        uint256 highestBid; // 当前最高出价
        address highestBidder; // 当前最高出价者
        uint8 highestBidCurrency; // 最高出价货币类型：0代表ETH，1代表ERC20
        address erc20TokenAddress; // 如果最高出价货币是ERC20，则为ERC20代币地址
        uint256 highestBidInUsd; // 最高出价的美元价值
        bool ended; // 拍卖是否结束
    }

    // 拍卖ID到拍卖物品结构体的映射
    mapping(uint256 => AuctionItem) public auctions;
    // 拍卖ID计数器
    uint256 private _auctionIdCounter;

    // 拍卖创建事件
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 startPrice, uint256 endTimestamp);
    // 出价事件
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    // 拍卖结束事件
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 highestBid);

    // 初始化函数
    function initialize() internal virtual {
        _auctionIdCounter = 0;
    }

    // 设置ERC20代币的价格聚合器
    function setPriceFeed(address _tokenAddress, address _priceFeedAddress) public virtual {
        priceFeeds[_tokenAddress] = AggregatorV3Interface(_priceFeedAddress);
    }

    // 设置ETH/USD的价格聚合器
    function setEthUsdPriceFeed(address _priceFeedAddress) public virtual {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // 获取最新价格
    function getLatestPrice(address _tokenAddress) public view virtual returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[_tokenAddress];
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return price;
    }

    // 创建拍卖
    function createAuction(
        IERC721 _nftContract, // NFT合约地址
        uint256 _tokenId, // NFT的Token ID
        uint256 _startPrice, // 起拍价
        uint8 _startPriceCurrency, // 起拍价货币类型：0代表ETH，1代表ERC20
        address _erc20TokenAddress, // 如果起拍价货币是ERC20，则为ERC20代币地址
        uint256 _duration // 拍卖持续时间（秒）
    ) public virtual {
        require(_startPrice > 0, "Start price must be greater than 0"); // 起拍价必须大于0
        require(_duration > 0, "Duration must be greater than 0"); // 持续时间必须大于0
        if (_startPriceCurrency == 1) {
            require(_erc20TokenAddress != address(0), "ERC20 token address cannot be zero"); // ERC20代币地址不能为零地址
        }

        // 将NFT转移到拍卖合约
        _nftContract.transferFrom(msg.sender, address(this), _tokenId);

        _auctionIdCounter++;
        uint256 newAuctionId = _auctionIdCounter;

        auctions[newAuctionId] = AuctionItem({
            auctionId: newAuctionId,
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            startPrice: _startPrice,
            endTimestamp: block.timestamp + _duration,
            highestBid: _startPrice,
            highestBidder: address(0), // 初始没有最高出价者
            highestBidCurrency: _startPriceCurrency,
            erc20TokenAddress: _erc20TokenAddress,
            highestBidInUsd: _convertToUsd(_erc20TokenAddress, _startPrice, _startPriceCurrency),
            ended: false
        });

        emit AuctionCreated(newAuctionId, msg.sender, address(_nftContract), _tokenId, _startPrice, block.timestamp + _duration);
    }

    // 出价（ETH）
    function placeBid(uint256 _auctionId) public payable virtual {
        AuctionItem storage auction = auctions[_auctionId];
        require(auction.auctionId != 0, "Auction does not exist"); // 拍卖必须存在
        require(!auction.ended, "Auction has ended"); // 拍卖不能已结束
        require(block.timestamp < auction.endTimestamp, "Auction has ended"); // 拍卖必须在进行中

        uint256 bidInUsd = _convertToUsd(address(0), msg.value, 0); // 将ETH出价转换为美元
        require(bidInUsd > auction.highestBidInUsd, "Bid must be higher than current highest bid in USD"); // 出价必须高于当前最高出价的美元价值

        // 如果有之前的最高出价者，则退款
        if (auction.highestBidder != address(0)) {
            if (auction.highestBidCurrency == 0) { // ETH
                payable(auction.highestBidder).transfer(auction.highestBid); // 退还ETH
            } else { // ERC20
                IERC20(auction.erc20TokenAddress).transfer(auction.highestBidder, auction.highestBid); // 退还ERC20
            }
        }

        auction.highestBid = msg.value; // 更新最高出价
        auction.highestBidder = msg.sender; // 更新最高出价者
        auction.highestBidCurrency = 0; // 设置货币类型为ETH
        auction.erc20TokenAddress = address(0); // 清空ERC20代币地址
        auction.highestBidInUsd = bidInUsd; // 更新最高出价的美元价值

        emit BidPlaced(_auctionId, msg.sender, msg.value); // 发出出价事件
    }

    // 出价（ERC20）
    function placeBidERC20(uint256 _auctionId, uint256 _amount, address _erc20TokenAddress) public virtual {
        AuctionItem storage auction = auctions[_auctionId];
        require(auction.auctionId != 0, "Auction does not exist"); // 拍卖必须存在
        require(!auction.ended, "Auction has ended"); // 拍卖不能已结束
        require(block.timestamp < auction.endTimestamp, "Auction has ended"); // 拍卖必须在进行中
        require(_erc20TokenAddress != address(0), "ERC20 token address cannot be zero"); // ERC20代币地址不能为零地址

        uint256 bidInUsd = _convertToUsd(_erc20TokenAddress, _amount, 1); // 将ERC20出价转换为美元
        require(bidInUsd > auction.highestBidInUsd, "Bid must be higher than current highest bid in USD"); // 出价必须高于当前最高出价的美元价值

        // 将ERC20从出价者转移到拍卖合约
        IERC20(_erc20TokenAddress).transferFrom(msg.sender, address(this), _amount);

        // 如果有之前的最高出价者，则退款
        if (auction.highestBidder != address(0)) {
            if (auction.highestBidCurrency == 0) { // ETH
                payable(auction.highestBidder).transfer(auction.highestBid); // 退还ETH
            } else { // ERC20
                IERC20(auction.erc20TokenAddress).transfer(auction.highestBidder, auction.highestBid); // 退还ERC20
            }
        }

        auction.highestBid = _amount; // 更新最高出价
        auction.highestBidder = msg.sender; // 更新最高出价者
        auction.highestBidCurrency = 1; // 设置货币类型为ERC20
        auction.erc20TokenAddress = _erc20TokenAddress; // 设置ERC20代币地址
        auction.highestBidInUsd = bidInUsd; // 更新最高出价的美元价值

        emit BidPlaced(_auctionId, msg.sender, _amount); // 发出出价事件
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) public virtual {
        AuctionItem storage auction = auctions[_auctionId];
        require(auction.auctionId != 0, "Auction does not exist"); // 拍卖必须存在
        require(!auction.ended, "Auction has ended"); // 拍卖不能已结束
        require(block.timestamp >= auction.endTimestamp, "Auction has not ended yet"); // 拍卖必须已结束

        auction.ended = true; // 设置拍卖状态为已结束

        if (auction.highestBidder != address(0)) {
            // 将NFT转移给最高出价者
            auction.nftContract.transferFrom(address(this), auction.highestBidder, auction.tokenId);
            // 将资金转移给卖家
            if (auction.highestBidCurrency == 0) { // ETH
                payable(auction.seller).transfer(auction.highestBid); // 转移ETH
            } else { // ERC20
                IERC20(auction.erc20TokenAddress).transfer(auction.seller, auction.highestBid); // 转移ERC20
            }
        } else {
            // 没有出价，将NFT退还给卖家
            auction.nftContract.transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid); // 发出拍卖结束事件
    }

    // 内部函数：将金额转换为美元
    function _convertToUsd(address _tokenAddress, uint256 _amount, uint8 _currency) internal view virtual returns (uint256) {
        AggregatorV3Interface priceFeed;
        if (_currency == 0) { // ETH
            priceFeed = ethUsdPriceFeed; // 使用ETH/USD价格聚合器
        } else { // ERC20
            priceFeed = priceFeeds[_tokenAddress]; // 使用ERC20/USD价格聚合器
        }
        
        require(address(priceFeed) != address(0), "Price feed not available"); // 价格聚合器必须可用

        (, int256 price, , ,) = priceFeed.latestRoundData(); // 获取最新价格
        require(price > 0, "Price feed returned invalid value"); // 价格必须大于0

        // 假设价格聚合器返回8位小数，代币金额为18位小数
        // 这可能需要根据实际代币小数位数进行调整
        return (_amount * uint256(price)) / (10 ** 8);
    }
}