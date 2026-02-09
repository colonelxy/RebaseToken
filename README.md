# Cross-chain rebase token
1. Create a protocol that allows users to deposit into a vault and in return receive a token representing thair underlying balance.
2. Rebase token -> balanceOf function is dynamic to show the changing value with time.
   - Balance increases liearly with time
   - mint tokens to our users each time they perform an action like transfering, minting, burning or bridging.
3. Interest rates
   - Individually set the rates for each user based on a global rate at the time the user deposits into the vault.
   - The global interest rate can only decrease to incentivise/ reward early adopters.