1. **Memefactory** (0x55f43C6f18C52a661D03E94f1FBE8693b974E7Dd) (https://basescan.org/address/0x55f43C6f18C52a661D03E94f1FBE8693b974E7Dd#code)
- This is the main contract that allows for the creation of tokens (memecoins). It should be the first one, as other contracts will likely depend on the tokens created by it.

2. **Whitelist Router** (0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661) (https://basescan.org/address/0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661#code)
- This contract is used to manage the routers that will be allowed to apply sell fees. It is important to set it up before using any mechanism that depends on these fees.

4. **Staking Contract**(0x5d10F4259b7a2229875DbDC362F72bb6F6327df6) (BRETT example)
- This contract allows users to stake their memecoins. It should be deployed after the previous contracts, as it needs access to the tokens and possibly the treasury contract.

5. **Eggs Contract** (Staking Reward Token) (0x9Dc786346DD5693B299f6a42Be27eDb06C12649f)
- This contract is for the reward token that is awarded to users for staking. It should be created after the staking contract, as it needs to interact with it to award the rewards.

6. **NFT Contract** (0x51D64232ef93Ca0509532509D055d853050e26A2)
- This contract creates NFTs that reward users with platform tokens. This contract can rely on staking or treasury contracts to award rewards.
- 
3. **Vaul Contract** (0xD9D78baa151F017857763996EDde44e56830A97e)
- This contract is responsible for handling the platform's funds, including rewards and other income. It must be in place before staking or rewards contracts start operating, as they will likely interact with it.
