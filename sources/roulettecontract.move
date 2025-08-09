module yash_addr::Roulette {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    
    /// Struct representing a roulette game
    struct RouletteGame has store, key {
        house_balance: u64,        // House balance for payouts
        total_bets: u64,          // Total amount of bets placed
        last_winning_number: u8,   // Last winning number (0-36)
    }
    
    /// Struct representing a player's bet
    struct PlayerBet has store, key {
        bet_amount: u64,          // Amount bet by player
        bet_type: u8,            // Type of bet: 1=red/black, 2=odd/even, 3=single number
        bet_value: u8,           // Specific bet value (0=red, 1=black for red/black bets)
        is_active: bool,         // Whether bet is active
    }
    
    /// Initialize the roulette game
    public fun create_roulette_game(owner: &signer, initial_house_balance: u64) {
        let game = RouletteGame {
            house_balance: initial_house_balance,
            total_bets: 0,
            last_winning_number: 0,
        };
        move_to(owner, game);
    }
    
    /// Place a bet on the roulette wheel
    public fun place_bet(
        player: &signer, 
        house_owner: address, 
        bet_amount: u64, 
        bet_type: u8, 
        bet_value: u8
    ) acquires RouletteGame, PlayerBet {
        let game = borrow_global_mut<RouletteGame>(house_owner);
        
        // Transfer bet amount from player to house
        let bet_coins = coin::withdraw<AptosCoin>(player, bet_amount);
        coin::deposit<AptosCoin>(house_owner, bet_coins);
        
        // Update game statistics
        game.total_bets = game.total_bets + bet_amount;
        
        // Create or update player bet
        let player_addr = signer::address_of(player);
        if (exists<PlayerBet>(player_addr)) {
            let existing_bet = borrow_global_mut<PlayerBet>(player_addr);
            existing_bet.bet_amount = bet_amount;
            existing_bet.bet_type = bet_type;
            existing_bet.bet_value = bet_value;
            existing_bet.is_active = true;
        } else {
            let player_bet = PlayerBet {
                bet_amount,
                bet_type,
                bet_value,
                is_active: true,
            };
            move_to(player, player_bet);
        };
        
        // Simple pseudo-random number generation using timestamp
        let current_time = timestamp::now_microseconds();
        let winning_number = ((current_time % 37) as u8); // 0-36
        game.last_winning_number = winning_number;
    }
}