pragma solidity 0.8.0;

contract IKIP17 {
    mapping(uint256 => address) private tokenOwner;
    mapping(address => uint256) public ownerById;

    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    function _mint(
        address to,
        uint256 tokenId
    ) internal returns (bool) {
        tokenOwner[tokenId] = to;
        ownerById[to] = tokenId;
        return true;
    }
    
    function _burn(uint256 tokenId) internal {
        require(
            msg.sender == tokenOwner[tokenId],
            "You not token Owner"
        );
        delete ownerById[msg.sender];
        delete tokenOwner[tokenId];
    }



    function _safeTransferFrom(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        require(
            msg.sender == tokenOwner[tokenId],
            "You not token Owner"
        );
        tokenOwner[tokenId] = to;
        require(
            _checkOnKIP17Received(msg.sender, to, tokenId, _data),
            "KIP17: transfer to non KIP17Receiver implementer"
        );
    }

    function _checkOnKIP17Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bool success;
        bytes memory returndata;

        if (!isContract(to)) {
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP17_RECEIVED,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (
            returndata.length != 0 &&
            abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }

        return false;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract Membership is IKIP17 {
    struct Membership {
        string value; 
        uint256 expirationDate;
    }
    address private contractOwner;
    
    mapping(uint256 => Membership) public tokenMembership;

    constructor() public {
        contractOwner = msg.sender;
    }
    
    // mintWithMembership(발급할 주소, 토큰 아이디, 토큰 값, 현재시간 기준 달 설정)
    function mintWithMembership(
        address to,
        uint256 tokenId,
        string memory value,
        uint256 expirationMonth
    ) public {
        require(contractOwner == msg.sender, "You not admin"); //, "컨트랙트를 배포한 사람만 민팅이 가능합니다."
        tokenMembership[tokenId] = Membership(value, block.timestamp + expirationMonth * 30 days);
        _mint(to,tokenId);
    }

    function burn(uint256 tokenId) private {
        delete tokenMembership[tokenId];
        _burn(ownerById[msg.sender]);
    }


    function showMembership() public view returns (Membership memory)  {
        require(ownerById[msg.sender] != 0, "Not find Membership"); //, "소유한 회원권이 없습니다."
         require(block.timestamp <= tokenMembership[ownerById[msg.sender]].expirationDate, "This Membership End"); // , "회원권의 기간이 지났습니다."
        return tokenMembership[ownerById[msg.sender]];
    }
}
