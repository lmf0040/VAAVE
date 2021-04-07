address 0x7257c2417e4d1038e1817c8f283ace2e {
    
    module ViolasAAVE {
	use 0x1::DiemTimestamp;

	const SECONDS_PER_YEAR: u64 = 365;
	const MANTISSA_ONE: u64 = 4294967296;

	resource struct ReserveData {
	    liquidity_index: u64,
	    variable_borrow_index: u64,
	    current_liquidity_rate: u64,
	    current_variable_borrow_rate: u64,
	    current_stable_borrow_rate: u64,
	    last_update_timestamp: u64,
	    id: u64,
	}

	resource struct AToken {
	    index: u64,
	    value: u64,
	}

	resource struct VariableDebtToken {
	    index: u64,
	    value: u64,
	}

	resource struct StableDebtToken {
	    index: u64,
	    value: u64,
	}
	
	resource struct ATokenInfo {
	    total_supply: u64,
	}

	resource struct VariableDebtTokenInfo {
	    total_supply: u64,
	}

	resource struct StableDebtTokenInfo {
	    total_supply: u64,
	}
	
	resource struct GlobalData {
	    reserves: vector<ReserveData>,
	    atoken_infos: vector<ATokenInfo>,
	    variable_debt_token_infos: vector<VariableDebtTokenInfo>,
	    stable_debt_token_infos: vector<StableDebtTokenInfo>,
	}
	
	fun new_mantissa(a: u64, b: u64) : u64 {
	    let c = (a as u128) << 64;
	    let d = (b as u128) << 32;
	    let e = c / d;
	    //assert(e != 0 || a == 0, 101);
	    (e as u64)
	}
	
	fun mantissa_div(a: u64, b: u64) : u64 {
	    let c = (a as u128) << 32;
	    let d = c / (b as u128);
	    (d as u64)
	}

	fun mantissa_mul(a: u64, b: u64) : u64 {
	    let c = (a as u128) * (b as u128);
	    let d = c >> 32;
	    (d as u64)
	}

	fun safe_sub(a: u64, b: u64): u64 {
	    if(a < b) { 0 } else { a - b }
	}
	
	
	public fun reserve_logic_get_normalized_income(reserve: &ReserveData) : u64 {
	    let timestamp =  reserve.last_update_timestamp;
	    let interest  = math_utils_calculate_linear_interest(reserve.current_liquidity_rate, timestamp);
	    let cumulated = mantissa_mul(reserve.liquidity_index, interest);
	    cumulated
	}

	public fun reserve_logic_get_normalized_debt(reserve: &ReserveData) : u64 {
	    let last_timestamp =  reserve.last_update_timestamp;
	    let curr_timestamp = DiemTimestamp::now_microseconds();
	    if(last_timestamp == curr_timestamp) {
		return reserve.variable_borrow_index
	    };
	    let interest = math_utils_calculate_compounded_interest(reserve.current_variable_borrow_rate, last_timestamp, curr_timestamp);
	    let cumulated = mantissa_mul(reserve.variable_borrow_index, interest);
	    cumulated
	}
	
	public fun math_utils_calculate_linear_interest(rate: u64, timestamp: u64) : u64 {
	    DiemTimestamp::now_microseconds()/(60*1000*1000);
	    let seconds = safe_sub(DiemTimestamp::now_microseconds(), timestamp)/(1000*1000);
	    let s = new_mantissa(seconds, SECONDS_PER_YEAR);
	    let r = mantissa_mul(rate, s);
	    r + MANTISSA_ONE
	}

	public fun math_utils_calculate_compounded_interest(rate: u64, last_timestamp: u64, curr_timestamp: u64) : u64 {
	    let exp = safe_sub(curr_timestamp, last_timestamp) / (1000*1000);
	    if (exp == 0) {
		return MANTISSA_ONE
	    };
	    
	    let exp1 = exp-1;
	    let exp2 = safe_sub(exp, 2);
	    let rate_persecond = rate / SECONDS_PER_YEAR;
	    let base_pow2 = mantissa_mul(rate_persecond, rate_persecond);
	    let base_pow3 = mantissa_mul(base_pow2, rate_persecond);
	    let term2 = exp*exp1*base_pow2/2;
	    let term3 = exp*exp1*exp2*base_pow3/6;
	    MANTISSA_ONE + rate_persecond*exp + term2 + term3
	}
    }
}
