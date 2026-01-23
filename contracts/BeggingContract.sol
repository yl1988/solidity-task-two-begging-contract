// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract BeggingContract {

    // 录每个捐赠者的捐赠金额
    mapping (address => uint256) private _usersMoney;

     // 排行榜功能
    struct Donor {
        address addr;
        uint256 amount;
    }
    
    Donor[3] private _top3;  // 固定维护前3名

    // 合约所有者
    address payable private _owner;

     // 捐赠开始和结束时间
    uint256 public donationStartTime;
    uint256 public donationEndTime;

    uint256 public totalReceived;

    event Donated(address indexed donor, uint256 money, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 money, uint256 timestamp);
    event LeaderboardUpdated(address[3] top3);

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
    function donate() external payable donationPerioActive {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _usersMoney[msg.sender] += msg.value;
         // 更新排行榜
        updateTop3(msg.sender, _usersMoney[msg.sender]);

        emit Donated(msg.sender, msg.value, block.timestamp);
    }

    /**
     * 更新前3
     */
    function updateTop3(address donor, uint256 newTotal) private {
            // 检查是否已在榜
            for (uint256 i = 0; i < 3; i++) {
                if (_top3[i].addr == donor) {
                    _top3[i].amount = newTotal;
                    sortTop3();
                    emitLeaderboard();
                    return;
                }
            }
            
            // 不在榜，尝试插入
            for (uint256 i = 0; i < 3; i++) {
                if (_top3[i].addr == address(0)) {
                    // 有空位
                    _top3[i] = Donor(donor, newTotal);
                    sortTop3();
                    emitLeaderboard();
                    return;
                }
                
                if (newTotal > _top3[i].amount) {
                    // 插入到位置i
                    for (uint256 j = 2; j > i; j--) {
                        _top3[j] = _top3[j-1];
                    }
                    _top3[i] = Donor(donor, newTotal);
                    emitLeaderboard();
                    return;
                }
            }
    }

    /**
     * 冒泡排序选出前3
     */
     function sortTop3() private {
        // 冒泡排序（只有3个元素）
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2 - i; j++) {
                if (_top3[j].amount < _top3[j+1].amount) {
                    Donor memory temp = _top3[j];
                    _top3[j] = _top3[j+1];
                    _top3[j+1] = temp;
                }
            }
        }
    }
    
    /**
     * 添加排序事件
     */
    function emitLeaderboard() private {
        address[3] memory top3Addrs;
        for (uint256 i = 0; i < 3; i++) {
            top3Addrs[i] = _top3[i].addr;
        }
        emit LeaderboardUpdated(top3Addrs);
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
     * 获取捐赠排行榜（前3名）
     */
    function getTopDonors() external view returns(Donor[] memory) {
       
        Donor[] memory result = new Donor[](3);
        for (uint256 i = 0; i < 3; i++) {
            result[i] = _top3[i];
        }
        return result;
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