// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract CrowdFund{
    
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint startAt,
        uint endAt
    );

    event Cancel(uint id);

    event Pledge(uint indexed id, address indexed caller, uint amount);

    event Unpledge(uint indexed id, address indexed caller, uint amount);

    event Claim(uint _id);

    event Refund(uint indexed id, address indexed caller,uint amount);
    


    struct Campaign{
        address creator;
        uint goal;
        uint startAt;
        uint endAt;
        uint pledged;
        bool claimed;
    }

    IERC20 public immutable token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    uint public count;
    mapping (uint => Campaign) campaigns;
    mapping (uint => mapping(address => uint)) public pledgedAmount;

    function launch(
        uint _goal,
        uint _startAt,
        uint _endAt) external{
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "End at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");
        
        count += 1;
        campaigns[count] = Campaign({
            creator : msg.sender,
            goal : _goal,
            pledged : 0,
            startAt : _startAt,
            endAt : _endAt,
            claimed : false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Not Started");
        require(block.timestamp <= campaign.endAt, "Already ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender];
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
    
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp == campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp == campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged > goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }

}












