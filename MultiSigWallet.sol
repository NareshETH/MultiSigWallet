// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MultiSigWallet{


     address[] public owners;
     uint8 public required;

     struct Transaction{

      address to;
      uint256 value;
      uint32 number_of_approve;
      bool executed;

     }

     mapping(address => bool)public isOwner;
     mapping (uint256 => mapping (address => bool))approved;

     error required_is_greaterthan_owners();
     error onlyOwner_Can_Call();
     error Owners_required();

     Transaction[] public transactions;

     constructor(address[] memory _owners,uint8 _required){


     require(_required > 0 && _required <= _owners.length,"Invalid Required of Owners");

     if(_owners.length == 0){
         revert Owners_required();
     }
     

      for(uint8 i; i < _owners.length;i++){

          address owner = _owners[i];

          require(owner != address(0),"Invalid address");
          require(!isOwner[owner],"Owner is not unique");

          owners.push(owner);

          isOwner[owner] = true;


      }

      required = _required;


     } 

     modifier onlyOwner(){
     
     if(!isOwner[msg.sender]){

         revert onlyOwner_Can_Call();
     }
       _;
     }

     modifier notApproved(uint256 _txId){

       require(!approved[_txId][msg.sender],"Already Approved");

       _;
     }

     modifier notExecuted(uint256 _txId){

       require(!transactions[_txId].executed,"Already Executed");
       _;
     }

     modifier txExists(uint256 _txId){

       require(_txId < transactions.length,"txExists");
       _;
     }

     //to receive ether to this contract
     receive() external payable {}

    
     function submit(address _to,uint256 _value) external onlyOwner {

        transactions.push(Transaction(_to,_value,0,false));

     }


     function approve(uint256 _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){

      Transaction storage transaction = transactions[_txId];

      transaction.number_of_approve ++;

      approved[_txId][msg.sender] = true;

    }

     function Revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
      
     require(approved[_txId][msg.sender],"Not Approved"); 

     approved[_txId][msg.sender] = false;
     
     Transaction storage transaction = transactions[_txId];

     transaction.number_of_approve --;
          
     }

     function Execute(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {

        Transaction storage transaction = transactions[_txId];

        require(transaction.number_of_approve >= required,"Need to Approve" );

        transaction.executed = true;

        (bool success,) = transaction.to.call{value:transaction.value}("");

        require(success,"call Failed");

     }
    
  }