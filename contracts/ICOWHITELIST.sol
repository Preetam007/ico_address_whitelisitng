pragma solidity ^0.4.21;


contract ICOWHITELIST {
    // Address which will receive raised funds
    address public contractOwner;


    // adreess vs state mapping (1 for exists , zero default);
    mapping (address=>bool) public whitelistedInvestors;
    uint256 public whitelistedInvestorsCount;

    /// modifiers
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    
    // constructor function 
    function ICOWHITELIST() public {
        contractOwner = msg.sender;
    }

    // whitelist function
    function whiteListAddresses(address[] _investors) external {
        uint i = 0;
        uint arrayLength = _investors.length;

        for (i; i < arrayLength; i++) {
            if (whitelistedInvestors[_investors[i]] == false) {
                whitelistedInvestors[_investors[i]] = true;
                whitelistedInvestorsCount++;
            }
            
        }
    }
}
