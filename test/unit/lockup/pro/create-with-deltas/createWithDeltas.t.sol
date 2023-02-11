// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/UD2x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Events } from "src/libraries/Events.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LockupPro } from "src/types/DataTypes.sol";

import { Pro_Unit_Test } from "../Pro.t.sol";

contract CreateWithDeltas_Pro_Unit_Test is Pro_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Pro_Unit_Test.setUp();

        // Load the stream id.
        streamId = pro.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_LoopCalculationOverflowsBlockGasLimit() external {
        uint40[] memory deltas = new uint40[](1_000_000);
        vm.expectRevert(bytes(""));
        createDefaultStreamWithDeltas(deltas);
    }

    modifier loopCalculationsDoNotOverflowBlockGasLimit() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_DeltasZero() external loopCalculationsDoNotOverflowBlockGasLimit {
        uint40 startTime = getBlockTimestamp();
        uint40[] memory deltas = Solarray.uint40s(DEFAULT_SEGMENT_DELTAS[0], 0);
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentMilestonesNotOrdered.selector,
                index,
                startTime + deltas[0],
                startTime + deltas[0]
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    modifier deltasNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_SegmentArrayCountsNotEqual()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
    {
        uint40[] memory deltas = new uint40[](defaultParams.createWithDeltas.segments.length + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentArrayCountsNotEqual.selector,
                defaultParams.createWithDeltas.segments.length,
                deltas.length
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    modifier segmentArrayCountsEqual() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_MilestonesCalculationsOverflows_StartTimeNotLessThanFirstSegmentMilestone()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        segmentArrayCountsEqual
    {
        uint40 startTime = getBlockTimestamp();
        uint40[] memory deltas = Solarray.uint40s(UINT40_MAX, 1);
        LockupPro.Segment[] memory segments = defaultParams.createWithDeltas.segments;
        unchecked {
            segments[0].milestone = startTime + deltas[0];
            segments[1].milestone = deltas[0] + deltas[1];
        }
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_StartTimeNotLessThanFirstSegmentMilestone.selector,
                startTime,
                segments[0].milestone
            )
        );
        createDefaultStreamWithDeltas(deltas);
    }

    /// @dev it should revert.
    function test_RevertWhen_MilestonesCalculationsOverflows_SegmentMilestonesNotOrdered()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        segmentArrayCountsEqual
    {
        uint40 startTime = getBlockTimestamp();

        // Create the deltas such that they overflow.
        uint40[] memory deltas = Solarray.uint40s(1, UINT40_MAX, 1);

        // Create new segments that overflow when the milestones are eventually calculated.
        LockupPro.Segment[] memory segments = new LockupPro.Segment[](3);
        unchecked {
            segments[0] = LockupPro.Segment({ amount: 0, exponent: ud2x18(1e18), milestone: startTime + deltas[0] });
            segments[1] = LockupPro.Segment({
                amount: DEFAULT_SEGMENTS[0].amount,
                exponent: DEFAULT_SEGMENTS[0].exponent,
                milestone: segments[0].milestone + deltas[1]
            });
            segments[2] = LockupPro.Segment({
                amount: DEFAULT_SEGMENTS[1].amount,
                exponent: DEFAULT_SEGMENTS[1].exponent,
                milestone: segments[1].milestone + deltas[2]
            });
        }

        // Expect a {SegmentMilestonesNotOrdered} error.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupPro_SegmentMilestonesNotOrdered.selector,
                index,
                segments[0].milestone,
                segments[1].milestone
            )
        );

        // Create the stream.
        pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.totalAmount,
            segments,
            defaultParams.createWithDeltas.asset,
            defaultParams.createWithDeltas.cancelable,
            deltas,
            defaultParams.createWithDeltas.broker
        );
    }

    modifier milestonesCalculationsDoNotOverflow() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, mint the NFT,
    /// record the protocol fee, and emit a {CreateLockupProStream} event.
    function test_CreateWithDeltas()
        external
        loopCalculationsDoNotOverflowBlockGasLimit
        deltasNotZero
        segmentArrayCountsEqual
        milestonesCalculationsDoNotOverflow
    {
        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupPro} contract.
        expectTransferFromCall({
            from: funder,
            to: address(pro),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker.
        expectTransferFromCall({ from: funder, to: users.broker, amount: DEFAULT_BROKER_FEE_AMOUNT });

        // Expect a {CreateLockupProStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupProStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            segments: DEFAULT_SEGMENTS,
            asset: DEFAULT_ASSET,
            cancelable: true,
            range: DEFAULT_PRO_RANGE,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithDeltas();

        // Assert that the stream has been created.
        LockupPro.Stream memory actualStream = pro.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.range, defaultStream.range);
        assertEq(actualStream.segments, defaultStream.segments);
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = pro.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = pro.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        address actualNFTOwner = pro.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithDeltas.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
