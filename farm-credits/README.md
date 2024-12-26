# CarbonCrop Protocol - Sustainable Farming Carbon Credits

A decentralized smart contract system built on Stacks blockchain that enables farmers to earn tokens for their sustainable farming practices through verified environmental improvements.

## Core Features

### Farm Verification System
- Verified inspector registry
- Multi-metric environmental tracking:
  - Carbon sequestration
  - Water conservation
  - Chemical reduction
- Time-locked verification periods (30 days)
- Automated reward calculations

### Token Economics
- Dynamic minting based on verified improvements
- Precision: 6 decimal places
- Built-in transfer mechanisms
- Total supply tracking

### Marketplace
- Create token listings
- Set custom prices
- Built-in escrow system
- Active listing management
- Buyer/seller reputation tracking

## Contract Functions

### Administrative
```clarity
(define-public (register-inspector (inspector-principal principal))
```
- Registers authorized inspectors
- Only callable by contract owner
- Maximum 50 inspectors

### Verification
```clarity
(define-public (submit-verification
    (farm-id uint)
    (farm-owner principal)
    (carbon-score uint)
    (water-score uint)
    (chemical-reduction uint))
```
- Submit environmental metrics
- Calculates improvements
- Mints reward tokens
- Updates farm history

### Trading
```clarity
(define-public (create-listing (listing-id uint) (amount uint) (price-per-token uint))
(define-public (transfer (recipient principal) (amount uint))
(define-public (purchase-listing (listing-id uint) (amount uint))
```

### Data Queries
```clarity
(define-read-only (get-balance (user principal))
(define-read-only (get-farm-data (farm-id uint) (owner principal))
(define-read-only (get-listing (listing-id uint))
(define-read-only (get-reputation (user principal))
```

## Security Features

- Input validation on all parameters
- Time-locked verifications
- Inspector authorization
- Safe token transfer mechanics
- Protected administrative functions
- Prevention of self-transfers
- Reasonable limits on scores
- List size constraints

## Error Codes

```clarity
ERR_NOT_AUTHORIZED (err u100)
ERR_INVALID_AMOUNT (err u101)
ERR_INSUFFICIENT_BALANCE (err u102)
ERR_NOT_FOUND (err u103)
ERR_ALREADY_LISTED (err u104)
```

## Development Setup

1. Install Clarinet
```bash
curl -sL https://github.com/hirosystems/clarinet/releases/download/v1.5.4/clarinet-linux-x64-glibc.tar.gz -o clarinet.tar.gz
tar -xf clarinet.tar.gz
chmod +x ./clarinet
sudo mv ./clarinet /usr/local/bin
```

2. Initialize Project
```bash
clarinet new carbon-crop-protocol
cd carbon-crop-protocol
```

3. Deploy Contract
```bash
clarinet contract:deploy carbon-crop-core
```

## Usage Examples

### Register as Inspector
```clarity
;; Call as contract owner
(contract-call? .carbon-crop-core register-inspector tx-sender)
```

### Submit Verification
```clarity
;; Call as registered inspector
(contract-call? .carbon-crop-core submit-verification 
    u1          ;; farm-id
    tx-sender   ;; farm-owner
    u500        ;; carbon-score
    u300        ;; water-score
    u200)       ;; chemical-reduction
```

### Create Market Listing
```clarity
;; List 1000 tokens at 2 STX each
(contract-call? .carbon-crop-core create-listing u1 u1000 u2)
```

## Future Enhancements

1. Governance functionality
2. Advanced marketplace features
   - Batch transfers
   - Auction mechanisms
3. Integration with IoT devices
4. Enhanced verification metrics
5. Comprehensive test suite

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request