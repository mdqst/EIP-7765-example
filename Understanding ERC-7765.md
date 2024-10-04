NFTs bound to real-world assets sometimes need to carry certain privileges that can be exercised by the holder. Users can initiate transactions onchain to specify the exercise of a certain privilege, thereby achieving real-world privileges that directly map the onchain privilege through subsequent operations. For example, if a certain product such as a pair of shoes is sold onchain in the representation of NFT, the NFT holder can exercise the privilege of exchanging physical shoes offchain, to achieve the purpose of interoperability between the blockchain and the real world.

Based on the above practical RWA NFT application scenarios, the Mint Blockchain team proposed a new NFT asset protocol standard which carries a real world asset with some privileges that can be exercised by the holder of the corresponding NFT. And we will explain this protocol standard ERC-7765 in detail below.

First of all, the ERC-7765 standard inherits the ERC-721 NFT token standard for all transfer and approval logic. All transfer and approval functions are inherited from this token standard without changes.

```
interface IERC7765 /* is IERC721, IERC165 */
```

Next, we will see that ERC-7765 defines the core function and event for exercising privileges.

```
event PrivilegeExercised(
    address indexed _operator,
    address indexed _to,
    uint256 indexed _tokenId,
    uint256 _privilegeId
);
    
function exercisePrivilege(
    address _to,
    uint256 _tokenId,
    uint256 _privilegeId,
    bytes calldata _data
) external;
```

The function exercisePrivilege performs the exercise action to a specific privilege of a token. If succeeds, it is expected to emit a PrivilegeExercised event. With this event emitted onchain, we can determine that the user has confirmed the exercise of this privilege, so as to implement the privilege in the real world.
One thing you should note is that the param address _to is included in the design so that a specific privilege of an NFT may be exercised to someone who will benefit from it other than the NFT holder or the transaction initiator. And this ERC doesn't assume who has the power to perform this action, it's totally decided by the developers who are using this standard. For example, the NFT holder can exercise the privilege of exchanging physical shoes for his friend other than himself.
Another thing you should also note is that the extra field _data is designed for extra messages or future extensions. For example, developers can use _data to exercise a privilege that takes effect directly onchain such as direct distribution of cryptocurrency assets. This greatly improves the diversity and operability of the ways in which privileges can be exercised.

Then ERC-7765 defines two boolean view functions of isExercisable and isExercised to check whether a specific privilege of an NFT can be exercisable or has been exercised to the _to address, allowing access to the status of the privileges onchain.

```
function isExercisable(
    address _to,
    uint256 _tokenId,
    uint256 _privilegeId
) external view returns (bool _exercisable);

function isExercised(
    address _to,
    uint256 _tokenId,
    uint256 _privilegeId
) external view returns (bool _exercised);
```

Finally, ERC-7765 provides a way to manage the binding relationship between NFTs and privilegeIds through the function getPrivilegeIds, allowing querying what privileges are bound to a specific NFT.

```
function getPrivilegeIds(
    uint256 _tokenId
) external view returns (uint256[] memory privilegeIds);
```

Besides, ERC-7765 also creates a metadata extension for ERC-7765 smart contracts. This allows your smart contract to be interrogated for its details about the privileges which your NFTs carry.

```
interface IERC7765Metadata /* is IERC7765 */ {

    function privilegeURI(uint256 _privilegeId) external view returns (string memory);

}
```

And below is the ERC-7765 Metadata JSON Schema, which is similar to how ERC-721 metadata extension is built.

```
{
    "title": "Privilege Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the specific privilege."
        },
        "description": {
            "type": "string",
            "description": "Describes the specific privilege."
        },
        "resource": {
            "type": "string",
            "description": "A URI pointing to a resource representing the specific privilege."
        }
    }
}
```

For developers using ERC-7765 to build RWA NFT contracts, you should pay attention to the storage to the states of the privileges. The contract should properly handle the state transition of each privilege of each NFT, clearly showing that each privilege is exercisable or has been exercised. Also, you should carefully define access control, particularly whether any EOA or contract account may or may not call exercisePrivilege function in any use case.

In summary, the new ERC-7765 standard innovatively builds an asset protocol suitable for non-fungible tokens representing real world assets with privileges to be exercised. The interface definitions of this standard retain sufficient universality and flexibility, providing a potential option for building RWA NFT assets.
