// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract RentHouseNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    IERC20 public _paymenToken;
    mapping(uint256 => mapping(uint256 => uint256))
        private _privilegesExercised;

    uint256 public constant RENT_PAYMENT = 1;

    event PrivilegeExercised(
        address indexed operator,
        address indexed to,
        uint256 indexed tokenId,
        uint256 privilegeId
    );

    constructor(
        address initOwner
    ) ERC721("RealEstateNFT", "REALESTATE") Ownable(initOwner) {}

    function setPaymentToken(address _token) external onlyOwner {
        _paymenToken = IERC20(_token);
    }

    function mint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
    }

    function isApprovedOrOwner(
        address operator,
        uint256 tokenId
    ) public view returns (bool) {
        return
            isApprovedForAll(ownerOf(tokenId), operator) ||
            ownerOf(tokenId) == _msgSender();
    }

    function exercisePrivilege(
        address to,
        uint256 tokenId,
        uint256 privilegeId,
        bytes calldata data
    ) external {
        require(
            isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved or owner"
        );

        // rentDate: month(202402)
        (uint256 rentDate, uint256 rentAmount) = abi.decode(
            data,
            (uint256, uint256)
        );
        require(
            _privilegesExercised[tokenId][rentDate] > 0,
            "Have already received rent this month"
        );

        _paymenToken.transferFrom(to, ownerOf(tokenId), rentAmount);

        _privilegesExercised[tokenId][rentDate] = rentAmount;
        emit PrivilegeExercised(_msgSender(), to, tokenId, privilegeId);
    }

    function isExercisable(
        address,
        uint256 tokenId,
        uint256 privilegeId
    ) external view returns (bool) {
        return
            isApprovedOrOwner(_msgSender(), tokenId) &&
            _privilegesExercised[tokenId][privilegeId] > 0;
    }

    function isExercised(
        address,
        uint256 tokenId,
        uint256 privilegeId
    ) external view returns (bool) {
        return _privilegesExercised[tokenId][privilegeId] > 0;
    }

    function getPrivilegeIds(
        uint256
    ) external pure returns (uint256[] memory) {
        uint256[] memory privilegeIds;
        privilegeIds[0] = RENT_PAYMENT;
        return privilegeIds;
    }
}
