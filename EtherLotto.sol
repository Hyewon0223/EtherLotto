// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.4.11;
contract EtherLotto {
	// 투자자 구조체
	struct Player {
		address payable addr;	// 투자자의 어드레스
		uint amount;	        // 투자액
		uint nums;
	}
	
	address payable public owner;		// 컨트랙트 소유자
	uint public numInvestors;	// 투자자 수
	uint public deadline;		// 마감일 (UnixTime)
	string public status;		// 모금활동 상태
	bool public ended;			// 모금 종료여부
	uint public goalAmount  = 30000000000000000000;		// 목표액
	uint public totalAmount;	// 총 투자액
    mapping (uint => Player) public players;	// 투자자 관리를 위한 매핑

	// 당첨자 정보
	address payable[] public winnerAddress;
	uint public numWinner;      // 당첨자 수
    uint public winningNum = 1; // 당첨 번호
    uint public randNum;
	
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}
	
	/// 생성자
	constructor(uint _duration) {
		owner = msg.sender;

		// 마감일 설정 (Unixtime)
		deadline = block.timestamp + _duration;

		status = "Buying";
		ended = false;

		numInvestors = 0;
		totalAmount = 0;
		numWinner = 0;  //test
	}
	
	/// 투자 시에 호출되는 함수
	function fund() payable public{
		// 모금이 끝났다면 처리 중단
		require(!ended);
		require(msg.value == 10 ether, "Just Pay 10 ETH"); // 10이더 이상일 때만 송금
		Player storage play = players[numInvestors++];
		play.addr = msg.sender;
		play.amount = msg.value;
		play.nums = 1; // JS에서 받아와야 함
		totalAmount += play.amount;
		
	}
	
	/// 조회하기
	function getMyNum (address InputAddress) public view returns(uint){
	    for (uint i=0;i<numInvestors;i++){
	        if (players[i].addr == InputAddress)
	            return players[i].nums;
	    }
	}
	
	/// 목표액 달성 여부 확인
	/// 그리고 모금 성공/실패 여부에 따라 송금
	function checkGoalReached () payable public onlyOwner {
		// 모금이 끝났다면 처리 중단
		require(!ended);
		
		// 마감이 지나지 않았다면 처리 중단
		require(block.timestamp >= deadline);
		
		if(goalAmount <= totalAmount) {	// 모금 성공인 경우
			status = "Succeeded";
			// 컨트랙트 소유자에게 컨트랙트에 있는 모든 이더를 송금
	        ended = true;
            randNum = generateRandomNumber();	// 난수 생성
            
            for(uint i=0; i<numInvestors; i++){
                if(winningNum == players[i].nums){
                   winnerAddress.push(players[i].addr);
                   numWinner++;
                }
            }
            shareMoney();
            // winner.transfer(address(this).balance); // winner가 1명일때 송금
            //players = new address players [](0); // 초기화
            
    //         for (uint j=0;j<numWinner;j++) {
				// if(!winnerAddress[j].send(10 ether)) {
				// 	revert();
			 //   }
			    
	   //     }
		} else {	// 모금 실패인 경우
			uint i = 0;
			status = "Failed";
			ended = true;
			
			// 각 투자자에게 투자금을 돌려줌
			while(i <= numInvestors) {
				if(!players[i].addr.send(players[i].amount)) {
					revert();
				}
				i++;
			}
		}
	}
	
	function shareMoney() payable public {
	    for (uint j=0;j<numWinner;j++) {
    		if(!winnerAddress[j].send(totalAmount/numWinner)) {
    			revert();
    	    }
	    }
	}
	
	/// 컨트랙트를 소멸시키기 위한 함수
	function kill() public onlyOwner {
		selfdestruct(owner);
	}
	
	function getBalance() view public returns(uint){
	    return address(this).balance;
	}
	
	// 당첨 숫자 뽑기
	function generateRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, numInvestors)));
    }
	
	function pickWinner() public onlyOwner {

    }
	
}
