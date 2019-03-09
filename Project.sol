pragma solidity ^0.4.24;
import "./Seriality.sol";

contract ProjectFactory {

    address[] public deployedProjects;

    function createProject(string heading, address[] approvers_list, address opt, address off) public {
        address newProject = new Project(msg.sender, heading, approvers_list, opt, off);
        deployedProjects.push(newProject);
    }

    function getDeployedProjects() public view returns(address[]){
        return deployedProjects;
    }
}

contract Project is Seriality{

    struct StatusUpdates {
        string summary;
        uint currency_slice;
        uint total;
        uint update_time;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    uint public creation_timestamp;
    address public admin;
    address public operator;
    address public officer;
    string public title;
    string[] public arr;
    StatusUpdates[] public updates;
    bool public status;
    uint public UpdatesCount;
    mapping(address => bool) approvers;


    function Project(address creator, string heading, address[] approvers_list, address opt, address off) public {
        admin = creator;
        creation_timestamp = now;
        title = heading;
        status = true;
        operator = opt;
        officer = off;
        approvers[approvers_list[0]] = true;
        approvers[approvers_list[1]] = true;
        approvers[approvers_list[2]] = true;

        StatusUpdates memory firstUpdate = StatusUpdates({
            currency_slice: 0,
            total: 0,
            update_time: creation_timestamp,
            summary: "Project initiated.",
            complete: true,
            approvalCount: 3
            //only value types need to be initialized
            //we don't have to intialize reference types like approvals in Request struct
        });
        arr.push("Project initiated.");
        UpdatesCount++;
        updates.push(firstUpdate);

    }

    function setUpdate(string newTask, uint amount) public{
        require(msg.sender == operator);
        require(updates[updates.length -1].complete);
        StatusUpdates memory nextUpdate = StatusUpdates({
            currency_slice: amount,
            total: updates[updates.length - 1].total + amount,
            update_time: now,
            summary: newTask,
            complete: false,
            approvalCount: 0
            //only value types need to be initialized
            //we don't have to intialize reference types like approvals in Request struct
        });

        arr.push(newTask);
        updates.push(nextUpdate);
        UpdatesCount ++;
    }

    function approveRequest () public {
        StatusUpdates storage tempUpdate = updates[updates.length - 1];
        require(approvers[msg.sender]);
        require(!tempUpdate.approvals[msg.sender]);

        tempUpdate.approvals[msg.sender] = true;
        tempUpdate.approvalCount++;
        UpdatesCount++;
        if (tempUpdate.approvalCount == 3 && !tempUpdate.complete) {
            tempUpdate.complete = true;
        }

    }

    function finalizeRequest() public {
        StatusUpdates storage tempUpdate = updates[updates.length - 1];
        require(msg.sender == officer);
        require(!tempUpdate.complete);
        require(tempUpdate.approvalCount == 3);

        UpdatesCount++;
        tempUpdate.complete = true;
    }

    function endProject() public {
        require (msg.sender == admin);
        require(updates[updates.length -1].complete);
        StatusUpdates memory nextUpdate = StatusUpdates({
            currency_slice: 0,
            total: updates[updates.length - 1].total,
            update_time: now,
            summary: "Project termination initiated.",
            complete: false,
            approvalCount: 0
            //only value types need to be initialized
            //we don't have to intialize reference types like approvals in Request struct
        });

        arr.push("Project termination initiated.");
        updates.push(nextUpdate);
        UpdatesCount++;
        status = false;
    }

    function getUpdatesCount() public view returns(uint){
      return UpdatesCount;
    }
    
    function getStatusUpdates(uint[] indexes)
        public view
        returns (bytes, uint[], uint[], bool[], uint[], uint[])
    {

        string[] memory addrs = new string[](indexes.length);
        uint[] memory curr_slice = new uint[](indexes.length);
        uint[] memory sum = new uint[](indexes.length);
        bool[] memory state = new bool[](indexes.length);
        uint[] memory counter = new uint[](indexes.length);
        uint[] memory time = new uint[](indexes.length);


        for (uint i = 0; i < indexes.length; i++) {
            StatusUpdates storage temp = updates[indexes[i]];
            addrs[i] = temp.summary;
            time[i] = temp.update_time;
            curr_slice[i] = temp.currency_slice;
            sum[i] = temp.total;
            state[i] = temp.complete;
            counter[i] = temp.approvalCount;
        }

        return (getBytes(0, arr.length),curr_slice, sum, state, counter, time);
    }


    function getBytes(uint startindex, uint endindex) public view returns(bytes serialized){

        require(endindex >= startindex);

        if(endindex > (arr.length - 1)){
            endindex = arr.length - 1;
        }


        //64 byte is needed for safe storage of a single string.
        //((endindex - startindex) + 1) is the number of strings we want to pull out.
        uint offset = 64*((endindex - startindex) + 1);

        bytes memory buffer = new  bytes(offset);
        string memory out1  = new string(32);


        for(uint i = startindex; i <= endindex; i++){
            out1 = arr[i];

            stringToBytes(offset, bytes(out1), buffer);
            offset -= sizeOfString(out1);
        }

        return (buffer);
    }

}
