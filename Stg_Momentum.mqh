/**
 * @file
 * Implements Momentum strategy based on the Momentum indicator.
 */

// User input params.
INPUT int Momentum_Period = 12;                                 // Averaging period
INPUT ENUM_APPLIED_PRICE Momentum_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int Momentum_Shift = 0;                                   // Shift
INPUT float Momentum_SignalOpenLevel = 0.00000000f;             // Signal open level
INPUT int Momentum_SignalOpenFilterMethod = 0.00000000;         // Signal open filter method
INPUT int Momentum_SignalOpenBoostMethod = 0.00000000;          // Signal open boost method
INPUT int Momentum_SignalOpenMethod = 0;                        // Signal open method (0-
INPUT float Momentum_SignalCloseLevel = 0.00000000;             // Signal close level
INPUT int Momentum_SignalCloseMethod = 0;                       // Signal close method (0-
INPUT int Momentum_PriceLimitMethod = 0;                        // Price limit method
INPUT float Momentum_PriceLimitLevel = 0;                       // Price limit level
INPUT float Momentum_MaxSpread = 6.0;                           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_Momentum.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_Momentum_Params : StgParams {
  unsigned int Momentum_Period;
  ENUM_APPLIED_PRICE Momentum_Applied_Price;
  int Momentum_Shift;
  int Momentum_SignalOpenMethod;
  float Momentum_SignalOpenLevel;
  int Momentum_SignalOpenFilterMethod;
  int Momentum_SignalOpenBoostMethod;
  int Momentum_SignalCloseMethod;
  float Momentum_SignalCloseLevel;
  int Momentum_PriceLimitMethod;
  float Momentum_PriceLimitLevel;
  float Momentum_MaxSpread;

  // Constructor: Set default param values.
  Stg_Momentum_Params()
      : Momentum_Period(::Momentum_Period),
        Momentum_Applied_Price(::Momentum_Applied_Price),
        Momentum_Shift(::Momentum_Shift),
        Momentum_SignalOpenMethod(::Momentum_SignalOpenMethod),
        Momentum_SignalOpenLevel(::Momentum_SignalOpenLevel),
        Momentum_SignalOpenFilterMethod(::Momentum_SignalOpenFilterMethod),
        Momentum_SignalOpenBoostMethod(::Momentum_SignalOpenBoostMethod),
        Momentum_SignalCloseMethod(::Momentum_SignalCloseMethod),
        Momentum_SignalCloseLevel(::Momentum_SignalCloseLevel),
        Momentum_PriceLimitMethod(::Momentum_PriceLimitMethod),
        Momentum_PriceLimitLevel(::Momentum_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Momentum_Params>(_params, _tf, stg_mom_m1, stg_mom_m5, stg_mom_m15, stg_mom_m30, stg_mom_h1,
                                         stg_mom_h4, stg_mom_h4);
    }
    // Initialize strategy parameters.
    MomentumParams mom_params(_params.Momentum_Period, _params.Momentum_Applied_Price);
    mom_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Momentum(mom_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Momentum_SignalOpenMethod, _params.Momentum_SignalOpenMethod,
                       _params.Momentum_SignalOpenFilterMethod, _params.Momentum_SignalOpenBoostMethod,
                       _params.Momentum_SignalCloseMethod, _params.Momentum_SignalCloseMethod);
    sparams.SetPriceLimits(_params.Momentum_PriceLimitMethod, _params.Momentum_PriceLimitLevel);
    sparams.SetMaxSpread(_params.Momentum_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Momentum(sparams, "Momentum");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_Momentum *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR].value[0] > _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR].value[0] < _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Momentum *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count = (int)_level * (int)_indi.GetPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 1: {
          int _bar_count = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 2: {
          int _bar_count = (int)_level * (int)_indi.GetPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 3: {
          int _bar_count = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
