/**
 * @file
 * Implements Momentum strategy based on the Momentum indicator.
 */

// User input params.
INPUT_GROUP("Momentum strategy: strategy params");
INPUT float Momentum_LotSize = 0;                // Lot size
INPUT float Momentum_SignalOpenLevel = 0.0f;     // Signal open level (in %)
INPUT int Momentum_SignalOpenFilterMethod = 32;  // Signal open filter method (-7-7)
INPUT int Momentum_SignalOpenFilterTime = 3;     // Signal open filter time (-7-7)
INPUT int Momentum_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Momentum_SignalOpenMethod = 2;         // Signal open method (-127-127)
INPUT float Momentum_SignalCloseLevel = 0.0f;    // Signal close level (in %)
INPUT int Momentum_SignalCloseMethod = 2;        // Signal close method (-127-127)
INPUT int Momentum_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT int Momentum_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float Momentum_PriceStopLevel = 2;         // Price stop level
INPUT int Momentum_TickFilterMethod = 32;        // Tick filter method
INPUT float Momentum_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short Momentum_Shift = 0;                  // Shift
INPUT float Momentum_OrderCloseLoss = 80;        // Order close loss
INPUT float Momentum_OrderCloseProfit = 80;      // Order close profit
INPUT int Momentum_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Momentum strategy: Momentum indicator params");
INPUT int Momentum_Indi_Momentum_Period = 12;                                 // Averaging period
INPUT ENUM_APPLIED_PRICE Momentum_Indi_Momentum_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int Momentum_Indi_Momentum_Shift = 0;                                   // Shift

// Structs.

// Defines struct with default user strategy values.
struct Stg_Momentum_Params_Defaults : StgParams {
  Stg_Momentum_Params_Defaults()
      : StgParams(::Momentum_SignalOpenMethod, ::Momentum_SignalOpenFilterMethod, ::Momentum_SignalOpenLevel,
                  ::Momentum_SignalOpenBoostMethod, ::Momentum_SignalCloseMethod, ::Momentum_SignalCloseFilter,
                  ::Momentum_SignalCloseLevel, ::Momentum_PriceStopMethod, ::Momentum_PriceStopLevel,
                  ::Momentum_TickFilterMethod, ::Momentum_MaxSpread, ::Momentum_Shift) {
    Set(STRAT_PARAM_LS, Momentum_LotSize);
    Set(STRAT_PARAM_OCL, Momentum_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Momentum_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Momentum_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Momentum_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_Momentum : public Strategy {
 public:
  Stg_Momentum(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Momentum *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_Momentum_Params_Defaults stg_momentum_defaults;
    StgParams _stg_params(stg_momentum_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_momentum_m1, stg_momentum_m5, stg_momentum_m15, stg_momentum_m30,
                             stg_momentum_h1, stg_momentum_h4, stg_momentum_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_Momentum(_stg_params, _tparams, _cparams, "Momentum");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    IndiMomentumParams _indi_params(::Momentum_Indi_Momentum_Period, ::Momentum_Indi_Momentum_Applied_Price,
                                    ::Momentum_Indi_Momentum_Shift);
    _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_Momentum(_indi_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Momentum *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncreasing(2);
        _result &= _indi.IsIncByPct(_level, 0, 0, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecreasing(2);
        _result &= _indi.IsDecByPct(-_level, 0, 0, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
