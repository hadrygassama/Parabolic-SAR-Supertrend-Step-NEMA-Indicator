//+------------------------------------------------------------------+
//|                                              ParabolicSAR_EA.mq4 |
//|                             Copyright 2025, Hadry Gassama       |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2025, Hadry Gassama"
#property link      "https://github.com/hadrygassama/Parabolic-SAR-Supertrend-Step-NEMA-Indicator"
#property version   "2.00"
#property description "Expert Advisor basé sur Parabolic SAR filtré par SuperTrend Histo"
#property description "Stratégie contrarian: SAR opposé à la tendance SuperTrend"
#property strict

//=================================================================
//                    PARAMETRES PARABOLIC SAR
//=================================================================
input string ________SAR_SETTINGS________ = "=== Paramètres Parabolic SAR ===";
input double InpSARStep = 0.02;        // SAR Step
input double InpSARMaximum = 0.2;      // SAR Maximum

//=================================================================
//                    PARAMETRES SUPERTREND HISTO
//=================================================================
input string ________SUPERTREND_SETTINGS________ = "=== Paramètres SuperTrend Histo ===";
input bool   InpUseSuperTrendFilter = true;     // Utiliser le filtre SuperTrend
input int    InpSuperTrendPeriod = 66;          // SuperTrend Period
input double InpSuperTrendMultiplier = 2.236;   // SuperTrend Multiplier
input int    InpMidPricePeriod = 10;            // Mid Price Period

//=================================================================
//                    GESTION DES POSITIONS
//=================================================================
input string ________POSITION_MANAGEMENT________ = "=== Gestion des Positions ===";
input double InpLotSize = 0.1;         // Taille des Lots
input int    InpMagicNumber = 12345;   // Magic Number
input int    InpSlippage = 3;          // Slippage (points)
input bool   InpCloseOnOppositeSignal = true; // Fermer sur signal opposé

//=================================================================
//                    GESTION DES RISQUES
//=================================================================
input string ________RISK_MANAGEMENT________ = "=== Gestion des Risques ===";
input bool   InpUseStopLoss = false;   // Utiliser Stop Loss
input bool   InpUseTakeProfit = false; // Utiliser Take Profit
input int    InpStopLoss = 50;         // Stop Loss (points)
input int    InpTakeProfit = 100;      // Take Profit (points)

//=================================================================
//                    OPTIONS DE TRADING
//=================================================================
input string ________TRADING_OPTIONS________ = "=== Options de Trading ===";
input bool   InpTradeOnNewBar = true;  // Trader sur nouvelle bougie uniquement
input bool   InpShowInfo = true;       // Afficher les informations sur le graphique

//--- Global variables
datetime LastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Validate input parameters
   if(InpSARStep <= 0 || InpSARStep >= 1)
   {
      Print("Erreur: SAR Step doit être entre 0 et 1");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(InpSARMaximum <= InpSARStep || InpSARMaximum >= 1)
   {
      Print("Erreur: SAR Maximum doit être supérieur à SAR Step et inférieur à 1");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(InpLotSize <= 0)
   {
      Print("Erreur: Lot Size doit être positif");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(InpSuperTrendPeriod <= 0)
   {
      Print("Erreur: SuperTrend Period doit être positif");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   // Initialize last bar time
   LastBarTime = Time[0];
   
   // Enable timer for info display
   if(InpShowInfo)
      EventSetTimer(1);
   
   Print("=== EA ParabolicSAR avec filtre SuperTrend initialisé ===");
   Print("SAR Step: ", InpSARStep, ", SAR Maximum: ", InpSARMaximum);
   Print("SuperTrend Filter: ", (InpUseSuperTrendFilter ? "ACTIVÉ" : "DÉSACTIVÉ"));
   Print("SuperTrend Period: ", InpSuperTrendPeriod, ", Multiplier: ", InpSuperTrendMultiplier);
   Print("Lot Size: ", InpLotSize, ", Magic Number: ", InpMagicNumber);
   Print("Fermeture sur signal opposé: ", (InpCloseOnOppositeSignal ? "Activée" : "Désactivée"));
   Print("Stratégie: Trading contrarian - SAR opposé à SuperTrend");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
   Print("EA ParabolicSAR arrêté. Raison: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if we should trade only on new bar
   if(InpTradeOnNewBar)
   {
      if(Time[0] == LastBarTime)
         return;
      LastBarTime = Time[0];
   }
   
   // Check if we have enough bars
   if(Bars < 20)
      return;
   
   // Get Parabolic SAR values
   double sar_current = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 1);
   double sar_previous = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 2);
   
   if(sar_current == 0 || sar_previous == 0)
      return;
   
   // Get current price data
   double close_current = Close[1];
   double close_previous = Close[2];
   
   // Determine SAR signals
   bool sar_bullish_signal = false;
   bool sar_bearish_signal = false;
   
   // SAR Bullish signal: SAR below price and was above price previously
   if(sar_current < close_current && sar_previous > close_previous)
      sar_bullish_signal = true;
   
   // SAR Bearish signal: SAR above price and was below price previously
   if(sar_current > close_current && sar_previous < close_previous)
      sar_bearish_signal = true;
   
   // Get SuperTrend Histo values if filter is enabled
   bool supertrend_bullish = false;
   bool supertrend_bearish = false;
   bool use_sar_buy = false;
   bool use_sar_sell = false;
   
   if(InpUseSuperTrendFilter)
   {
      double st_up = iCustom(Symbol(), Period(), "SuperTrend Histo (experiment) 1.3", 
                            PERIOD_CURRENT, InpSuperTrendPeriod, InpSuperTrendMultiplier, 
                            InpMidPricePeriod, 0, false, false, true, false, false, false, "alert2.wav", 0, 1);
      
      double st_down = iCustom(Symbol(), Period(), "SuperTrend Histo (experiment) 1.3", 
                              PERIOD_CURRENT, InpSuperTrendPeriod, InpSuperTrendMultiplier, 
                              InpMidPricePeriod, 0, false, false, true, false, false, false, "alert2.wav", 1, 1);
      
      // SuperTrend direction
      supertrend_bullish = (st_up != EMPTY_VALUE && st_up > 0);
      supertrend_bearish = (st_down != EMPTY_VALUE && st_down > 0);
      
      // Contrarian logic: 
      // Si SuperTrend haussier → Prendre seulement les SELL du SAR
      // Si SuperTrend baissier → Prendre seulement les BUY du SAR
      if(supertrend_bullish)
      {
         use_sar_sell = true;  // Prendre les signaux de vente SAR
         use_sar_buy = false;
      }
      else if(supertrend_bearish)
      {
         use_sar_buy = true;   // Prendre les signaux d'achat SAR
         use_sar_sell = false;
      }
   }
   else
   {
      // Si pas de filtre SuperTrend, utiliser tous les signaux SAR
      use_sar_buy = true;
      use_sar_sell = true;
   }
   
   // Final trading signals with filter
   bool final_buy_signal = sar_bullish_signal && use_sar_buy;
   bool final_sell_signal = sar_bearish_signal && use_sar_sell;
   
   // Check current positions
   int total_orders = OrdersTotal();
   bool has_buy_position = false;
   bool has_sell_position = false;
   
   for(int i = 0; i < total_orders; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagicNumber)
         {
            if(OrderType() == OP_BUY)
               has_buy_position = true;
            if(OrderType() == OP_SELL)
               has_sell_position = true;
         }
      }
   }
   
   // Trading logic with SuperTrend filter
   if(final_buy_signal)
   {
      // Close sell positions if option is enabled
      if(InpCloseOnOppositeSignal && has_sell_position)
      {
         CloseAllPositions(OP_SELL);
         Print("Positions SELL fermées suite au signal d'achat filtré");
      }
      
      // Open buy position if we don't have one
      if(!has_buy_position)
      {
         string reason = InpUseSuperTrendFilter ? " (SuperTrend baissier + SAR haussier)" : " (SAR haussier)";
         Print("Signal d'achat validé", reason);
         OpenPosition(OP_BUY);
      }
   }
   else if(final_sell_signal)
   {
      // Close buy positions if option is enabled
      if(InpCloseOnOppositeSignal && has_buy_position)
      {
         CloseAllPositions(OP_BUY);
         Print("Positions BUY fermées suite au signal de vente filtré");
      }
      
      // Open sell position if we don't have one
      if(!has_sell_position)
      {
         string reason = InpUseSuperTrendFilter ? " (SuperTrend haussier + SAR baissier)" : " (SAR baissier)";
         Print("Signal de vente validé", reason);
         OpenPosition(OP_SELL);
      }
   }
   
   // Alternative logic: Close on opposite trend
   if(!final_buy_signal && !final_sell_signal && InpCloseOnOppositeSignal)
   {
      string current_trend = GetCurrentTrendDirection();
      
      if(current_trend == "BAISSIER" && has_buy_position)
      {
         CloseAllPositions(OP_BUY);
         Print("Positions BUY fermées - tendance devenue baissière");
      }
      else if(current_trend == "HAUSSIER" && has_sell_position)
      {
         CloseAllPositions(OP_SELL);
         Print("Positions SELL fermées - tendance devenue haussière");
      }
   }
}

//+------------------------------------------------------------------+
//| Open a new position                                              |
//+------------------------------------------------------------------+
void OpenPosition(int order_type)
{
   double price;
   double sl = 0, tp = 0;
   color arrow_color;
   string comment;
   
   if(order_type == OP_BUY)
   {
      price = Ask;
      arrow_color = clrBlue;
      comment = "SAR-ST Buy";
      
      if(InpUseStopLoss)
         sl = price - InpStopLoss * Point;
      if(InpUseTakeProfit)
         tp = price + InpTakeProfit * Point;
   }
   else if(order_type == OP_SELL)
   {
      price = Bid;
      arrow_color = clrRed;
      comment = "SAR-ST Sell";
      
      if(InpUseStopLoss)
         sl = price + InpStopLoss * Point;
      if(InpUseTakeProfit)
         tp = price - InpTakeProfit * Point;
   }
   else
      return;
   
   // Normalize price levels
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);
   
   int ticket = OrderSend(Symbol(), order_type, InpLotSize, price, InpSlippage, sl, tp, comment, InpMagicNumber, 0, arrow_color);
   
   if(ticket > 0)
   {
      Print("Position ouverte avec succès. Ticket: ", ticket, ", Type: ", (order_type == OP_BUY ? "BUY" : "SELL"));
   }
   else
   {
      Print("Erreur lors de l'ouverture de position. Code d'erreur: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Close all positions of specified type                            |
//+------------------------------------------------------------------+
void CloseAllPositions(int order_type)
{
   int closed_count = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagicNumber && OrderType() == order_type)
         {
            double close_price;
            color arrow_color;
            
            if(order_type == OP_BUY)
            {
               close_price = Bid;
               arrow_color = clrBlue;
            }
            else
            {
               close_price = Ask;
               arrow_color = clrRed;
            }
            
            bool result = OrderClose(OrderTicket(), OrderLots(), close_price, InpSlippage, arrow_color);
            
            if(result)
            {
               closed_count++;
               Print("Position fermée avec succès. Ticket: ", OrderTicket());
            }
            else
            {
               Print("Erreur lors de la fermeture de position. Ticket: ", OrderTicket(), ", Erreur: ", GetLastError());
            }
         }
      }
   }
   
   if(closed_count > 0)
   {
      Print("Total de ", closed_count, " position(s) ", (order_type == OP_BUY ? "BUY" : "SELL"), " fermée(s)");
   }
}

//+------------------------------------------------------------------+
//| Get current trend based on SAR position                          |
//+------------------------------------------------------------------+
string GetCurrentTrend()
{
   double sar_current = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 1);
   double close_current = Close[1];
   
   if(sar_current < close_current)
      return "HAUSSIER";
   else if(sar_current > close_current)
      return "BAISSIER";
   else
      return "NEUTRE";
}

//+------------------------------------------------------------------+
//| Get current trend direction for closing logic                    |
//+------------------------------------------------------------------+
string GetCurrentTrendDirection()
{
   double sar_current = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 1);
   double close_current = Close[1];
   
   if(sar_current < close_current)
      return "HAUSSIER";
   else
      return "BAISSIER";
}

//+------------------------------------------------------------------+
//| Get SuperTrend status                                            |
//+------------------------------------------------------------------+
string GetSuperTrendStatus()
{
   if(!InpUseSuperTrendFilter)
      return "DÉSACTIVÉ";
      
   double st_up = iCustom(Symbol(), Period(), "SuperTrend Histo (experiment) 1.3", 
                         PERIOD_CURRENT, InpSuperTrendPeriod, InpSuperTrendMultiplier, 
                         InpMidPricePeriod, 0, false, false, true, false, false, false, "alert2.wav", 0, 1);
   
   double st_down = iCustom(Symbol(), Period(), "SuperTrend Histo (experiment) 1.3", 
                           PERIOD_CURRENT, InpSuperTrendPeriod, InpSuperTrendMultiplier, 
                           InpMidPricePeriod, 0, false, false, true, false, false, false, "alert2.wav", 1, 1);
   
   if(st_up != EMPTY_VALUE && st_up > 0)
      return "HAUSSIER";
   else if(st_down != EMPTY_VALUE && st_down > 0)
      return "BAISSIER";
   else
      return "NEUTRE";
}

//+------------------------------------------------------------------+
//| Get allowed SAR signals based on SuperTrend                     |
//+------------------------------------------------------------------+
string GetAllowedSignals()
{
   if(!InpUseSuperTrendFilter)
      return "TOUS";
      
   string st_status = GetSuperTrendStatus();
   
   if(st_status == "HAUSSIER")
      return "SELL uniquement";
   else if(st_status == "BAISSIER")
      return "BUY uniquement";
   else
      return "AUCUN";
}

//+------------------------------------------------------------------+
//| Display information on chart                                     |
//+------------------------------------------------------------------+
void DisplayInfo()
{
   if(!InpShowInfo)
      return;
      
   string info = "=== EA Parabolic SAR + SuperTrend Filter ===\n";
   info += "Tendance SAR: " + GetCurrentTrend() + "\n";
   info += "SuperTrend: " + GetSuperTrendStatus() + "\n";
   info += "Signaux autorisés: " + GetAllowedSignals() + "\n";
   info += "─────────────────────────────────\n";
   info += "SAR Step: " + DoubleToString(InpSARStep, 3) + "\n";
   info += "SAR Maximum: " + DoubleToString(InpSARMaximum, 3) + "\n";
   info += "ST Period: " + IntegerToString(InpSuperTrendPeriod) + "\n";
   info += "ST Multiplier: " + DoubleToString(InpSuperTrendMultiplier, 3) + "\n";
   info += "Lot Size: " + DoubleToString(InpLotSize, 2) + "\n";
   info += "─────────────────────────────────\n";
   info += "Filtre SuperTrend: " + (InpUseSuperTrendFilter ? "ACTIVÉ" : "DÉSACTIVÉ") + "\n";
   info += "Fermeture signal opposé: " + (InpCloseOnOppositeSignal ? "OUI" : "NON") + "\n";
   
   // Count current positions
   int buy_count = 0, sell_count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagicNumber)
         {
            if(OrderType() == OP_BUY) buy_count++;
            if(OrderType() == OP_SELL) sell_count++;
         }
      }
   }
   
   info += "─────────────────────────────────\n";
   info += "Positions BUY: " + IntegerToString(buy_count) + "\n";
   info += "Positions SELL: " + IntegerToString(sell_count) + "\n";
   
   Comment(info);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   DisplayInfo();
}