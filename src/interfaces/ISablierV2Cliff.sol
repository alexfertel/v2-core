// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.4;

/// @notice The common interface between all Sablier V2 streaming contracts.
/// @author Sablier Labs Ltd.

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Cliff
/// @author Sablier Labs Ltd
/// @notice Creates cliff streams whose streaming function is $f(x) = x$ after a clif period ends.
interface ISablierV2Cliff is ISablierV2 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to create a stream with a start time greater than cliff time;
    error SablierV2Cliff__StartTimeGreaterThanCliffTime(uint256 startTime, uint256 cliffTime);

    /// @notice Emitted when attempting to create a stream with a cliff time greater than stop time;
    error SablierV2Cliff__CliffTimeGreaterThanStopTime(uint256 cliffTime, uint256 stopTime);

    /// EVENTS ///

    /// @notice Emitted when a stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the cliff period will end.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @param cancelable Whether the stream is cancelable or not.
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    );

    /// STRUCTS ///

    /// @notice Cliff stream struct.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct Stream {
        uint256 cliffTime;
        uint256 depositAmount;
        uint256 startTime;
        uint256 stopTime;
        uint256 withdrawnAmount;
        address recipient;
        address sender;
        IERC20 token;
        bool cancelable;
    }

    /// CONSTANT FUNCTIONS ///

    function getStream(uint256 streamId) external view returns (Stream memory stream);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new stream funded by `msg.sender`.
    ///
    /// @dev Emits a {CreateStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `from`.
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param from The address which funds the stream.
    /// @param sender The address from which to stream the money with a cliff.
    /// @param recipient The address toward which to stream the money with a cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a stream funded by `from`. Sets the start time to `block.timestamp` and the stop
    /// time to `block.timestamp + duration`.
    ///
    /// @dev Emits a {CreateStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - The duration calculation cannot overflow uint256.
    ///
    /// @param from The address which funds the stream.
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cliffDuration The number of seconds for how long the cliff period will last.
    /// @param totalDuration The total number of seconds for how long the stream will last.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 cliffDuration,
        uint256 totalDuration,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a stream funded by `msg.sender`. Sets the start time to `block.timestamp` and the stop
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - The cliff duration calculation cannot overflow uint256.
    /// - The total duration calculation cannot overflow uint256.
    ///
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cliffDuration The number of seconds for how long the cliff period will last.
    /// @param totalDuration The total number of seconds for how long the stream will last.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 cliffDuration,
        uint256 totalDuration,
        bool cancelable
    ) external returns (uint256 streamId);
}
