// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;



contract DungeonsAndDragons {
    struct Character {
        string name;
        uint256 level;
        uint256 experience;
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
    }

    struct Dungeon {
        string name;
        uint256 difficulty;
        uint256 reward;
    }

    struct Monster {
        string name;
        uint256 health;
        uint256 attack;
    }

    struct Raid {
        string name;
        uint256 requiredLevel;
        uint256 reward;
    }

    mapping(address => Character) public characters;
    Dungeon[] public dungeons;
    Monster[] public monsters;
    Raid[] public raids;
    string public salt;
    uint256 public initialReward;
    uint256 public initialLevel;
    address public owner;
    
    event CharacterCreated(address indexed player, string name);
    event DungeonCompleted(address indexed player, string dungeonName, uint256 reward);
    event RaidCompleted(address indexed player, string raidName, uint256 reward);
    event MonsterDefeated(address indexed player, string monsterName);
    event FinalDragonDefeated(address indexed player);

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyCreator() {
        require(msg.sender == owner, "Only the creator can call this function");
        _;
    }
    
    bool private locked;

    constructor(string memory _salt, uint256 _initialReward, uint256 _initialLevel) payable {
        require(msg.value == 100 ether, "Contract must be funded with 100 Ether");
        salt = _salt;
        initialReward = _initialReward;
        initialLevel = _initialLevel;
        owner = msg.sender;
    }

    fallback() external payable {}

    function createCharacter(string memory _name, uint256 _class) public payable {
        require(msg.value == 0.1 ether, "Must pay 0.1 ether to create a character");
        require(bytes(characters[msg.sender].name).length == 0, "Character already exists");
        
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;

        if (_class == 1) { // Warrior
            strength = 10;
            dexterity = 5;
            intelligence = 2;
        } else if (_class == 2) { // Rogue
            strength = 5;
            dexterity = 10;
            intelligence = 3;
        } else if (_class == 3) { // Mage
            strength = 2;
            dexterity = 3;
            intelligence = 10;
        }

        characters[msg.sender] = Character(_name, initialLevel, 0, strength, dexterity, intelligence);
        emit CharacterCreated(msg.sender, _name);
    }

    function createDungeon(string memory _name, uint256 _difficulty, uint256 _reward) public onlyCreator {
        dungeons.push(Dungeon(_name, _difficulty, _reward));
    }

    function createMonster(string memory _name, uint256 _health, uint256 _attack) public {
        monsters.push(Monster(_name, _health, _attack));
    }

    function createRaid(string memory _name, uint256 _requiredLevel, uint256 _reward) public onlyCreator {
        raids.push(Raid(_name, _requiredLevel, _reward));
    }

    function completeDungeon(uint256 _dungeonIndex) public nonReentrant {
        require(_dungeonIndex < dungeons.length, "Invalid dungeon index");
        Dungeon memory dungeon = dungeons[_dungeonIndex];
        Character storage character = characters[msg.sender];

        require(character.level >= dungeon.difficulty, "Character level too low");

        character.experience += dungeon.reward;
        character.level++;
        character.experience = 0;

        emit DungeonCompleted(msg.sender, dungeon.name, dungeon.reward);
    }

    function completeRaid(uint256 _raidIndex) public nonReentrant {
        require(_raidIndex < raids.length, "Invalid raid index");
        Raid memory raid = raids[_raidIndex];
        Character storage character = characters[msg.sender];

        require(character.level >= raid.requiredLevel, "Character level too low");

        character.experience += raid.reward;
        character.level++;
        character.experience = 0;

        emit RaidCompleted(msg.sender, raid.name, raid.reward);
    }

    function fightMonster(uint256 _monsterIndex) public nonReentrant {
        require(_monsterIndex < monsters.length, "Invalid monster index");
        Monster memory monster = monsters[_monsterIndex];
        Character storage character = characters[msg.sender];

        uint256 fateScore = uint256(keccak256(abi.encodePacked(msg.sender, salt, uint256(42)))) % 100;
        
        require(fateScore > 30, "Monster fight failed! Bad luck!");

        if (character.strength + character.dexterity + character.intelligence > monster.health + monster.attack) {
            emit MonsterDefeated(msg.sender, monster.name);
            character.experience += 50;
            character.level++;
            character.experience = 0;
        } else {
            revert("Monster too strong! Failed to defeat");
        }
    }

    function finalDragon() public nonReentrant {
        Character storage character = characters[msg.sender];
        require(character.level >= 20, "Character level too low to fight the final dragon");

        uint256 fateScore = uint256(keccak256(abi.encodePacked(msg.sender, salt, uint256(999)))) % 100;
       

        if (fateScore > 50) {
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "Reward transfer failed");
            emit FinalDragonDefeated(msg.sender);
        }
    }

    function withdraw() public onlyCreator {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function getCharacter(address _player) public view returns (Character memory) {
        return characters[_player];
    }

    function distributeRewards(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public {
        address signer = ecrecover(messageHash, v, r, s);
        require(signer == owner, "Invalid signature");

        //distribute rewards logic
        Character storage character = characters[msg.sender];
        character.experience += 10;  
    }
}
