// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "../interfaces/IERC7765.sol";
import "../interfaces/IERC7765Metadata.sol";

contract MultiplePrivilegeManagement is ERC721, IERC7765, IERC7765Metadata, Ownable {
    
    uint256 public privilegeId = 0;

    // This is a type for a single privilege.
    struct Privilege {
        uint256 id; // privilegeId
        string name; // the name of the privilege
        string description; // the description of the privilege
        uint256 expiration; // the expiration of the privilege
        uint256 tokenIdRangeStart; // the start number of a valid token ID
        uint256 tokenIdRangeEnd; // the end number of a valid token ID
        uint256 exerciseCount; // the number of accumulated exercises
    }

    mapping(uint256 privilegeId => Privilege) public privileges;
    mapping(uint256 tokenId => mapping(uint256 privilegeId => address)) public privilegeExercisedInfo;
    // One tokenId maps to multiple exercised privilegeIds.
    mapping(uint256 => uint256[]) public tokenPrivileges;

    /// @notice This event emitted when a new privilege is successfully released.
    /// @param _privilegeId the id of the privilege
    /// @param _name the name of the privilege
    /// @param _description  the description of the privilege
    /// @param _expiration the expiration of the privilege
    /// @param _tokenIdRangeStart the start number of a valid token ID
    /// @param _tokenIdRangeEnd the end number of a valid token ID
    event PrivilegeReleased(uint256 _privilegeId, string _name, string _description, uint256 _expiration, uint256 _tokenIdRangeStart, uint256 _tokenIdRangeEnd);

    modifier checkPrivilegeExist(uint256 _privilegeId) {
        require(privileges[_privilegeId].id > 0, "The privilege does not exist");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {}
    
    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId, "");
    }

    /// @notice This function releases a new privilege.
    /// @param _name the name of the privilege
    /// @param _description  the description of the privilege
    /// @param _expiration the expiration of the privilege
    /// @param _tokenIdRangeStart the start number of a valid token ID
    /// @param _tokenIdRangeEnd the end number of a valid token ID
    function releasePrivilege(
        string memory _name,
        string memory _description,
        uint256 _expiration,
        uint256 _tokenIdRangeStart,
        uint256 _tokenIdRangeEnd
    ) public onlyOwner {

        uint256 _privilegeId = ++privilegeId;

        privileges[_privilegeId] = Privilege({
            id: _privilegeId,
            name: _name,
            expiration: _expiration,
            description: _description,
            tokenIdRangeStart: _tokenIdRangeStart,
            tokenIdRangeEnd: _tokenIdRangeEnd,
            exerciseCount: 0
        });

        emit PrivilegeReleased(_privilegeId, _name, _description, _expiration, _tokenIdRangeStart, _tokenIdRangeEnd);
    }

    /// @notice This function exercised a specific privilege of a token if succeeds.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    /// @param _data  extra data passed in for extra message or future extension.
    function exercisePrivilege(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId,
        bytes calldata _data
    ) external checkPrivilegeExist(_privilegeId) {

        require(_to != address(0), "The _to is invalid");
        require(ownerOf(_tokenId) == _to, "The NFT does not exist");

        Privilege storage privilege = privileges[_privilegeId];
        require(privilege.expiration > block.timestamp, "The privilege has expired");
        require(privilege.tokenIdRangeStart <= _tokenId, "The _tokenId is out of range");
        require(privilege.tokenIdRangeEnd > _tokenId, "The _tokenId is out of range");
        require(privilegeExercisedInfo[_tokenId][_privilegeId] == address(0), "You had exercised this privilege");

        privilege.exerciseCount += 1; 
        privilegeExercisedInfo[_tokenId][_privilegeId] = _to;
        tokenPrivileges[_tokenId].push(_privilegeId);

        doExtension(_data);

        emit PrivilegeExercised(msg.sender, _to, _tokenId, _privilegeId);
    }

    /// @notice This function is to do extension according to `_data`.
    /// @param _data the additional data.
    function doExtension(bytes calldata _data) internal {
        // optional
    }

    /// @notice This function is to check whether a specific privilege of a token can be exercised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExercisable(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external checkPrivilegeExist(_privilegeId) view returns (bool _exercisable) {

        require(ownerOf(_tokenId) == _to, "The NFT does not exist");

        return privilegeExercisedInfo[_tokenId][_privilegeId] == address(0);
    }

    /// @notice This function is to check whether a specific privilege of a token has been exercised.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId.
    /// @param _to  the address to benefit from the privilege.
    /// @param _tokenId  the NFT tokenID.
    /// @param _privilegeId  the ID of the privileges.
    function isExercised(
        address _to,
        uint256 _tokenId,
        uint256 _privilegeId
    ) external checkPrivilegeExist(_privilegeId) view returns (bool _exercised) {

        require(_to != address(0), "The _to is invalid");
        require(ownerOf(_tokenId) == _to, "The NFT does not exist");

        return privilegeExercisedInfo[_tokenId][_privilegeId] != address(0);
    }

    /// @notice This function is to list all exercised privilegeIds of a token.
    /// @param _tokenId  the NFT tokenID.
    function getPrivilegeIds(
        uint256 _tokenId
    ) external view returns (uint256[] memory) {      
        require(ownerOf(_tokenId) != address(0), "The NFT does not exist");
        return tokenPrivileges[_tokenId];
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given privilegeId.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC-7765
    ///  Metadata JSON Schema".
    function privilegeURI(
        uint256 _privilegeId
    ) external view returns (string memory) {

        require(privileges[_privilegeId].id > 0, "The privilege does not exist");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(privilegeURIJSON(_privilegeId)))
                )
            );
    }

    function privilegeURIJSON(
        uint256 _privilegeId
    ) internal pure returns (string memory) {
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
