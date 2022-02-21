/* solium-disable security/no-block-members */

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;

    event Released(uint256 amount);
    event Revoked();

    address public beneficiaryA;
    address public beneficiaryB;
    address public beneficiaryC;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    address public tokenAddress;
    address public ownerAddress;

    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;    

    constructor(
        address _beneficiaryA,
        address _beneficiaryB,
        address _beneficiaryC,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable,
        address _token,
        address _owner
    )
    Ownable()
    public {
        require(_beneficiaryA != address(0));
        require(_beneficiaryB != address(0));
        require(_beneficiaryC != address(0));
        require(_cliff <= _duration);

        IERC20 token;
        tokenAddress = _token;
        token = IERC20(_token);
        ownerAddress = _owner;

        beneficiaryA = _beneficiaryA;
        beneficiaryB = _beneficiaryB;
        beneficiaryC = _beneficiaryC;

        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;   
    }
    function release(IERC20 token) public {

        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0);

        released[tokenAddress] = released[tokenAddress].add(unreleased);

        uint256 cut = unreleased / 3;

        token.transfer(beneficiaryA, cut);
        token.transfer(beneficiaryB, cut);
        token.transfer(beneficiaryC, cut);

        emit Released(unreleased);
    }

    function revoke(IERC20 token) public onlyOwner {
        require(revocable);
        require(!revoked[tokenAddress]);

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        revoked[tokenAddress] = true;

        token.transfer(ownerAddress, refund);

        emit Revoked();
    }
    function releasableAmount(IERC20 token) public view returns (uint256) {
        return vestedAmount(token).sub(released[address(token)]);
    }
    function vestedAmount(IERC20 token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[tokenAddress]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[tokenAddress]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
    function getTime () public view returns (uint256) {
        return block.timestamp;
    }

}