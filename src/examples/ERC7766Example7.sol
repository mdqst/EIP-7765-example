// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "../interfaces/IERC7766.sol";
import "../interfaces/IERC7766Metadata.sol";

contract ERC7766Example7 is ERC721, IERC7766, IERC7766Metadata, Ownable {
    uint256 public _privilegeId;
    mapping(uint256 _privilegeId => PrivilegeConfig) private privilegeIdConfigs;
    mapping(uint256 _privilegeId => bool) private exitPrivilegeIdConfigs;

    mapping(uint256 _tokenId => PrivilegeConfig) public tokenPrivilege;
    mapping(uint256 _privilegeId => bool) private exitTokenPrivilege;

    mapping(uint256 _tokenId => uint256) privilegeCounts;
    mapping(uint256 tokenId => bool) privilegeStates;

    uint256 public mintPrice = 40000000000000000;
    mapping(address => uint256 mintPrice) privilegeMintPrice;
    mapping(address => bool) privileged;

    mapping(address => address helpAddress) public helpAddressA;
    mapping(address => address helpAddress) public helpAddressB;


    event MintPriceChanged(uint256 oldPrice, uint256 newPrice);

    struct PrivilegeConfig {
        uint256 privilegeId;
        string status;
        string role;
        uint256 discount;
        uint256 helpNumbers;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        ++_privilegeId;
        privilegeIdConfigs[_privilegeId] = PrivilegeConfig({
            privilegeId: _privilegeId,
            status: "active",
            role: "OG",
            discount: 80,
            helpNumbers: 5
        });
        exitPrivilegeIdConfigs[_privilegeId] = true;

        ++_privilegeId;
        privilegeIdConfigs[_privilegeId] = PrivilegeConfig({
            privilegeId: _privilegeId,
            status: "inactive",
            role: "NORMAL",
            discount: 90,
            helpNumbers: 2 
        });
        exitPrivilegeIdConfigs[_privilegeId] = true;
    }
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        emit MintPriceChanged(mintPrice, _newMintPrice);
        mintPrice = _newMintPrice;
    }

    function addPrivilege(
        string memory role,
        uint256 discount,
        uint256 helpNumbers
    ) public onlyOwner {
        privilegeIdConfigs[++_privilegeId] = PrivilegeConfig({
            privilegeId: _privilegeId,
            status: "active",
            role: role,
            discount: discount,
            helpNumbers: helpNumbers
        });
        exitPrivilegeIdConfigs[_privilegeId] = true;
    }

    function removePrivilege(uint256 privilegeId) public onlyOwner {
        require(exitPrivilegeIdConfigs[privilegeId], "Privilege not exist");
        privilegeIdConfigs[privilegeId].status = "inactive";
    }

    function assignPrivilege(
        uint256 privilegeId,
        uint256 tokenId
    ) public onlyOwner {
        require(exitPrivilegeIdConfigs[privilegeId], "Privilege not exist");
        tokenPrivilege[tokenId] = privilegeIdConfigs[privilegeId];
    }

    function getPrivilege(
        uint256 privilegeId
    )
        public
        view
        returns (uint256, string memory, string memory, uint256, uint256)
    {
        require(exitPrivilegeIdConfigs[privilegeId], "Privilege not exist");
        PrivilegeConfig memory privilege = privilegeIdConfigs[privilegeId];
        return (
            privilege.privilegeId,
            privilege.status,
            privilege.role,
            privilege.discount,
            privilege.helpNumbers
        );
    }

    function getTokenPrivilege(
        uint256 tokenId
    )
        public
        view
        returns (uint256, string memory, string memory, uint256, uint256)
    {
         require(exitTokenPrivilege[tokenId], "Privilege not exist");
        PrivilegeConfig memory privilege = tokenPrivilege[tokenId];
        return (
            privilege.privilegeId,
            privilege.status,
            privilege.role,
            privilege.discount,
            privilege.helpNumbers
        );
    }

    function assignOgPrivilegeBatch(
        uint256 privilegeId,
        uint256[] calldata tokenList
    ) external onlyOwner {
        require(tokenList.length > 0, "");
        for (uint i = 0; i < tokenList.length; i++) {
            assignPrivilege(privilegeId, tokenList[i]);
        }
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
        address send = msg.sender;
        if (_to == address(0)) {
            _to = send;
        }
        require(exitTokenPrivilege[_tokenId], "Privilege not exist");
        require(exitPrivilegeIdConfigs[_privilegeId], "Privilege not exist");

        require(ownerOf(_tokenId) == send, "Token not exist");

       PrivilegeConfig memory _tokenPrivilegeConfig =  tokenPrivilege[_tokenId];
       PrivilegeConfig memory _privilegeIdConfigs =  privilegeIdConfigs[_privilegeId];
        require(
            keccak256(abi.encodePacked(_tokenPrivilegeConfig.role)) ==
                keccak256(abi.encodePacked(_privilegeIdConfigs.role)),
            ""
        );
        require(
            keccak256(abi.encodePacked(_tokenPrivilegeConfig.status)) ==
                keccak256(abi.encodePacked("active")),
            ""
        );
        require(
            privilegeCounts[_tokenId] < _tokenPrivilegeConfig.helpNumbers,
            ""
        );

        (bytes memory data) = abi.encode(
            privilegeIdConfigs[_privilegeId].discount,
            _to
        );
        // Optional to deal with _data
        // dealWithData(_data);
        dealWithData(data);

        ++privilegeCounts[_tokenId];
        privilegeStates[_tokenId] = true;
        helpAddressA[_to] = send;
        helpAddressB[send] = _to;
        emit PrivilegeExercised(msg.sender, _to, _tokenId, _privilegeId);
    }

    function dealWithData(bytes memory _data) internal {
        //
        (uint256 discount, address wallet) = abi.decode(
            _data,
            (uint256, address)
        );
        privilegeMintPrice[wallet] = (mintPrice * discount) / 100;
        privileged[wallet] = true;
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
        require(exitTokenPrivilege[_tokenId], "Privilege not exist");
        require(exitPrivilegeIdConfigs[_privilegeId], "Privilege not exist");

        require(ownerOf(_tokenId) == msg.sender, "Token not exist");

       PrivilegeConfig memory _tokenPrivilegeConfig =  tokenPrivilege[_tokenId];
       PrivilegeConfig memory _privilegeIdConfigs =  privilegeIdConfigs[_privilegeId];
        require(
            keccak256(abi.encodePacked(_tokenPrivilegeConfig.role)) ==
                keccak256(abi.encodePacked(_privilegeIdConfigs.role)),
            ""
        );

        return
            keccak256(abi.encodePacked(tokenPrivilege[_tokenId].status)) ==
            keccak256(abi.encodePacked("active")) &&
            privilegeCounts[_tokenId] < tokenPrivilege[_tokenId].helpNumbers;
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
        require(exitTokenPrivilege[_tokenId], "Privilege not exist");
        require(exitPrivilegeIdConfigs[_privilegeId], "Privilege not exist");

        return privilegeStates[_tokenId];
    }

    /// @notice This function is to list all privilegeIdConfigs of a token.
    /// @param _tokenId  the NFT tokenID.
    function getPrivilegeIds(
        uint256 _tokenId
    ) external view returns (uint256[] memory) {
        require(ownerOf(_tokenId) != address(0), "Token not exist");

        require(exitTokenPrivilege[_tokenId], "Privilege not exist");

        // Define and initialize the array with length 1
        uint256[] memory array;
        // Assign the privilegeId to the array
        array[0] = tokenPrivilege[_tokenId].privilegeId;
        
        return array;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given privilegeId.
    /// @dev Throws if `_privilegeId` is not a valid privilegeId. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC-7766
    ///  Metadata JSON Schema".
    function privilegeURI(
        uint256 _privilegeId
    ) external view returns (string memory) {
        require(exitPrivilegeIdConfigs[_privilegeId], "Privilege not exist");

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
