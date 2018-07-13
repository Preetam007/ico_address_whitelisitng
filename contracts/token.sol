pragma solidity ^0.4.21;


contract ERC20 {
 // modifiers

 // mitigate short address attack
 // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
 // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    uint256 public totalSupply;
    /*
      *  Public functions
      */
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    /*
      *  Events
      */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event SaleContractActivation(address saleContract, uint256 tokensForSale);
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  // it is recommended to define functions which can neither read the state of blockchain nor write in it as pure instead of constant

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

  /// @dev Returns number of tokens owned by given address
  /// @param _owner Address of token owner
  /// @return Balance of owner

    // it is recommended to define functions which can read the state of blockchain but cannot write in it as view instead of constant

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

  /// @dev Transfers sender's tokens to a given address. Returns success
  /// @param _to Address of token receiver
  /// @param _value Number of tokens to transfer
  /// @return Was transfer successful?

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value); // solhint-disable-line
            return true;
        } else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param _from Address from where tokens are withdrawn
    /// @param _to Address to where tokens are sent
    /// @param _value Number of tokens to transfer
    /// @return Was transfer successful?

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); // solhint-disable-line
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        require(_value == 0 && (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // solhint-disable-line
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue); // solhint-disable-line
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

 /**
  * @dev Burns a specific amount of tokens.
  * @param _value The amount of token to be burned.
  */
    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value); // solhint-disable-line
        return true;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    address public owner;
    address public creater;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable(address _owner) public {
        creater = msg.sender;
        if (_owner != 0) {
            owner = _owner;

        } else {
            owner = creater;
        }

    }
    /**
    * @dev Throws if called by any account other than the owner.
    */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creater);
        _;
    }

   

}



contract TravelHelperToken is StandardToken, Ownable {

//Begin: state variables
    address public saleContract;
    string public constant name = "TravelHelperToken";
    string public constant symbol = "TRH";
    uint public constant decimals = 18;
    bool public fundraising = true;
    uint public totalReleased = 0;
    address public teamAddressOne;
    address public teamAddressTwo;
    address public advisorsAddress;
    address public marketingTeamAddress;
    uint public icoStartTime;
    uint256 vestingPeriod = 18921600; //182 days + 30 days crowdsale+ 7 days presale
    uint256 tokensUnlockPeriod = 3196800; // 7 days presale + 30 days crowdsale
    uint public tokensSupply = 5000000000;
    uint public teamTokens = 1500000000 * 1 ether;
    uint public marketingTeamTokens = 500000000 * 1 ether; 
    uint public advisorsTokens = 350000000 * 1 ether;
    uint public bountyTokens = 150000000 * 1 ether;
    uint public releasedTeamTokens = 0;
    uint public releasedAdvisorsTokens = 0;
    uint public releasedMarketingTokens = 0;
    bool tokensLocked = true;
    Ownable public ownable;
    uint public tokensForSale = 2500000000 * 1 ether;

    mapping (address => bool) public frozenAccounts;
    mapping(bytes32=>bool) validIds;
 //End: state variables
 //Begin: events
    event FrozenFund(address target, bool frozen);
    event PriceLog(string text);
//End: events

//Begin: modifiers


    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        }
        else {
            require(fundraising == false);
            _;
        }
    }
    
    modifier tokenNotLocked() {
        if (icoStartTime > 0 && now.sub(icoStartTime) > tokensUnlockPeriod) {
            tokensLocked = false;
        } else {
            revert();
        }
    
        _;
    }

//End: modifiers

//Begin: constructor
    function TravelHelperToken(
    address _tokensOwner,
    address _teamAddressOne,
    address _teamAddressTwo,
    address _marketingTeamAddress,
    address _advisorsAddress) public Ownable(_tokensOwner) {
        require(_tokensOwner != 0x0);
        require(_teamAddressOne != 0x0);
        require(_teamAddressTwo != 0x0);
        require(_marketingTeamAddress != 0x0);
        require(_advisorsAddress != 0x0);
        teamAddressOne = _teamAddressOne;
        teamAddressTwo = _teamAddressTwo;
        marketingTeamAddress = _marketingTeamAddress;
        advisorsAddress = _advisorsAddress;
        totalSupply = tokensSupply * (uint256(10) ** decimals);
        balances[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);

    }


//End: constructor

    

//Begin: overriden methods

    function transfer(address _to, uint256 _value) public manageTransfer onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        manageTransfer
        onlyPayloadSize(3) returns (bool success)
    {
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transferFrom(_from, _to, _value);

    }


//End: overriden methods


//Being: setters
   
    function activateSaleContract(address _saleContract) public onlyOwner {
        require(_saleContract != address(0));
        saleContract = _saleContract;
        balances[saleContract] = balances[saleContract].add(tokensForSale);
        totalReleased = totalReleased.add(tokensForSale);
        icoStartTime = now;
        transferOwnership(_saleContract);
        assert(totalReleased <= totalSupply);
        emit Transfer(address(this), saleContract, totalReleased);
        emit SaleContractActivation(saleContract, totalReleased);
    }
   
    function burn() public onlyOwner returns (bool burnSuccess) {
        require(fundraising == false);
        uint _value = totalSupply.sub(totalReleased);
        return super.burn(_value);
    }
    
   
    function vestingStage() public view returns (uint) {
        if (icoStartTime == 0)
            return 0;

        if (now.sub(icoStartTime) > tokensUnlockPeriod && now.sub(icoStartTime) < vestingPeriod ) {
            return 1; //stage 1 after 30 days
        }
        else if (now.sub(icoStartTime) > vestingPeriod) {
            return 2; // stage two after 6 months
        }
    }
   
   function releaseTeamTokens() tokenNotLocked public returns (bool) {
        require(teamTokens > 0);
        require(totalReleased < totalSupply);
       
    
        if (vestingStage() == 1 && releasedTeamTokens  == 0) {
            uint totalValue = teamTokens.mul(50).div(100);
            uint eachTeamValue = totalValue.mul(50).div(100);
            balances[teamAddressOne] = balances[teamAddressOne].add(eachTeamValue);
            balances[teamAddressTwo] = balances[teamAddressTwo].add(eachTeamValue);
            releasedTeamTokens = releasedTeamTokens.add(totalValue);
            teamTokens = teamTokens.sub(totalValue);
            totalReleased = totalReleased.add(totalValue);
            return true;
        }
        else if (vestingStage() == 2) {
            uint finalValue = teamTokens;
            uint finaleachTeamValue = finalValue.mul(50).div(100);
            balances[teamAddressOne] = balances[teamAddressOne].add(finaleachTeamValue);
            balances[teamAddressTwo] = balances[teamAddressTwo].add(finaleachTeamValue);
            teamTokens = 0;
            releasedTeamTokens = releasedTeamTokens.add(finalValue);
            totalReleased = totalReleased.add(finalValue);
            
            return true;
            
        }
       
        return false;
    }
   
    function releaseAdvisorsTokens() tokenNotLocked public {
        require(totalReleased < totalSupply);
        require(advisorsTokens > 0);
        balances[advisorsAddress] = balances[advisorsAddress].add(advisorsTokens);
        totalReleased = totalReleased.add(advisorsTokens);
        releasedAdvisorsTokens = advisorsTokens;
        advisorsTokens = 0;
       
    }
     function releaseMarketingTokens() public tokenNotLocked {
        require(totalReleased < totalSupply);
        require(marketingTeamTokens > 0);
        balances[marketingTeamAddress] = balances[marketingTeamAddress].add(marketingTeamTokens);
        totalReleased = totalReleased.add(marketingTeamTokens);
        releasedMarketingTokens = marketingTeamTokens;
        marketingTeamTokens = 0;
        
    }

    function finalize() public  onlyOwner {
        require(fundraising != false);
        // Switch to Operational state. This is the only place this can happen.
        fundraising = false;
    }

    function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        require(freeze == (true || false));
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze); // solhint-disable-line
    }
    
    function sendBounty(address _to, uint256 _value) public onlyOwner returns (bool) {
        uint256 value = _value.mul(1 ether);
        require(bountyTokens >= value);
        totalReleased = totalReleased.add(value);
        require(totalReleased <= totalSupply);
        balances[_to] = balances[_to].add(value);
        bountyTokens = bountyTokens.sub(value);
        emit Transfer(address(this), _to, value);
        return true;
    }
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner); // solhint-disable-line
        owner = newOwner;
    }

//End: setters
   
    function() public {
        revert();
    }

}
