1. **Memefactory** (0x4319C5a837f21C6c79D5f6fcf3358495E16EaD81) (https://basescan.org/address/0x4319C5a837f21C6c79D5f6fcf3358495E16EaD81#code)
- This is the main contract that allows for the creation of tokens (memecoins). It should be the first one, as other contracts will likely depend on the tokens created by it.

2. **Whitelist Router** (0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661) (https://basescan.org/address/0x66E2fCcB63ff38F23A39A93B3BaaF3C33ee67661#code)
- This contract is used to manage the routers that will be allowed to apply sell fees. It is important to set it up before using any mechanism that depends on these fees.

3. **Treasury Contract**
- This contract is responsible for handling the platform's funds, including rewards and other income. It must be in place before staking or rewards contracts start operating, as they will likely interact with it.

4. **Staking Contract**
- This contract allows users to stake their memecoins. It should be deployed after the previous contracts, as it needs access to the tokens and possibly the treasury contract.

5. **Eggs Contract** (Staking Reward Token)
- This contract is for the reward token that is awarded to users for staking. It should be created after the staking contract, as it needs to interact with it to award the rewards.

6. **NFT Contract** (NFT Contract that rewards platform tokens)
- This contract creates NFTs that reward users with platform tokens. This contract can rely on staking or treasury contracts to award rewards.
