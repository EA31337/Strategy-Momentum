/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Momentum_Params_H1 : MomentumParams {
  Indi_Momentum_Params_H1() : MomentumParams(indi_momentum_defaults, PERIOD_H1) { shift = 0; }
} indi_momentum_h1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Momentum_Params_H1 : StgParams {
  // Struct constructor.
  Stg_Momentum_Params_H1() : StgParams(stg_momentum_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_momentum_h1;
