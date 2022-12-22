// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Errors } from "src/libraries/Errors.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract Burn__Test is LinearTest {
    uint256 internal defaultStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        defaultStreamId = createDefaultStream();

        // Make the owner of the NFT the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotBurn__StreamExistent() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamExistent.selector, defaultStreamId));
        sablierV2Linear.burn(defaultStreamId);
    }

    modifier StreamNonExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotBurn__NFTNonExistent() external StreamNonExistent {
        uint256 nonStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        sablierV2Linear.burn(nonStreamId);
    }

    modifier NFTExistent() {
        // Cancel the stream so that the stream entity gets deleted.
        sablierV2Linear.cancel(defaultStreamId);
        _;
    }

    /// @dev it should revert.
    function testCannotBurn__CallerUnauthorized() external StreamNonExistent NFTExistent {
        // Make Eve the caller in the rest of this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamId, users.eve));
        sablierV2Linear.burn(defaultStreamId);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should burn the NFT.
    function testBurn__CallerApprovedOperator(
        address operator
    ) external StreamNonExistent NFTExistent CallerAuthorized {
        vm.assume(operator != address(0));

        // Approve the operator to handle the stream.
        sablierV2Linear.approve({ to: operator, tokenId: defaultStreamId });

        // Make the approved operator the caller in this test.
        changePrank(operator);

        // Run the test.
        sablierV2Linear.burn(defaultStreamId);
        address actualOwner = sablierV2Linear.getRecipient(defaultStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }

    /// @dev it should burn the NFT.
    function testBurn__CallerNFTOwner() external StreamNonExistent NFTExistent CallerAuthorized {
        sablierV2Linear.burn(defaultStreamId);
        address actualOwner = sablierV2Linear.getRecipient(defaultStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }
}
