pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    function transfer(address receiver, uint amount) external;

    function burn(uint256 _value) external;
}

contract SEMCrowdsale is Ownable {

    using SafeMath for uint256;

    address public beneficiary;
    uint public tokenSold;
    uint public price;
    Token public token;
    uint public deadline;
    uint public numberOfICO;
    mapping(address => uint256) public balanceOf;
    uint8 public minToken;

    bool fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event BuyTokens(address buyer, uint amount);
    event FundTransfer(address backer, uint amount, bool isContribution);

    constructor(
        address _beneficiary,
        uint countOfIco,
        address addressOfToken
    ) public {
        beneficiary = _beneficiary;
        token = Token(addressOfToken);
        numberOfICO = countOfIco;
    }

    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    modifier afterEndOfAllPeriod() {
        require(numberOfICO == 0);
        _;
    }

    function startICO(uint durationInDays, uint weiCostOfEachToken, uint8 _minToken) public onlyOwner afterDeadline {
        require(durationInDays > 0);
        require(numberOfICO > 0);
        deadline = now + durationInDays * 1 days;
        price = weiCostOfEachToken.mul(1 wei);
        minToken = _minToken;
        numberOfICO = numberOfICO.sub(1);
    }

    function buyTokens() public payable returns (uint256) {
        uint256 tokens = _buyTokens(msg.sender, msg.value);
        return tokens;
    }

    function _buyTokens(address _sender, uint256 _amount) internal returns (uint256) {
        require(!crowdsaleClosed);
        require(now <= deadline);
        uint256 tokenAmount = _amount.div(price).mul(10 ** uint256(0));
        require(tokenAmount >= minToken);
        balanceOf[_sender] = balanceOf[_sender].add(_amount);
        tokenSold = tokenSold.add(_amount);
        token.transfer(_sender, tokenAmount);
        sendToBeneficiary(_amount);
        emit BuyTokens(msg.sender, tokenAmount);
        emit FundTransfer(msg.sender, tokenAmount, true);
        return tokenAmount;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */

    function() payable public {
        _buyTokens(msg.sender, msg.value);
    }

    function sendToBeneficiary(uint256 _amount) internal {
        if (beneficiary.send(_amount)) {
            emit FundTransfer(beneficiary, _amount, false);
        }
    }

    function isPeriodClosed() public view returns (bool) {
        if (now >= deadline) {
            return true;
        } else {
            return false;
        }
    }
}