// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "../interfaces/IERC7766.sol";
import "../interfaces/IERC7766Metadata.sol";

contract superVIP is ERC721, Ownable, IERC7766, IERC7766Metadata {

    uint256 private _nextTokenId;
    mapping(uint256 tokenId => uint256 privilegeId) private tokenPrivilegeId;
    mapping(uint256 privilegeId => bool) private privilegeIdStatus;
    mapping(uint256 privilegeId => uint256) private privilegeUseCount;
    
    constructor(address initOwner) ERC721("SuperVIP", "SVIP") Ownable(initOwner) {}

    function Mint(address to, uint256 _privilegeId) public onlyOwner {

        require(privilegeIdStatus[_privilegeId] != true, "PrivilegeId already exist");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        tokenPrivilegeId[tokenId] = _privilegeId;
        privilegeIdStatus[_privilegeId] = true;
        privilegeUseCount[_privilegeId] = 0;
    }

    function exercisePrivilege(address _to, uint256 _tokenId, uint256 _privilegeId, bytes calldata _data) external {
        if (_to == address(0)) {
            _to = msg.sender;
        }

        require(ownerOf(_tokenId) == msg.sender, "Token not exist");
        require(privilegeIdStatus[_privilegeId], "Privilege not exist or Invalid");

        dealWithData(_data);

        privilegeUseCount[_privilegeId] += 1;

        emit PrivilegeExercised(msg.sender, _to, _tokenId, _privilegeId);
    }

    function dealWithData(bytes calldata _data) internal {
        //
    }

    function isExercisable(address _to, uint256 _tokenId, uint256 _privilegeId) external view returns (bool _exercisable) {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIdStatus[_privilegeId], "Privilege not exist");

        return privilegeIdStatus[_privilegeId];
    }

    function isExercised(address _to, uint256 _tokenId, uint256 _privilegeId) external view returns (bool _exercised) {
        require(_to != address(0), "Illegal _to address");
        require(ownerOf(_tokenId) != address(0), "Token not exist");
        require(privilegeIdStatus[_privilegeId], "Privilege not exist");

        return privilegeUseCount[_privilegeId] > 0;
    }

    function getPrivilegeIds(uint256 _tokenId) external view returns (uint256[] memory) {
        require(ownerOf(_tokenId) != address(0), "Token not exist");

        uint256[] memory privilegeIds;
        privilegeIds[0] = tokenPrivilegeId[_tokenId];

        return privilegeIds;
    }

    function privilegeURI(uint256 _privilegeId) external view returns (string memory) {
        require(privilegeIdStatus[_privilegeId], "Privilege not exist");

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
