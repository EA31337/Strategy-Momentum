//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Momentum_EURUSD_M5_Params : Stg_Momentum_Params {
  Stg_Momentum_EURUSD_M5_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M5;
    Momentum_Period = 2;
    Momentum_Applied_Price = 3;
    Momentum_Shift = 0;
    Momentum_TrailingStopMethod = 6;
    Momentum_TrailingProfitMethod = 11;
    Momentum_SignalOpenLevel = 36;
    Momentum_SignalBaseMethod = -61;
    Momentum_SignalOpenMethod1 = 1;
    Momentum_SignalOpenMethod2 = 0;
    Momentum_SignalCloseLevel = 36;
    Momentum_SignalCloseMethod1 = 1;
    Momentum_SignalCloseMethod2 = 0;
    Momentum_MaxSpread = 3;
  }
};
