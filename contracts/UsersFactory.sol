// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MultisigWallet.sol";

contract UsersFactory {
    MultisigWallet[] multisigWallets;
    mapping(MultisigWallet => address[]) ownersOfWallet;
    uint256 AMOUNT_TO_WEI = 10 ** 18;

    modifier onlyOwner(MultisigWallet _multisigWallet) {
        require(
            checkOwner(_multisigWallet, msg.sender),
            "Only Valid Owner can perform it."
        );
        _;
    }

    function createMultisigWallet(address[] memory _owners) public {
        MultisigWallet multisigWallet = new MultisigWallet(_owners);
        multisigWallets.push(multisigWallet);
        ownersOfWallet[multisigWallet] = _owners;
    }

    function createTransaction(
        MultisigWallet _multisigWallet,
        address _to,
        uint256 _amount
    ) public payable onlyOwner(_multisigWallet) returns (uint24) {
        return
            _multisigWallet.createTransaction{value: msg.value}(
                _to,
                _amount,
                msg.sender
            );
    }

    function approveTranscationByOwner(
        MultisigWallet _multisigWallet,
        uint24 _transactionId
    ) public onlyOwner(_multisigWallet) {
        _multisigWallet.approveTranscationByOwner(_transactionId, msg.sender);
    }

    function recieveTransaction(
        MultisigWallet _multisigWallet,
        uint24 _transactionId
    ) public payable onlyOwner(_multisigWallet) {
        _multisigWallet.recieveTransaction(_transactionId, msg.sender);
    }

    // Getter
    function getOwnersOfMultisigWallets(
        MultisigWallet _multisigWallet
    ) public view returns (address[] memory) {
        return ownersOfWallet[_multisigWallet];
    }

    function getMultisigWallets()
        public
        view
        returns (MultisigWallet[] memory)
    {
        return multisigWallets;
    }

    function checkOwner(
        MultisigWallet _multisigWallet,
        address _owner
    ) internal view returns (bool) {
        address[] memory owners = ownersOfWallet[_multisigWallet];
        for (uint256 i = 0; i < owners.length; i++) {
            if (_owner == owners[i]) {
                return true;
            }
        }
        return false;
    }

    function getTransaction(
        MultisigWallet _multisigWallet,
        uint24 _transactionId
    )
        public
        view
        onlyOwner(_multisigWallet)
        returns (
            uint24 transactionId,
            address to,
            uint256 amount,
            bool isExecuted
        )
    {
        return _multisigWallet.getTransaction(_transactionId, msg.sender);
    }

    function getTransactionHistory(
        MultisigWallet _multisigWallet
    ) public view onlyOwner(_multisigWallet) returns (uint24[] memory) {
        return _multisigWallet.getTransactionHistory(msg.sender);
    }

    function getNumberOfApprovalRequired(
        MultisigWallet _multisigWallet
    ) public view returns (uint256) {
        return _multisigWallet.getNumberOfApprovalRequired();
    }

    function getTotalApprovalsOfTransaction(
        MultisigWallet _multisigWallet,
        uint24 _transactionId
    ) public view returns (uint256) {
        return _multisigWallet.getTotalApprovalsOfTransaction(_transactionId);
    }
}
