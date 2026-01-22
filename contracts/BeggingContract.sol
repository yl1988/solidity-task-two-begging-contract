// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract BeggingContract {

    // 录每个捐赠者的捐赠金额
    mapping (address => uint256) private _usersMoney;

    // 合约所有者
    address payable private _owner;

     // 捐赠开始和结束时间
    uint256 public donationStartTime;
    uint256 public donationEndTime;

    uint256 public totalReceived;

    event Donated(address indexed donor, uint256 money, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 money, uint256 timestamp);

    // 构造函数，设置合约所有者
    constructor(uint256 _donationDuration) {
        _owner = payable(msg.sender);
        donationStartTime = block.timestamp;
        donationEndTime = block.timestamp + _donationDuration;
    }

    // 修饰符，只有所有者可以调用
    modifier onlyOwner(){
        require(msg.sender == _owner, "nly owner can call this function");
        _;
    }

    // 修饰符，检查捐赠时间是否有效
    modifier donationPerioActive() {
        require(block.timestamp >= donationStartTime, "Donation period not started");
        require(block.timestamp <= donationEndTime, "Donation period end");
        _;
    }

    /**
     * 用户向合约发送以太币，并记录捐赠信息
     * 使用 payable 修饰符接收以太币
     */
    function donate() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _usersMoney[msg.sender] += msg.value;
        Donated(msg.sender, msg.value, block.timestamp);
    }

    /**
     * 合约所有者提取所有资金
     */
    function withdraw () external onlyOwner {
        // 获取合约余额
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // 将合约余额转账给所有者
        (bool success) = _owner.call{value: balance}("");

        // 方式1：transfer (2300 gas限制，不推荐)
        // _owner.transfer(balance);
        // // 问题：固定2300 gas，可能不够复杂合约接收

        // // 方式2：send (2300 gas限制，不推荐)
        // bool success = _owner.send(balance);
        // // 问题：同样有gas限制

        // // 方式3：call (推荐，forward all gas)
        // (bool success, ) = _owner.call{value: balance}("");
        // // 优点：转发所有剩余gas，更安全
        // // 缺点：需要检查success返回值

        // // 方式4：call with data
        // (bool success, ) = _owner.call{value: balance}(
        //     abi.encodeWithSignature("receivePayment()")
        // );
        // // 可以同时调用接收者的函数
        require(success, "Transfer failed");
       
        emit Withdraw(_owner, balance, block.timestamp);
    }

    /**
     * 查询某个地址的捐赠金额
     */
    function getDonation (address target) public view returns(uint256) {
        return _usersMoney[target];
    }

    /**
     * 获取捐赠排行榜（前N名）
     */
    function getTopDonors(uint256 topN) external view returns(Donor[] memory) {
        require(topN > 0, "topN must be between 1 and 10");

        // 获取所有捐赠者记录的地址
        address[] memory donors = new address[](100);
        uint256 donorCount = 0;

        Donor[] memory topDonors = new Donor[](topN);

        return topDonors;
    }

    /**
     *获取合约所有者地址
    */

    function getOwner() external view returns(address) {
        return _owner;
    }

    /**
     *
     */
    function getContractBanlance() external view returns(uint256) {
        return address(this).balance;
    }

    /**
     * 获取捐赠时间段信息
     */
    function getDonationPeriod() external view returns(uint256 start, uint256 end) {
        return (donationStartTime, donationEndTime);
    }

    // 接收以太币的回退函数
    receive() external payable {
        totalReceived += msg.value;
        _usersMoney[msg.sender] += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    fallback() external payable {
        revert("Use donate() function");
    }

}