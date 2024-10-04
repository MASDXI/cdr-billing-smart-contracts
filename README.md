# cdr-billing-smart-contracts

This repository provides Call Detail Records (CDRs) billing using smart contracts written in Solidity. It enables telecom operators and service providers to manage billing processes transparently and efficiently on a blockchain network, ensuring accurate, immutable, and automated.

## Prerequisite

- node [Download](https://nodejs.org/en/)
- nvm [Download](https://github.com/nvm-sh/nvm#installing-and-updating)
- git [Download](https://git-scm.com/)

```shell
git clone https://github.com/MASDXI/cdr-billing-smart-contracts.git
cd cdr-billing-smart-contracts
```

## Installing

To install all necessary packages and dependencies in the project, run command

```
yarn install
```

## Compile the code

To compile the smart contracts, run command

```
yarn compile
```

## Testing

To run the tests and ensure that the contracts behave as expected, run command

```
yarn test
```

## Rationale

- The design approach should not tied exclusively to Solidity or Ethereum but can be applied across various Distributed Ledger Technologies (DLTs) or blockchain frameworks that support Turing-complete smart contracts.
- Avoid `WRITE` or `UPDATE` operation with Sliding Window Algorithm for billing efficiently over a specified time period. This method helps in maintaining a consistent billing cycle by leveraging a sliding window mechanism that automatically accounts for time-based without needing constant manual updates.

## Security Consideration

- Current design when change blocktime total billing will be recalculate

---

## License

All Code within 'contracts' directory is Copyright (C) sirawt. All rights reserved.  
The `contracts` is released under the [GNU General Public License v3.0](LICENSE)
