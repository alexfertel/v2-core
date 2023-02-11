// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupPro } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../Lockup.t.sol";

/// @title Pro_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupPro} unit and fuzz tests.
abstract contract Pro_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasParams {
        IERC20 asset;
        Broker broker;
        bool cancelable;
        uint40[] deltas;
        address recipient;
        address sender;
        LockupPro.SegmentWithDelta[] segments;
        uint128 totalAmount;
    }

    struct CreateWithMilestonesParams {
        IERC20 asset;
        Broker broker;
        bool cancelable;
        address recipient;
        LockupPro.Segment[] segments;
        address sender;
        uint40 startTime;
        uint128 totalAmount;
    }

    struct DefaultParams {
        CreateWithDeltasParams createWithDeltas;
        CreateWithMilestonesParams createWithMilestones;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupPro.Stream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams.createWithDeltas.sender = users.sender;
        defaultParams.createWithDeltas.recipient = users.recipient;
        defaultParams.createWithDeltas.totalAmount = DEFAULT_TOTAL_AMOUNT;
        defaultParams.createWithDeltas.asset = DEFAULT_ASSET;
        defaultParams.createWithDeltas.cancelable = true;
        defaultParams.createWithDeltas.broker = Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE });

        defaultParams.createWithMilestones.sender = users.sender;
        defaultParams.createWithMilestones.recipient = users.recipient;
        defaultParams.createWithMilestones.totalAmount = DEFAULT_TOTAL_AMOUNT;
        defaultParams.createWithMilestones.asset = DEFAULT_ASSET;
        defaultParams.createWithMilestones.cancelable = true;
        defaultParams.createWithMilestones.startTime = DEFAULT_START_TIME;
        defaultParams.createWithMilestones.broker = Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE });

        // See https://github.com/ethereum/solidity/issues/12783
        for (uint256 i = 0; i < DEFAULT_SEGMENTS.length; ++i) {
            defaultParams.createWithDeltas.segments.push(DEFAULT_SEGMENTS_WITH_DELTAS[i]);
            defaultParams.createWithMilestones.segments.push(DEFAULT_SEGMENTS[i]);
        }

        // Create the default stream to be used across the tests.
        defaultStream.amounts = DEFAULT_LOCKUP_AMOUNTS;
        defaultStream.isCancelable = defaultParams.createWithMilestones.cancelable;
        defaultStream.segments = defaultParams.createWithMilestones.segments;
        defaultStream.sender = defaultParams.createWithMilestones.sender;
        defaultStream.range = DEFAULT_PRO_RANGE;
        defaultStream.status = Lockup.Status.ACTIVE;
        defaultStream.asset = defaultParams.createWithMilestones.asset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with deltas.
    function createDefaultStreamWithDeltas() internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.totalAmount,
            defaultParams.createWithDeltas.asset,
            defaultParams.createWithDeltas.cancelable,
            defaultParams.createWithDeltas.segments,
            defaultParams.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(
        LockupPro.SegmentWithDelta[] memory segments
    ) internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.totalAmount,
            defaultParams.createWithDeltas.asset,
            defaultParams.createWithDeltas.cancelable,
            segments,
            defaultParams.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided end time. In this case, the last milestone is the end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        LockupPro.Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[1].milestone = endTime;
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            isCancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegments(LockupPro.Segment[] memory segments) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            totalAmount,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }
}
