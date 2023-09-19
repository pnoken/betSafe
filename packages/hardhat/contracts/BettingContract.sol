pragma solidity ^0.8.0;

contract BettingContract {
	enum BetState {
		PENDING,
		WON,
		LOST
	}

	struct Bet {
		address user;
		uint256 amount;
		uint256 gameID;
		uint256 betOption;
		BetState state;
	}

	struct Game {
		string description;
		bool isOpen;
		uint256[] bets;
		uint256 totalFunds; // Added totalFunds to track game balance
		BetState state; // Added state to track game state
		uint256 numBets; // Added numBets to track the number of bets
	}

	Game[] public games;
	mapping(uint256 => mapping(uint256 => Bet)) public bets;
	uint256 public numGames;
	mapping(uint256 => uint256[]) public winningBets; // Added winningBets mapping

	event NewGame(string description);
	event NewBet(uint256 gameID, uint256 betOption);
	event GameClosed(uint256 gameID);
	event BetStateChanged(uint256 gameID, uint256 betOption, BetState newState);
	event WinningsDistributed(
		uint256 gameID,
		uint256[] winningBets,
		uint256 totalWinnings
	);

	constructor() {
		numGames = 0;
	}

	modifier onlyOwner() {
		require(msg.sender == owner());
		_;
	}

	function owner() public view returns (address) {
		return address(this); // Changed payable(address(this)) to address(this)
	}

	function createGame(string memory _description) public onlyOwner {
		games.push(
			Game(_description, true, new uint256[](0), 0, BetState.PENDING, 0)
		);
		numGames++;
		emit NewGame(_description);
	}

	function placeBet(uint256 _gameId, uint256 _betOption) public payable {
		require(_gameId < numGames, "Invalid game ID");
		Game storage game = games[_gameId];
		require(game.isOpen, "Game is not open");
		require(msg.value > 0, "Bet amount must be greater than 0");
		Bet storage bet = bets[_gameId][game.numBets]; // Changed game.bets.length to game.numBets
		bet.user = msg.sender;
		bet.amount = msg.value;
		bet.gameID = _gameId;
		bet.betOption = _betOption;
		bet.state = BetState.PENDING;
		game.bets.push(game.numBets); // Changed game.bets.length to game.numBets
		game.totalFunds += msg.value; // Increment game balance
		game.numBets++; // Increment the number of bets
		emit NewBet(_gameId, _betOption);
	}

	function closeGame(uint256 _gameId) public onlyOwner {
		require(_gameId < numGames, "Invalid game ID");
		Game storage game = games[_gameId];
		require(game.isOpen, "Game is already closed");
		game.isOpen = false;
		emit GameClosed(_gameId);
	}

	function removeBet(uint256 _gameId) public {
		require(_gameId < numGames, "Invalid game ID");
		Game storage game = games[_gameId];
		require(game.isOpen, "Game is not open");
		uint256[] storage betsForGame = game.bets;
		for (uint256 i = 0; i < betsForGame.length; i++) {
			Bet storage bet = bets[_gameId][betsForGame[i]];
			if (bet.user == msg.sender) {
				payable(msg.sender).transfer(bet.amount);
				emit BetStateChanged(_gameId, bet.betOption, BetState.LOST);
				delete bets[_gameId][betsForGame[i]];
				betsForGame[i] = betsForGame[betsForGame.length - 1];
				betsForGame.pop();
				game.numBets--; // Decrement the number of bets
				break;
			}
		}
	}

	function declareWinners(
		uint256 _gameId,
		uint256[] memory _winningBets
	) public onlyOwner {
		require(
			games[_gameId].state == BetState.LOST,
			"Game is not yet closed"
		);
		require(
			winningBets[_gameId].length == 0,
			"Winning bets have already been declared for this game"
		);
		require(
			_winningBets.length > 0,
			"At least one winning bet must be provided"
		);
		require(
			_winningBets.length <= games[_gameId].numBets,
			"Invalid number of winning bets provided"
		);

		// Mark winning bets
		for (uint i = 0; i < _winningBets.length; i++) {
			uint256 betId = _winningBets[i];
			Bet storage bet = bets[_gameId][betId];
			require(
				bet.state == BetState.PENDING,
				"Bet is already declared as a winner or loser"
			);
			bet.state = BetState.WON;
		}

		// Store winning bets
		winningBets[_gameId] = _winningBets;

		// Update game state to "WAITING_FOR_WINNERS"
		games[_gameId].state = BetState.WON;
	}

	function distributeWinnings(uint256 _gameId) public onlyOwner {
		require(
			games[_gameId].state == BetState.WON,
			"Game is not waiting for winners"
		);

		uint256 totalFunds = games[_gameId].totalFunds;
		uint256 numWinningBets = winningBets[_gameId].length;
		uint256 winningsPerBet = totalFunds / numWinningBets;

		for (uint i = 0; i < numWinningBets; i++) {
			uint256 betId = winningBets[_gameId][i];
			Bet storage bet = bets[_gameId][betId];
			require(bet.state == BetState.WON, "Bet is not a winning bet");
			payable(bet.user).transfer(winningsPerBet);
			emit BetStateChanged(_gameId, bet.betOption, BetState.WON);
			delete bets[_gameId][betId];
		}

		// Update game state to "WINNERS_DECLARED"
		games[_gameId].state = BetState.WON;
	}
}
