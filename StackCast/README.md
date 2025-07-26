# StackCast 🔮

**Bitcoin-backed Prediction Markets on Stacks**

StackCast is a decentralized prediction market platform built on the Stacks blockchain, enabling users to bet on real-world outcomes using Bitcoin as collateral through STX tokens.

## 🚀 Features

- **Create Markets**: Anyone can create prediction markets on any topic
- **Binary Outcomes**: Simple YES/NO betting system
- **Bitcoin Security**: Leverages Bitcoin's security through Stacks
- **Automatic Payouts**: Smart contract handles all settlements
- **Dynamic Odds**: Market-driven pricing based on betting activity
- **Low Fees**: Only 2.5% platform fee on winnings
- **Transparent**: All market data and outcomes are on-chain

## 📋 How It Works

1. **Market Creation**: Users create prediction markets with a title, description, expiry block, and category
2. **Betting Phase**: Users place bets on YES or NO outcomes by locking STX tokens
3. **Market Resolution**: After expiry, the market creator resolves the outcome
4. **Claim Winnings**: Winners can claim their proportional share of the total pool

## 🛠 Smart Contract Functions

### Public Functions

- `create-market`: Create a new prediction market
- `place-bet`: Place a bet on YES (1) or NO (0) outcome
- `resolve-market`: Resolve market outcome (creator only)
- `claim-winnings`: Claim winnings from resolved markets

### Read-Only Functions

- `get-market`: Get market details by ID
- `get-user-position`: Get user's position in a market
- `get-market-odds`: Get current market odds
- `get-potential-payout`: Calculate potential winnings

## 💰 Payout Calculation

Winnings are calculated proportionally based on the winning pool:

```
User Payout = (User Bet Amount × Total Pool) / Winning Pool Size
```

Example:
- Total YES bets: 100 STX
- Total NO bets: 200 STX
- Your YES bet: 10 STX
- If YES wins: Your payout = (10 × 300) / 100 = 30 STX

## 🏗 Installation & Deployment

### Local Development

```bash
# Clone the repository
git clone https://github.com/ozgirl/stackcast
cd stackcast

# Install dependencies
clarinet integrate

# Run tests
clarinet test

# Deploy locally
clarinet deploy --devnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet
clarinet deploy --mainnet
```

## 🧪 Testing

The contract includes comprehensive tests covering:

- Market creation and expiry validation
- Bet placement and pool updates
- Market resolution and outcome validation
- Payout calculations and claiming
- Edge cases and error handling

```bash
clarinet test
```

## 📊 Market Categories

StackCast supports various prediction market categories:

- **Sports**: Game outcomes, championship winners
- **Politics**: Election results, policy decisions
- **Crypto**: Price predictions, protocol upgrades
- **Technology**: Product launches, adoption metrics
- **Weather**: Temperature, precipitation events
- **Entertainment**: Award shows, box office results

## 🔒 Security Features

- **Expiry Validation**: Markets cannot be bet on after expiry
- **Creator Authorization**: Only market creators can resolve outcomes
- **Double-Claim Protection**: Users cannot claim winnings twice
- **Input Validation**: All parameters are validated before execution
- **Reentrancy Protection**: Safe token transfers using try! macro

## 🎯 Roadmap

- [ ] Oracle integration for automatic resolution
- [ ] Multi-outcome markets (beyond binary)
- [ ] Market categories and filtering
- [ ] Reputation system for market creators
- [ ] Mobile app interface
- [ ] Advanced trading features (limit orders)
- [ ] Cross-chain betting support

## 🤝 Contributing

We welcome contributions! 
