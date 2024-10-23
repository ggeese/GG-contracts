# Contracts Overview

## MemeFactory Contract
- **Address:** [0x55f43C6f18C52a661D03E94f1FBE8693b974E7Dd](https://basescan.org/address/0x55f43C6f18C52a661D03E94f1FBE8693b974E7Dd#code)  
- **Description:** This is the primary contract responsible for creating tokens (memecoins). It allows users to deploy new meme-themed tokens.

---

## Whitelist Router Contract
- **Address:** [0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661](https://basescan.org/address/0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661#code)  
- **Description:** This contract manages the list of allowed routers that can apply sell fees on transactions. It ensures that only these routers are authorized to impose fees.

---

## Staking Contract (BRETT Example)
- **Address:** [0x5d10F4259b7a2229875DbDC362F72bb6F6327df6](https://basescan.org/address/0x5d10F4259b7a2229875DbDC362F72bb6F6327df6#code)  
- **Description:** This contract enables users to stake their memecoins and earn rewards in the form of "Eggs" tokens. It incentivizes long-term holding and active participation.

---

## Eggs Contract (Staking Reward Token)
- **Address:** [0x9Dc786346DD5693B299f6a42Be27eDb06C12649f](https://basescan.org/address/0x9Dc786346DD5693B299f6a42Be27eDb06C12649f#code)  
- **Description:** This contract issues the "Eggs" reward token to users who participate in staking. The "Eggs" token is non-transferable and can be used to exchange for rewards within the ecosystem.

---

## NFT Contract
- **Address:** [0x51D64232ef93Ca0509532509D055d853050e26A2](https://basescan.org/address/0x51D64232ef93Ca0509532509D055d853050e26A2#code)  
- **Description:** This contract is responsible for minting NFTs, allowing users to create unique digital collectibles as part of the platform's offerings.

---

## Vault Contract
- **Address:** [0xD9D78baa151F017857763996EDde44e56830A97e](https://basescan.org/address/0xD9D78baa151F017857763996EDde44e56830A97e#code)  
- **Description:** This contract stores the reward tokens allocated for users who mint NFTs. The Vault receives instructions from the NFT contract, which has authority over its operations.
