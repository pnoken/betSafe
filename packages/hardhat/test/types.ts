export type BettingContractInstance = {
  methods: {
    createGame: (description: string) => any;
    placeBet: (gameId: number, betOption: number, options?: any) => any;
    closeGame: (gameId: number) => any;
    // Add typings for other contract methods here
  };
  events: {
    NewGame: (options?: any) => any;
    NewBet: (options?: any) => any;
    GameClosed: (options?: any) => any;
    BetStateChanged: (options?: any) => any;
    WinningsDistributed: (options?: any) => any;
    // Add typings for contract events here
  };
};
