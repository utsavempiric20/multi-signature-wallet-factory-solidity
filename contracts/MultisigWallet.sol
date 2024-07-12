// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultisigWallet {
    error MultisigWallet__TransferFailed();

    struct Transaction {
        uint24 transactionId;
        address to;
        uint256 amount;
        bool isExecuted;
    }

    address[] owners;
    uint256 numberOfApprovalRequired;
    uint256 AMOUNT_TO_WEI = 10 ** 18;

    mapping(address => mapping(uint24 => Transaction)) ownerTransaction;
    mapping(address => mapping(uint24 => bool)) approvelsOfOwners;
    mapping(address => uint24[]) transactionsHistory;
    mapping(uint24 => bool) transactionExist;

    modifier isApproved(uint24 _transactionId, address approver) {
        require(
            !approvelsOfOwners[approver][_transactionId],
            "Already Approved."
        );
        _;
    }

    modifier isTransactionExist(uint24 _transactionId) {
        require(transactionExist[_transactionId], "Transaction dosen't exist.");
        _;
    }

    modifier isTransactionExecuted(uint24 _transactionId, address owner) {
        require(
            !ownerTransaction[owner][_transactionId].isExecuted,
            "Transaction already Executed."
        );
        _;
    }

    modifier isTotalApprovalMeetRequired(uint24 _transactionId) {
        require(
            getTotalApprovalsOfTransaction(_transactionId) >=
                numberOfApprovalRequired,
            "Number of Approvals are not meet."
        );
        _;
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "Owner should not be 0.");
        for (uint256 i = 0; i < _owners.length; i++) {
            owners.push(_owners[i]);
        }
        numberOfApprovalRequired = (_owners.length / 2) + 1;
    }

    function createTransaction(
        address _to,
        uint256 _amount,
        address owner
    ) public payable returns (uint24) {
        uint256 payableAmount = _amount * AMOUNT_TO_WEI;
        require(msg.value == payableAmount, "Amount equal to payableAmount");
        uint24 _transactionId = uint24(
            uint256(
                keccak256(abi.encodePacked(_to, payableAmount, block.timestamp))
            )
        );

        Transaction memory _transaction = Transaction({
            transactionId: _transactionId,
            to: _to,
            amount: payableAmount,
            isExecuted: false
        });

        ownerTransaction[owner][_transactionId] = _transaction;
        transactionsHistory[owner].push(_transactionId);
        transactionExist[_transactionId] = true;
        return _transactionId;
    }

    function approveTranscationByOwner(
        uint24 _transactionId,
        address approver
    )
        public
        isTransactionExist(_transactionId)
        isApproved(_transactionId, approver)
    {
        approvelsOfOwners[approver][_transactionId] = true;
    }

    function recieveTransaction(
        uint24 _transactionId,
        address owner
    )
        public
        payable
        isTransactionExist(_transactionId)
        isTransactionExecuted(_transactionId, owner)
        isTotalApprovalMeetRequired(_transactionId)
    {
        Transaction storage transaction = ownerTransaction[owner][
            _transactionId
        ];
        transaction.isExecuted = true;

        (bool success, ) = payable(transaction.to).call{
            value: transaction.amount
        }("");
        if (!success) {
            revert MultisigWallet__TransferFailed();
        }
    }

    // Getter Functions
    function getTransaction(
        uint24 _transactionId,
        address owner
    )
        public
        view
        returns (
            uint24 transactionId,
            address to,
            uint256 amount,
            bool isExecuted
        )
    {
        Transaction memory transactionOfUser = ownerTransaction[owner][
            _transactionId
        ];
        return (
            transactionOfUser.transactionId,
            transactionOfUser.to,
            transactionOfUser.amount,
            transactionOfUser.isExecuted
        );
    }

    function getTransactionHistory(
        address owner
    ) public view returns (uint24[] memory) {
        return transactionsHistory[owner];
    }

    function getNumberOfApprovalRequired() public view returns (uint256) {
        return numberOfApprovalRequired;
    }

    function getTotalApprovalsOfTransaction(
        uint24 _transactionId
    ) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approvelsOfOwners[owners[i]][_transactionId]) {
                count++;
            }
        }
        return count;
    }
}
