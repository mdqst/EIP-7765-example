// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "../interfaces/IERC7765.sol";
import "../interfaces/IERC7765Metadata.sol";

contract BurnablePrivileges is ERC721, IERC7765, IERC7765Metadata {
    uint256[] private privilegeIdsArr = [1, 2];
    mapping(uint256 privilegeId => bool) private privilegeIds;

    mapping(uint256 tokenId => mapping(uint256 privilegeId => address to)) privilegeStates;

    mapping(uint256 => uint256[]) burnPrivilegeIds;


    event BurnPrivilege(address indexed from, uint256 indexed tokenId, uint256 privilegeId);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        privilegeIds[1] = true;
        privilegeIds[2] = true;
    }

    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    /// @param _data  extra data passed in for extra message or future extension.
    function burnPrivilege(uint256 _tokenId, uint256 _privilegeId, bytes calldata _data) external {
        require(ownerOf(_tokenId) == msg.sender, "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");
        require(!checkPrivilegeIdIsBurn(_tokenId, _privilegeId),"privilegeId has been burned");

        // Optional to deal with _data
        dealWithData(_data);

        uint256[] memory hasBurnPrivilegeIds = burnPrivilegeIds[_tokenId];


        uint256[] memory newHasBurnPrivilegeIds = new uint256[](hasBurnPrivilegeIds.length + 1);
        

        for (uint i = 0; i < hasBurnPrivilegeIds.length; i++) {
            newHasBurnPrivilegeIds[i] = hasBurnPrivilegeIds[i];
        }

        newHasBurnPrivilegeIds[hasBurnPrivilegeIds.length] = _privilegeId;

        burnPrivilegeIds[_tokenId] = newHasBurnPrivilegeIds;
        emit BurnPrivilege(msg.sender, _tokenId, _privilegeId);
    }

    function checkPrivilegeIdIsBurn(uint256 _tokenId, uint256 _privilegeId) internal view returns(bool) {
        uint256[] memory hasBurnPrivilegeIds = burnPrivilegeIds[_tokenId];
        bool privilegeIdIsBurn = false;
        for (uint i = 0; i < hasBurnPrivilegeIds.length; i++) {
            if (hasBurnPrivilegeIds[i] == _privilegeId) {
                privilegeIdIsBurn = true;
                break;
            }
        }
        return privilegeIdIsBurn;
    }

    /// @notice This function exercised a specific privilege of a token if succeeds.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benifit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    /// @param _data  extra data passed in for extra message or future extension.
    function exercisePrivilege(address _to, uint256 _tokenId, uint256 _privilegeId, bytes calldata _data) external {
        if (_to == address(0)) {
            _to = msg.sender;
        }

        require(ownerOf(_tokenId) == msg.sender, "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");
        require(privilegeStates[_tokenId][_privilegeId] == address(0), "Privilege already exercised");
        require(!checkPrivilegeIdIsBurn(_tokenId, _privilegeId),"privilegeId has been burned");

        // Optional to deal with _data
        dealWithData(_data);

        privilegeStates[_tokenId][_privilegeId] = _to;
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
    function isExercisable(address _to, uint256 _tokenId, uint256 _privilegeId)
        external
        view
        returns (bool _exercisable)
    {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");
        require(!checkPrivilegeIdIsBurn(_tokenId, _privilegeId),"privilegeId has been burned");

        return privilegeStates[_tokenId][_privilegeId] == address(0);
    }

    /// @notice This function is to check whether a specific privilege of a token has been exercised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benifit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExercised(address _to, uint256 _tokenId, uint256 _privilegeId) external view returns (bool _exercised) {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIds[_privilegeId], "Privilege not exist");
        require(!checkPrivilegeIdIsBurn(_tokenId, _privilegeId),"privilegeId has been burned");

        return privilegeStates[_tokenId][_privilegeId] == _to;
    }

    /// @notice This function is to list all privilegeIds of a token.
    /// @param _tokenId  the NFT tokenID.
    function getPrivilegeIds(uint256 _tokenId) external view returns (uint256[] memory) {
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        uint256[] memory hasBurnPrivilegeIds = burnPrivilegeIds[_tokenId];
        if (hasBurnPrivilegeIds.length == 0) {
            return privilegeIdsArr;
        }

        uint256[] memory allPrivilegeIds = privilegeIdsArr;

        uint privilegeLength = allPrivilegeIds.length - hasBurnPrivilegeIds.length;

        uint256[] memory validPrivilegeIds = new uint256[](privilegeLength);

        for (uint k = 0; k < validPrivilegeIds.length; k++) {
            uint256 validPrivilegeId;
            for (uint i = 0; i < allPrivilegeIds.length; i++) {
                uint256 privilegeId = allPrivilegeIds[i];
                bool privilegeIdIsBurn = false;
                for (uint j = 0; j < hasBurnPrivilegeIds.length; j++) {
                    if (privilegeId == hasBurnPrivilegeIds[j]) {
                        privilegeIdIsBurn = true;
                        break;
                    }
                }
                if (!privilegeIdIsBurn) {
                    validPrivilegeId = privilegeId;
                }
            }
            validPrivilegeIds[k] = validPrivilegeId;
        }
        return validPrivilegeIds;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given privilegeId.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC-7765
    ///  Metadata JSON Schema".
    function privilegeURI(uint256 _privilegeId) external view returns (string memory) {
        require(privilegeIds[_privilegeId], "Privilege not exist");

        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(privilegeURIJSON(_privilegeId))))
        );
    }

    function privilegeURIJSON(uint256 _privilegeId) internal pure returns (string memory) {
        return string(
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
