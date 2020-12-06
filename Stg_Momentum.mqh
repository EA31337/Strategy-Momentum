/**
 * @file
 * Implements Momentum strategy based on the Momentum indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Momentum.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float Momentum_LotSize = 0;                        // Lot size
INPUT float Momentum_SignalOpenLevel = 0.00000000f;      // Signal open level
INPUT int Momentum_SignalOpenFilterMethod = 0.00000000;  // Signal open filter method
INPUT int Momentum_SignalOpenBoostMethod = 0.00000000;   // Signal open boost method
INPUT int Momentum_SignalOpenMethod = 0;                 // Signal open method (0-
INPUT float Momentum_SignalCloseLevel = 0.00000000;      // Signal close level
INPUT int Momentum_SignalCloseMethod = 0;                // Signal close method (0-
INPUT int Momentum_PriceStopMethod = 0;                  // Price stop method
INPUT float Momentum_PriceStopLevel = 0;                 // Price stop level
INPUT int Momentum_TickFilterMethod = 0;                 // Tick filter method
INPUT float Momentum_MaxSpread = 6.0;                    // Max spread to trade (pips)
INPUT int Momentum_Shift = 0;                            // Shift
INPUT string __Momentum_Indi_Momentum_Parameters__ =
    "-- Momentum strategy: Momentum indicator params --";            // >>> Momentum strategy: Momentum indicator <<<
INPUT int Indi_Momentum_Period = 12;                                 // Averaging period
INPUT ENUM_APPLIED_PRICE Indi_Momentum_Applied_Price = PRICE_CLOSE;  // Applied Price

// Structs.

// Defines struct with default user indicator values.
struct Indi_Momentum_Params_Defaults : MomentumParams {
  Indi_Momentum_Params_Defaults() : MomentumParams(::Indi_Momentum_Period, ::Indi_Momentum_Applied_Price) {}
} indi_momentum_defaults;

// Defines struct to store indicator parameter values.
struct Indi_Momentum_Params : public MomentumParams {
  // Struct constructors.
  void Indi_Momentum_Params(MomentumParams &_params, ENUM_TIMEFRAMES _tf) : MomentumParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_Momentum_Params_Defaults : StgParams {
  Stg_Momentum_Params_Defaults()
      : StgParams(::Momentum_SignalOpenMethod, ::Momentum_SignalOpenFilterMethod, ::Momentum_SignalOpenLevel,
                  ::Momentum_SignalOpenBoostMethod, ::Momentum_SignalCloseMethod, ::Momentum_SignalCloseLevel,
                  ::Momentum_PriceStopMethod, ::Momentum_PriceStopLevel, ::Momentum_TickFilterMethod,
                  ::Momentum_MaxSpread, ::Momentum_Shift) {}
} stg_momentum_defaults;

// Struct to define strategy parameters to override.
struct Stg_Momentum_Params : StgParams {
  Indi_Momentum_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Momentum_Params(Indi_Momentum_Params &_iparams, StgParams &_sparams)
      : iparams(indi_momentum_defaults, _iparams.tf), sparams(stg_momentum_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Momentum : public Strategy {
 public:
  Stg_Momentum(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Momentum *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_Momentum_Params _indi_params(indi_momentum_defaults, _tf);
    StgParams _stg_params(stg_momentum_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_Momentum_Params>(_indi_params, _tf, indi_momentum_m1, indi_momentum_m5, indi_momentum_m15,
                                          indi_momentum_m30, indi_momentum_h1, indi_momentum_h4, indi_momentum_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_momentum_m1, stg_momentum_m5, stg_momentum_m15, stg_momentum_m30,
                               stg_momentum_h1, stg_momentum_h4, stg_momentum_h8);
    }
    // Initialize indicator.
    MomentumParams mom_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Momentum(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Momentum(_stg_params, "Momentum");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Momentum *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR][0] > _indi[PREV][0];
          if (METHOD(_method, 0)) _result &= _indi[PREV][0] < _indi[PPREV][0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1)) _result &= _indi[PPREV][0] < _indi[3][0];     // ... 3 consecutive columns are red.
          if (METHOD(_method, 2)) _result &= _indi[3][0] < _indi[4][0];         // ... 4 consecutive columns are red.
          if (METHOD(_method, 3)) _result &= _indi[PREV][0] > _indi[PPREV][0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4)) _result &= _indi[PPREV][0] > _indi[3][0];     // ... 3 consecutive columns are green.
          if (METHOD(_method, 5)) _result &= _indi[3][0] < _indi[4][0];         // ... 4 consecutive columns are green.
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR][0] < _indi[PREV][0];
          if (METHOD(_method, 0)) _result &= _indi[PREV][0] < _indi[PPREV][0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1)) _result &= _indi[PPREV][0] < _indi[3][0];     // ... 3 consecutive columns are red.
          if (METHOD(_method, 2)) _result &= _indi[3][0] < _indi[4][0];         // ... 4 consecutive columns are red.
          if (METHOD(_method, 3)) _result &= _indi[PREV][0] > _indi[PPREV][0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4)) _result &= _indi[PPREV][0] > _indi[3][0];     // ... 3 consecutive columns are green.
          if (METHOD(_method, 5)) _result &= _indi[3][0] < _indi[4][0];         // ... 4 consecutive columns are green.
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Momentum *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1: {
          int _bar_count0 = (int)_level * (int)_indi.GetPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count0));
          break;
        }
        case 2: {
          int _bar_count1 = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
          break;
        }
        case 3: {
          int _bar_count2 = (int)_level * (int)_indi.GetPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count2))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count2));
          break;
        }
        case 4: {
          int _bar_count3 = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count3))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count3));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
