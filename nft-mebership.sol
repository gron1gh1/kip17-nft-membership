pragma solidity >=0.4.24 <=0.5.6;


contract NFT_Membership {
    struct Membership {
        string value; 
        uint256 expirationDate;
    }

    address private contractOwner;
    // 소유한 토큰 리스트
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => Membership) public tokenMembership;
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    // mint(tokenId, uri, owner)
    // transferFrom(from, to, tokenId) -> owner가 바뀌는 것(from -> to)

    constructor() public {
        contractOwner = msg.sender;
    }

    function mint(
        address to,
        uint256 tokenId
    ) private returns (bool) {
        require(contractOwner == msg.sender, "컨트랙트를 배포한 사람만 민팅이 가능합니다.");
        // to에게 tokenId(일련번호)를 발행하겠다.
        // 적힐 글자는 tokenURI
        tokenOwner[tokenId] = to;
        return true;
    }
    
    
    function mintWithMembership(
        address to,
        uint256 tokenId,
        string memory value,
        uint256 expirationDate
    ) public {
        require(contractOwner == msg.sender, "컨트랙트를 배포한 사람만 민팅이 가능합니다.");
        tokenMembership[tokenId] = Membership(value,expirationDate);
        mint(to,tokenId);
    }

    function burn(uint256 tokenId) public {
        require(contractOwner == msg.sender, "컨트랙트를 배포한 사람만 소각이 가능합니다.");
        delete tokenOwner[tokenId];
        delete tokenMembership[tokenId];
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(
            from == tokenOwner[tokenId],
            "해당 토큰을 소지한 사람만 전송이 가능합니다."
        );
        tokenOwner[tokenId] = to;
        require(
            _checkOnKIP17Received(from, to, tokenId, _data),
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
