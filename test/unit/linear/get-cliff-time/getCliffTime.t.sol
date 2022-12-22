// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetCliffTime__Test is LinearTest {
    /// @dev it should return zero.
    function testGetCliffTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(nonStreamId);
        uint256 expectedCliffTime = 0;
        assertEq(actualCliffTime, expectedCliffTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct cliff time.
    function testGetCliffTime() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint256 actualCliffTime = sablierV2Linear.getCliffTime(defaultStreamId);
        uint256 expectedCliffTime = defaultStream.cliffTime;
        assertEq(actualCliffTime, expectedCliffTime);
    }
}
