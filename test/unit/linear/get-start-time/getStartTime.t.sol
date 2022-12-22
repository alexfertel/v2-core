// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { LinearTest } from "../LinearTest.t.sol";

contract GetStartTime__Test is LinearTest {
    /// @dev it should return zero.
    function testGetStartTime__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualStartTime = sablierV2Linear.getStartTime(nonStreamId);
        uint256 expectedStartTime = 0;
        assertEq(actualStartTime, expectedStartTime);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct start time.
    function testGetStartTime() external StreamExistent {
        uint256 defaultStreamId = createDefaultStream();
        uint256 actualStartTime = sablierV2Linear.getStartTime(defaultStreamId);
        uint256 expectedStartTime = defaultStream.startTime;
        assertEq(actualStartTime, expectedStartTime);
    }
}
