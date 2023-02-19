// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import "hardhat/console.sol";

/// @dev Constant Flow Agreement registration key, used to get the address from the host.
bytes32 constant CFA_ID = keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");


/// @title Stream Redirection Contract
/// @notice This contract is a registered super app, meaning it receives
contract RedirectAll is SuperAppBase {
    // SuperToken library setup
    using SuperTokenV1Library for ISuperToken;

    /// @dev Super token that may be streamed to this contract
    ISuperToken internal immutable _acceptedToken;

    ///@notice this is the superfluid host which is used in modifiers
    ISuperfluid immutable host;

    IConstantFlowAgreementV1 immutable cfa;

    /// @notice This is the list of current receivers that all streams are redirected to.
    mapping(uint256 => address) public _receivers;

    constructor(
        ISuperToken acceptedToken,
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa
    ) {
        assert(address(_host) != address(0));
        assert(address(acceptedToken) != address(0));
        assert(address(_cfa) != address(0));

        _acceptedToken = acceptedToken;
        host = _host;
        cfa = _cfa;

        // Registers Super App, indicating it is the final level (it cannot stream to other super
        // apps), and that the `before*` callbacks should not be called on this contract, only the
        // `after*` callbacks.
        host.registerApp(
            SuperAppDefinitions.APP_LEVEL_FINAL |
                SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
                SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
        );
    }

    // ---------------------------------------------------------------------------------------------
    // EVENTS

    /// @dev Logged when the receiver changes
    /// @param receiver The new receiver address.
    /// @param tokenId The tokenId of the NFT
    event ReceiverChanged(address indexed receiver, uint256 tokenId);

    /// @dev Logged when a new flow is created
    /// @param receiver The new receiver address.
    /// @param flowRate The new flowRate
    event FlowCreated(address indexed receiver, int96 flowRate);

    /// @dev Logged when the flow is updated
    /// @param receiver The new receiver address.
    /// @param flowRate The new flowRate
    event FlowUpdated(address indexed receiver, int96 flowRate);

    /// @dev Logged when the flow is deleted
    /// @param receiver The new receiver address.
    /// @param flowRate The new flowRate
    event FlowDeleted(address indexed receiver, int96 flowRate);

    // ---------------------------------------------------------------------------------------------
    // MODIFIERS

    modifier onlyHost() {
        require(msg.sender == address(host), "Not the Host");
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(superToken == _acceptedToken, "Invalid Token");
        require(agreementClass == address(cfa), "Invalid Agreement");
        _;
    }

    // ---------------------------------------------------------------------------------------------
    // RECEIVER DATA

    /// @notice Returns current receiver's address, start time, and flow rate.
    /// @return startTime Start time of the current flow.
    /// @return receiver Receiving address.
    /// @return flowRate Flow rate from this contract to the receiver.
    function currentReceiver(uint256 tokenId)
        external
        view
        returns (
            uint256 startTime,
            address receiver,
            int96 flowRate
        )
    {
        if (receiver != address(0)) {
            (startTime, flowRate, , ) = _acceptedToken.getFlowInfo(
                address(this),
                _receivers[tokenId]
            );

            receiver = _receivers[tokenId];
        }
    }

    // ---------------------------------------------------------------------------------------------
    // SUPER APP CALLBACKS

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId
        bytes calldata, //_agreementData
        bytes calldata, //_cbdata
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateOutflow(_ctx);
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData,
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateOutflow(_ctx);
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    ) 
        external 
        override 
        onlyHost
        returns (bytes memory newCtx) 
    {
        // According to the app basic law, we should never revert in a termination callback
        if (_superToken != _acceptedToken || _agreementClass != address(cfa)) {
            return _ctx;
        }

        return _updateOutflow(_ctx);
    }

    // ---------------------------------------------------------------------------------------------
    // INTERNAL LOGIC

    /// @dev Changes receiver and redirects all flows to the new one. Logs `ReceiverChanged`.
    /// @param newReceiver The new receiver to redirect to.
    function _changeReceiver(address newReceiver, uint256 tokenId) internal {
        require(newReceiver != address(0), "Receiver cannot be the Zero address");
        require(!host.isApp(ISuperApp(newReceiver)), "Receiver cannot be the Super App");

        if (newReceiver == _receivers[tokenId]) return;

        int96 outFlowRate = _acceptedToken.getFlowRate(address(this), _receivers[tokenId]);

        if (outFlowRate > 0) 
        {
            _acceptedToken.deleteFlow(address(this), _receivers[tokenId]);
            _acceptedToken.createFlow(newReceiver, _acceptedToken.getNetFlowRate(address(this)));
        }

        _receivers[tokenId] = newReceiver;

        emit ReceiverChanged(newReceiver, tokenId);
    }

    /// @dev Updates the outflow. The flow is either created, updated, or deleted, depending on the
    /// net flow rate.
    /// @param ctx The context byte array from the Host's calldata.
    /// @return newCtx The new context byte array to be returned to the Host.
    function _updateOutflow(bytes calldata ctx) private returns (bytes memory newCtx) {
        uint256 tokenId = bytesToUint(host.decodeCtx(ctx).userData);
        
        newCtx = ctx;

        console.log("---------------");
        console.logBytes(host.decodeCtx(ctx).userData);
        console.log("---------------");

        int96 netFlowRate = _acceptedToken.getNetFlowRate(address(this));

        int96 outFlowRate = _acceptedToken.getFlowRate(address(this), _receivers[tokenId]);

        int96 inFlowRate = netFlowRate + outFlowRate;

        if (inFlowRate == 0) {
            // The flow does exist and should be deleted.
            newCtx = _acceptedToken.deleteFlowWithCtx(address(this), _receivers[tokenId], ctx);
            emit FlowDeleted(_receivers[tokenId], 0);
        } else if (outFlowRate != 0) {
            // The flow does exist and needs to be updated.
            newCtx = _acceptedToken.updateFlowWithCtx(_receivers[tokenId], inFlowRate, ctx);
            emit FlowUpdated(_receivers[tokenId], inFlowRate);
        } else {
            // The flow does not exist but should be created.
            newCtx = _acceptedToken.createFlowWithCtx(_receivers[tokenId], inFlowRate, ctx);
            emit FlowCreated(_receivers[tokenId], inFlowRate);
        }
    }

    function getOutFlowRate(uint256 tokenId) internal view returns (int96 outFlowRate)
    {
        outFlowRate = _acceptedToken.getFlowRate(address(this), _receivers[tokenId]);
    }

    function updateMapping(address receiver, uint256 tokenId) internal {
        _receivers[tokenId] = receiver;
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++)
        {
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    
}