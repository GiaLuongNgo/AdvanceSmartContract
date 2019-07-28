pragma solidity ^0.5.1;

import "github.com/oraclize/ethereum-api/provableAPI.sol";

contract CoinFlip is usingProvable {
    constructor() payable public {
        
    }
    uint public winner;
    mapping (uint => player) public players;
    uint public wager;
    struct player {
        uint id;
        address payable Address;
        uint Wager;
        uint timestamp;
    }
    
    uint coin;
    
    enum State {NOT_BEGIN ,DEPOSIT, TRANSFER}
    State public mode = State.NOT_BEGIN;
    
    modifier notBegan(){
        require(mode == State.NOT_BEGIN);
        _;
    }
    
    modifier isWagerMade(){
        require(mode == State.DEPOSIT);
        _;
    }
    
    modifier isWagerAccepted(){
        require(mode == State.TRANSFER);
        _;
    }
    
    modifier isWinner(){
        require(tx.origin == players[winner].Address);
        _;
    }
    
    function generateRandom() public payable  {
        provable_query("WolframAlpha", "random number between 1 and 2");
    }
    
    
    function startGame() notBegan public payable {
        require(msg.value > 0);
        players[1] = player(1,tx.origin, msg.value,now);
        wager = msg.value;
        mode = State.DEPOSIT;
    }
    
    function acceptGame() public payable isWagerMade{
        require(msg.value == wager && tx.origin != players[1].Address);
        players[2]= player(2,tx.origin,msg.value,now);
        generateRandom();
        mode=State.DEPOSIT;

    }
    
    function withdrawMoney() public isWinner{
        mode=State.TRANSFER;
        uint amount = players[winner].Wager;
        players[winner].Address.transfer(amount);
    }
    
}

contract Factory {
    uint public GameInstance;
    
    mapping (uint =>CoinFlip) public games;
    event newInstance(CoinFlip cf);
    
    function deployCoinFlip() public payable {
        GameInstance++;
        CoinFlip cf = new CoinFlip();
        games[GameInstance] = cf;
        emit newInstance(games[GameInstance]);
    }
    
    function getGameByID(uint _id) public view returns(CoinFlip){
        return games[_id];
    }
}

contract dashboard{
    Factory gameFa;
    
    constructor(address _gameFactory) public {
        gameFa = Factory(_gameFactory);
    }
    
    function createNewGame() public payable{
        gameFa.deployCoinFlip();
    }
    
    function beginById(uint _id) public payable {
        CoinFlip fg = CoinFlip(gameFa.getGameByID(_id));
        fg.startGame.value(msg.value)();
    }
    
    function acceptById(uint _id) public payable{
        CoinFlip flipGame = CoinFlip(gameFa.getGameByID(_id));
        flipGame.acceptGame.value(msg.value)();
    }
    
    function withdrawById(uint _id) public {
        CoinFlip flipGame = CoinFlip(gameFa.getGameByID(_id));
        flipGame.withdrawMoney();
    }
    
}
