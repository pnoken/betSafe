import { BettingContractInstance } from "./types"; // Import the generated contract typings
import { ethers } from "hardhat";
import { expect } from "chai";

const BettingContract = artifacts.require("BettingContract"); // Import the contract artifact

describe("BettingContract", (accounts) => {
  let betting: BettingContractInstance;

  beforeEach(async () => {
    betting = await BettingContract.deployed();
  });

  it("should create a game", async () => {
    const gameDescription = "Test Game";
    await betting.createGame(gameDescription);
    const gameCount = await betting.numGames();
    assert.equal(gameCount.toNumber(), 1, "Game count should be 1");
  });

  it("should place a bet", async () => {
    const gameId = 0;
    const betOption = 1;
    const betAmount = web3.utils.toWei("1", "ether");
    const initialBalance = await web3.eth.getBalance(accounts[0]);

    await betting.placeBet(gameId, betOption, { from: accounts[0], value: betAmount });

    const betCount = await betting.getGameBetCount(gameId);
    assert.equal(betCount.toNumber(), 1, "Bet count should be 1");

    const betState = await betting.getBetState(gameId, 0);
    assert.equal(betState.toNumber(), 0, "Bet should be in PENDING state");

    const gameBalance = await betting.getGameBalance(gameId);
    assert.equal(gameBalance.toString(), betAmount, "Game balance should be 1 ether");

    const userBalance = await web3.eth.getBalance(accounts[0]);
    assert.isTrue(
      userBalance.lt(initialBalance),
      "User balance should be reduced after placing a bet"
    );
  });

  it("should close a game", async () => {
    const gameId = 0;
    await betting.closeGame(gameId);
    const gameIsOpen = await betting.getGameIsOpen(gameId);
    assert.isFalse(gameIsOpen, "Game should be closed");
  });

  // Add more test cases for other contract functions here...
});
