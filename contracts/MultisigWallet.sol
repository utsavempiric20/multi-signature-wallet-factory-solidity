// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

contract MultisigWallet {
    error MultisigWallet__TransferFailed();

    struct Transaction {
        bytes4 transactionId;
        address from;
        address to;
        uint256 amount;
        bool isExecuted;
    }

    address[] owners;

    uint256 numberOfApprovalRequired;
    uint256 AMOUNT_TO_WEI = 10 ** 18;

    mapping(bytes4 => Transaction) ownerTransaction;
    mapping(address => bytes4[]) transactionsHistory;
    mapping(address => mapping(bytes4 => bool)) approvelsOfOwners;
    mapping(bytes4 => uint256) approverCount;
    mapping(bytes4 => bool) transactionExist;

    modifier isNotApproved(bytes4 _transactionId, address approver) {
        require(
            !approvelsOfOwners[approver][_transactionId],
            "Already Approved."
        );
        _;
    }

    modifier isTransactionExist(bytes4 _transactionId) {
        require(transactionExist[_transactionId], "Transaction dosen't exist.");
        _;
    }

    modifier isTransactionExecuted(bytes4 _transactionId, address owner) {
        require(
            !ownerTransaction[_transactionId].isExecuted,
            "Transaction already Executed."
        );
        _;
    }

    modifier isTotalApprovalMeetRequired(bytes4 _transactionId) {
        require(
            approverCount[_transactionId] >= numberOfApprovalRequired,
            "Number of Approvals are not meet."
        );
        _;
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "Owner should not be 0.");
        owners = _owners;
        numberOfApprovalRequired = (_owners.length / 2) + 1;
    }

    receive() external payable {}

    function createTransaction(
        address _to,
        uint256 _amount,
        address _owner
    ) public returns (bytes4) {
        uint256 payableAmount = _amount * AMOUNT_TO_WEI;
        require(
            payableAmount <= address(this).balance,
            "Insufficiant Balance in wallet."
        );
        bytes4 _transactionId = bytes4(
            keccak256(abi.encodePacked(_to, payableAmount, block.timestamp))
        );

        Transaction memory _transaction = Transaction({
            transactionId: _transactionId,
            from: _owner,
            to: _to,
            amount: payableAmount,
            isExecuted: false
        });

        ownerTransaction[_transactionId] = _transaction;
        transactionsHistory[_owner].push(_transactionId);
        transactionExist[_transactionId] = true;
        approvelsOfOwners[_owner][_transactionId] = true;
        approverCount[_transactionId]++;
        return _transactionId;
    }

    function approveTranscation(
        bytes4 _transactionId,
        address approver
    )
        public
        isTransactionExist(_transactionId)
        isNotApproved(_transactionId, approver)
    {
        approvelsOfOwners[approver][_transactionId] = true;
        approverCount[_transactionId]++;
        if (approverCount[_transactionId] >= numberOfApprovalRequired) {
            require(
                !ownerTransaction[_transactionId].isExecuted,
                "Transaction already Executed."
            );
            Transaction storage transaction = ownerTransaction[_transactionId];
            transaction.isExecuted = true;
            (bool success, ) = payable(transaction.to).call{
                value: transaction.amount
            }("");
            if (!success) {
                revert MultisigWallet__TransferFailed();
            }
        }
    }

    // Getter Functions
    function getTransaction(
        bytes4 _transactionId
    )
        public
        view
        returns (
            bytes4 transactionId,
            address from,
            address to,
            uint256 amount,
            bool isExecuted
        )
    {
        Transaction memory transactionOfUser = ownerTransaction[_transactionId];
        return (
            transactionOfUser.transactionId,
            transactionOfUser.from,
            transactionOfUser.to,
            transactionOfUser.amount,
            transactionOfUser.isExecuted
        );
    }

    function getTransactionHistory(
        address owner
    ) public view returns (bytes4[] memory) {
        return transactionsHistory[owner];
    }

    function getNumberOfApprovalRequired() public view returns (uint256) {
        return numberOfApprovalRequired;
    }

    function getTotalApprovalsOfTransaction(
        bytes4 _transactionId
    ) public view returns (uint256) {
        return approverCount[_transactionId];
    }

    function getWalletBalance(
        address _walletAddress
    ) public view returns (uint256) {
        return _walletAddress.balance;
    }
}
