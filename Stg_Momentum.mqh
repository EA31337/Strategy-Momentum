//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Momentum strategy based on the Momentum indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Momentum.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
string __Momentum_Parameters__ = "-- Momentum strategy params --";  // >>> MOMENTUM <<<
int Momentum_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
ENUM_TRAIL_TYPE Momentum_TrailingStopMethod = 22;                  // Trail stop method
ENUM_TRAIL_TYPE Momentum_TrailingProfitMethod = 1;                 // Trail profit method
int Momentum_Period = 12;                                          // Period Fast
ENUM_APPLIED_PRICE Momentum_Applied_Price = PRICE_CLOSE;           // Applied Price
double Momentum_SignalOpenLevel = 0.00000000;                      // Signal open level
int Momentum1_SignalBaseMethod = 0;                                // Signal base method (0-
int Momentum1_OpenCondition1 = 0;                                  // Open condition 1 (0-1023)
int Momentum1_OpenCondition2 = 0;                                  // Open condition 2 (0-1023)
ENUM_MARKET_EVENT Momentum1_CloseCondition = C_MOMENTUM_BUY_SELL;  // Close condition for M1
double Momentum_MaxSpread = 6.0;                                   // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Momentum_Params : Stg_Params {
  unsigned int Momentum_Period;
  ENUM_APPLIED_PRICE Momentum_Applied_Price;
  int Momentum_Shift;
  ENUM_TRAIL_TYPE Momentum_TrailingStopMethod;
  ENUM_TRAIL_TYPE Momentum_TrailingProfitMethod;
  double Momentum_SignalOpenLevel;
  long Momentum_SignalBaseMethod;
  long Momentum_SignalOpenMethod1;
  long Momentum_SignalOpenMethod2;
  double Momentum_SignalCloseLevel;
  ENUM_MARKET_EVENT Momentum_SignalCloseMethod1;
  ENUM_MARKET_EVENT Momentum_SignalCloseMethod2;
  double Momentum_MaxSpread;

  // Constructor: Set default param values.
  Stg_Momentum_Params()
      : Momentum_Period(::Momentum_Period),
        Momentum_Applied_Price(::Momentum_Applied_Price),
        Momentum_Shift(::Momentum_Shift),
        Momentum_TrailingStopMethod(::Momentum_TrailingStopMethod),
        Momentum_TrailingProfitMethod(::Momentum_TrailingProfitMethod),
        Momentum_SignalOpenLevel(::Momentum_SignalOpenLevel),
        Momentum_SignalBaseMethod(::Momentum_SignalBaseMethod),
        Momentum_SignalOpenMethod1(::Momentum_SignalOpenMethod1),
        Momentum_SignalOpenMethod2(::Momentum_SignalOpenMethod2),
        Momentum_SignalCloseLevel(::Momentum_SignalCloseLevel),
        Momentum_SignalCloseMethod1(::Momentum_SignalCloseMethod1),
        Momentum_SignalCloseMethod2(::Momentum_SignalCloseMethod2),
        Momentum_MaxSpread(::Momentum_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Momentum : public Strategy {
 public:
  Stg_Momentum(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Momentum *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Momentum_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Momentum_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Momentum_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Momentum_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Momentum_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Momentum_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Momentum_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Momentum_Params adx_params(_params.Momentum_Period, _params.Momentum_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_Momentum);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Momentum(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Momentum_SignalBaseMethod, _params.Momentum_SignalOpenMethod1,
                       _params.Momentum_SignalOpenMethod2, _params.Momentum_SignalCloseMethod1,
                       _params.Momentum_SignalCloseMethod2, _params.Momentum_SignalOpenLevel,
                       _params.Momentum_SignalCloseLevel);
    sparams.SetStops(_params.Momentum_TrailingProfitMethod, _params.Momentum_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Momentum_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Momentum(sparams, "Momentum");
    return _strat;
  }

  /**
   * Check if Momentum indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double momentum_0 = ((Indi_Momentum *)this.Data()).GetValue(0);
    double momentum_1 = ((Indi_Momentum *)this.Data()).GetValue(1);
    double momentum_2 = ((Indi_Momentum *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        break;
      case ORDER_TYPE_SELL:
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
