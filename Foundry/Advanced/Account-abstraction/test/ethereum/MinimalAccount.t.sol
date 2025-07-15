// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccountTest is Test {
    address private owner;
    HelperConfig private helperConfig;
    HelperConfig.NetworkConfig private config;
    MinimalAccount private minimalAccount;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.run();
        config = helperConfig.getConfig();
        owner = minimalAccount.owner();
    }

    function test_OwnerCanExecute() public {
        //Arrange
        uint256 amountToMint = 1 ether;
        address usdc = config.usdc;
        uint256 initialBalance = ERC20Mock(usdc).balanceOf(address(minimalAccount));
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);

        //Act
        vm.prank(owner);
        minimalAccount.execute(usdc, 0, functionData);

        //Assert
        uint256 endingBalance = ERC20Mock(usdc).balanceOf(address(minimalAccount));
        assertEq(initialBalance, 0);
        assertEq(endingBalance, amountToMint);
    }

    function test_executeRevertsIfNotOwner() public {
        //Arrange
        uint256 amountToMint = 1 ether;
        address usdc = config.usdc;
        address user = makeAddr("user");
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);

        //Act
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector));
        minimalAccount.execute(usdc, 0, functionData);
    }

    function test_recoverSignedOp() public {
        //Arrange
        uint256 amountToMint = 1 ether;
        address usdc = config.usdc;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);
        bytes memory executeData = abi.encodeWithSelector(MinimalAccount.execute.selector, usdc, 0, functionData);
        SendPackedUserOp sendPackedUserOp = new SendPackedUserOp();
        PackedUserOperation memory userOp =
            sendPackedUserOp.generateSignedUserOperation(executeData, address(minimalAccount), helperConfig);

        //Act
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        //Assert
        address recover = ECDSA.recover(digest, userOp.signature);
        assertEq(recover, owner);
    }

    function test_validationOfUserOps() public {
        //Arrange
        uint256 amountToMint = 1 ether;
        address usdc = config.usdc;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);
        bytes memory executeData = abi.encodeWithSelector(MinimalAccount.execute.selector, usdc, 0, functionData);
        SendPackedUserOp sendPackedUserOp = new SendPackedUserOp();
        PackedUserOperation memory userOp =
            sendPackedUserOp.generateSignedUserOperation(executeData, address(minimalAccount), helperConfig);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        uint256 missingAccountFounds = 1e5;

        //Act
        vm.prank(config.entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(userOp, userOpHash, missingAccountFounds);

        //Assert
        assertEq(validationData, 0);
    }

    function test_entryPointCanExecuteCommand() public {
        //Arrange
        uint256 amountToMint = 1 ether;
        address usdc = config.usdc;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), amountToMint);
        bytes memory executeData = abi.encodeWithSelector(MinimalAccount.execute.selector, usdc, 0, functionData);
        SendPackedUserOp sendPackedUserOp = new SendPackedUserOp();
        PackedUserOperation memory userOp =
            sendPackedUserOp.generateSignedUserOperation(executeData, address(minimalAccount), helperConfig);
        PackedUserOperation[] memory packedUserOp = new PackedUserOperation[](1);
        packedUserOp[0] = userOp;
        vm.deal(address(minimalAccount), 1 ether);

        //Act
        address randomUser = makeAddr("randomUser");
        vm.prank(randomUser);
        IEntryPoint(config.entryPoint).handleOps(packedUserOp, payable(randomUser));

        //Assert
        assertEq(ERC20Mock(usdc).balanceOf(address(minimalAccount)), amountToMint);
    }
}
