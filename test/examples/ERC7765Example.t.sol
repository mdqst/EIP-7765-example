// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../../src/references/MultiplePrivilegeManagement.sol";

contract ERC7765ExampleTest is Test {

    MultiplePrivilegeManagement private example;
    address private owner;
    address private user1;
    uint256 private tokenId = 1;
    uint256 private privilegeId = 1;
    uint256 private unknownPrivilegeId = 2;

    function setUp() public {
        owner = address(this);
        user1 = address(0xd0C05c200f933987376779184bD5B41DFaAc2D67);
        example = new MultiplePrivilegeManagement("Test Token", "TST", owner);
    }

    function testReleasePrivilege() public {

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );
        
        (
            uint256 id, 
            string memory name,,
            // string memory description, 
            uint256 expiration,,,
            // uint256 tokenIdRangeStart,
            // uint256 tokenIdRangeEnd,
            // uint256 exerciseCount
        ) = example.privileges(privilegeId);
        
        assertEq(id, privilegeId);
        assertEq(name, "Test Privilege");
        assertTrue(expiration > block.timestamp);
    }

    function testExercisePrivilegeInvalidId() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.expectRevert("The privilege does not exist");

        // Act as user and exercise privilege
        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, unknownPrivilegeId, "");
    }

    function testExercisePrivilegeInvalidTo() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.expectRevert("The privilege does not exist");
        
        // Act as user and exercise privilege
        vm.prank(owner);
        example.exercisePrivilege(owner, tokenId, unknownPrivilegeId, "");
    }

    function testExercisePrivilegeInvalidTokenId() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            10,
            100
        );

        vm.expectRevert("The _tokenId is out of range");

        // Act as user and exercise privilege
        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");
    }

    function testExercisePrivilegeInvalidExpiration() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp - 1000,
            1,
            100
        );

        vm.expectRevert("The privilege has expired");

        // Act as user and exercise privilege
        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");
    }

    function testExercisePrivilegeDuplicate() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        // Act as user and exercise privilege
        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");

        vm.expectRevert("You had exercised this privilege");

        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");
    }

    function testExercisePrivilege() public {
        // First, mint a token to the user
        example.safeMint(user1, tokenId);
        
        // Release a privilege
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        // Act as user and exercise privilege
        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");

        // Check if the privilege is exercised
        address exercisedBy = example.privilegeExercisedInfo(tokenId, privilegeId);
        assertEq(exercisedBy, user1);

        // Check if the privilege has been marked as exercised
        bool exercisable = example.isExercisable(user1, tokenId, privilegeId);
        assertFalse(exercisable);
    }

    function testIsExercised() public {
        example.safeMint(user1, tokenId);
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");

        bool exercised = example.isExercised(user1, tokenId, privilegeId);
        assertTrue(exercised);
    }

    function testGetPrivilegeIds() public {
        example.safeMint(user1, tokenId);
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, tokenId, privilegeId, "");

        uint256[] memory privileges = example.getPrivilegeIds(tokenId);
        assertEq(privileges.length, 1);
        assertEq(privileges[0], privilegeId);
    }

    function testPrivilegeURI() public {
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        string memory uri = example.privilegeURI(privilegeId);
        assertTrue(bytes(uri).length > 0);
    }
}
