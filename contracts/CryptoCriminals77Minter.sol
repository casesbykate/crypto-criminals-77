pragma solidity ^0.5.6;

import "./klaytn-contracts/token/KIP17/KIP17Full.sol";
import "./klaytn-contracts/ownership/Ownable.sol";
import "./interfaces/IMix.sol";
import "./CryptoCriminals77.sol";

contract CryptoCriminals77Minter is Ownable {

    CryptoCriminals77 public nft;
    KIP17Full public cbk;

    IMix public mix;
    address public signer;
    uint256 public tryPrice = 1 * 1e18;

    mapping(uint256 => uint256[]) public cases;
    mapping(uint256 => bool) public usedCases;
    mapping(string => address) public triedKeys;

    constructor(CryptoCriminals77 _nft, KIP17Full _cbk, IMix _mix, address _signer) public {
        nft = _nft;
        cbk = _cbk;
        mix = _mix;
        signer = _signer;
    }

    function setSigner(address _signer) onlyOwner external {
        signer = _signer;
    }

    function setTryPrice(uint256 _price) external onlyOwner {
        tryPrice = _price;
    }

    function tryMint(string memory key, uint256[] memory _cases) public {
        require(_cases.length == 7);
        for (uint256 i = 0; i < 7; i += 1) {
            require(usedCases[_cases[i]] != true);
            require(cbk.ownerOf(_cases[i]) == msg.sender);
        }
        triedKeys[key] = msg.sender;
        mix.burnFrom(msg.sender, tryPrice);
    }

    function mint(address to, uint256 id, uint256[] memory _cases, string memory key, bytes memory signature) public {

        require(_cases.length == 7);
        require(triedKeys[key] == to);

        bytes32 hash = keccak256(abi.encodePacked(to, id,
            _cases[0],
            _cases[1],
            _cases[2],
            _cases[3],
            _cases[4],
            _cases[5],
            _cases[6],
            key
        ));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid signature 's' value"
        );
        require(v == 27 || v == 28, "invalid signature 'v' value");

        require(ecrecover(message, v, r, s) == signer);

        for (uint256 i = 0; i < 7; i += 1) {
            require(usedCases[_cases[i]] != true);
            require(cbk.ownerOf(_cases[i]) == to);
            usedCases[_cases[i]] = true;
        }

        nft.mint(id, to, 1);
    }
}
