//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Momentum_EURUSD_H4_Params : Stg_Momentum_Params {
  Stg_Momentum_EURUSD_H4_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H4;
    Momentum_Period = 2;
    Momentum_Applied_Price = 3;
    Momentum_Shift = 0;
    Momentum_TrailingStopMethod = 6;
    Momentum_TrailingProfitMethod = 11;
    Momentum_SignalOpenLevel = 36;
    Momentum_SignalBaseMethod = 0;
    Momentum_SignalOpenMethod1 = 1;
    Momentum_SignalOpenMethod2 = 0;
    Momentum_SignalCloseLevel = 36;
    Momentum_SignalCloseMethod1 = 1;
    Momentum_SignalCloseMethod2 = 0;
    Momentum_MaxSpread = 10;
  }
};
