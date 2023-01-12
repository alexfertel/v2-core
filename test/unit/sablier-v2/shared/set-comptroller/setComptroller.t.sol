// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";

import { Events } from "src/libraries/Events.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract SetComptroller_Test is SharedTest {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != users.admin);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IAdminable.Adminable_CallerNotAdmin.selector, users.admin, eve));
        sablierV2.setComptroller(ISablierV2Comptroller(eve));
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should emit a SetComptroller event and re-set the comptroller.
    function test_SetComptroller_SameComptroller() external callerAdmin {
        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit Events.SetComptroller(users.admin, comptroller, comptroller);

        // Re-set the comptroller.
        sablierV2.setComptroller(comptroller);

        // Assert that the comptroller did not change.
        address actualComptroller = address(sablierV2.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller);
    }

    /// @dev it should set the new comptroller.
    function test_SetComptroller_NewComptroller() external callerAdmin {
        // Deploy the new comptroller.
        ISablierV2Comptroller newComptroller = new SablierV2Comptroller({ initialAdmin: users.admin });

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit Events.SetComptroller(users.admin, comptroller, newComptroller);

        // Set the new comptroller.
        sablierV2.setComptroller(newComptroller);

        // Assert that the new comptroller was set.
        address actualComptroller = address(sablierV2.comptroller());
        address expectedComptroller = address(newComptroller);
        assertEq(actualComptroller, expectedComptroller);
    }
}
