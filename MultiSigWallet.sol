pragma solidity 0.7.5;
pragma abicoder v2;

contract MultiSigWallet {
    Transfer[] transferRequests;
    mapping(address => mapping(uint => bool)) approvals;
    uint limit;
    address[] internal owners;
    uint balance;
    
    struct Transfer{
        uint amount;
        address payable receiver;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }

    event TransferRequestCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);
    event deposited(uint valueDeposited, address _sender);

    modifier onlyOwners(){
        
       bool _amOwner;
        for (uint i=0; i <= owners.length - 1 ; i++)
       {
            if (owners[i] == msg.sender) {
                _amOwner = true;
                break;
            }
        }
        require(_amOwner,"Unauthorized");
        _;
   }
   
   constructor(address[] memory _owners, uint _limit){
       require(_owners.length > 1, "More than one address required");
       require(_limit > 1, "More than one signature required");
       require(_limit <= _owners.length, "Total number of signatures required can't exceed the total number provided.");
       
       //Check for duplicate addresses
       bool _duplicateFound;
       for (uint i = 0; i <= _owners.length - 1; i++){
           for (uint j = 1; j < _owners.length; j++) {
               if(_owners[i] == _owners[j]){
                   _duplicateFound = true;
                   break;
               }
           }
           if(_duplicateFound == false){
                 owners.push(_owners[i]);
               }
       }
       require(_duplicateFound == true, "Duplicate address found.");
       limit = _limit;
       
   }
   
   function deposit() public payable{
       require(msg.value > 0);
       uint oldBalance = balance;
       balance += msg.value;
       assert(balance == oldBalance + msg.value);
       
       emit deposited(msg.value, msg.sender);
   }
   
   function createTransfer(uint _amount, address payable _receiver) public onlyOwners {
       require(_amount > 0, "Amount must be greater than zero.");
       require(address(this).balance >= _amount, "Insufficient Funds");
    
       emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);

       transferRequests.push(Transfer(_amount, _receiver, 0, false, transferRequests.length));
   }
   
   function approve(uint _id) public onlyOwners{
       require(approvals[msg.sender][_id] == false);
       require(transferRequests[_id].hasBeenSent == false);
       
       approvals[msg.sender][_id] = true;
       transferRequests[_id].approvals++;
       
       emit ApprovalReceived(_id, transferRequests[_id].approvals, msg.sender);
   
       if(transferRequests[_id].approvals >= limit){
           transferRequests[_id].hasBeenSent = true;
           transferRequests[_id].receiver.transfer(transferRequests[_id].amount);
           emit TransferApproved(_id);
           
       }
   }
   
   function getTrasnferRequests() public view returns(Transfer[] memory) {
       return transferRequests;
   }
   
   function getTransferRequestApprovals(uint _id) public view returns(uint){
       return transferRequests[_id].approvals;
   }
}