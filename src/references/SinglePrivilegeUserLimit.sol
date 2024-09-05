// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "../interfaces/IERC7766.sol";
import "../interfaces/IERC7766Metadata.sol";

contract SinglePrivilegeUserLimit is ERC721, IERC7766, IERC7766Metadata {

    uint256[] private privilegeIdsArr = [1, 2];
    mapping(uint256 privilegeId => bool) private privilegeIds;

    mapping(uint256 tokenId => mapping(uint256 privilegeId => uint256 count)) privilegeCounts;

    mapping(uint256 tokenId => mapping(uint256 privilegeId => mapping(address to => uint256 count))) privilegeAddressCounts;

    uint256 constant public MAX_COUNT = 10;

    uint256 constant public SINGLE_ADDRESS_MAX_COUNT = 3;

    constructor(string memory name_, 
                string memory symbol_) 
        ERC721(name_, symbol_) {
            privilegeIds[1] = true;
            privilegeIds[2] = true;
        }

    /// @notice This function exercised a specific privilege of a token if succeeds.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benifit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    /// @param _data  extra data passed in for extra message or future extension.
    function exercisePrivilege(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId,
        bytes calldata _data
    ) external {
        if (_to == address(0)) {
            _to = msg.sender;
        }

        require(ownerOf(_tokenId) == msg.sender, "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");
        require(privilegeCounts[_tokenId][_privilegeId] < MAX_COUNT, "Privilege has already been exercised");
        require(privilegeAddressCounts[_tokenId][_privilegeId][_to] < SINGLE_ADDRESS_MAX_COUNT, "Privilege has already been exercised");

        // Optional to deal with _data
        dealWithData(_data);

        ++privilegeAddressCounts[_tokenId][_privilegeId][_to];
        emit PrivilegeExercised(msg.sender, _to, _tokenId, _privilegeId);
    }

    function dealWithData(bytes calldata _data) internal {
        //
    }

    /// @notice This function is to check whether a specific privilege of a token can be exercised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benifit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExercisable(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view returns (bool _exercisable) {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");

        return privilegeCounts[_tokenId][_privilegeId] < MAX_COUNT && privilegeAddressCounts[_tokenId][_privilegeId][_to] < SINGLE_ADDRESS_MAX_COUNT;
    }

    /// @notice This function is to check whether a specific privilege of a token has been exercised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benifit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExercised(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external view returns (bool _exercised) {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");

        return privilegeAddressCounts[_tokenId][_privilegeId][_to] > 0;
    }

    /// @notice This function is to list all privilegeIds of a token.
    /// @param _tokenId  the NFT tokenID.
    function getPrivilegeIds(
        uint256 _tokenId
    ) external view returns (uint256[] memory) {
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        return privilegeIdsArr;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given privilegeId.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC-7766
    ///  Metadata JSON Schema".
    function privilegeURI(uint256 _privilegeId) external view returns (string memory) {
        require(privilegeIds[_privilegeId], "Privilege not exist");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(privilegeURIJSON(_privilegeId)))
                )
            );
    }

    function privilegeURIJSON(uint256 _privilegeId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "{",
                    '"name": "Privilege #',
                    Strings.toString(_privilegeId),
                    '",',
                    '"description": "description -',
                    Strings.toString(_privilegeId),
                    '",',
                    '"resource": "ipfs://abc/',
                    Strings.toString(_privilegeId),
                    '"}'
                )
            );
    }

}