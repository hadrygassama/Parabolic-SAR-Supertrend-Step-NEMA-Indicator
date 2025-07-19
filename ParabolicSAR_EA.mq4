//+------------------------------------------------------------------+
//|                                              ParabolicSAR_EA.mq4 |
//|                             Copyright 2025, Votre Nom           |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2025, Votre Nom"
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

//--- Input parameters
input double InpSARStep = 0.02;        // Parabolic SAR Step
input double InpSARMaximum = 0.2;      // Parabolic SAR Maximum
input double InpLotSize = 0.1;         // Lot Size
input int    InpMagicNumber = 12345;   // Magic Number
input int    InpSlippage = 3;          // Slippage
input bool   InpUseStopLoss = false;    // Use Stop Loss
input bool   InpUseTakeProfit = false;  // Use Take Profit
input int    InpStopLoss = 50;         // Stop Loss (points)
input int    InpTakeProfit = 100;      // Take Profit (points)
input bool   InpTradeOnNewBar = true;  // Trade only on new bar
input bool   InpCloseOnOppositeSignal = true; // Close trades on opposite signal

//--- Global variables
datetime LastBarTime = 0;
int      SARHandle;

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
   
   // Initialize last bar time
   LastBarTime = Time[0];
   
   Print("EA ParabolicSAR initialisé avec succès");
   Print("SAR Step: ", InpSARStep, ", SAR Maximum: ", InpSARMaximum);
   Print("Lot Size: ", InpLotSize, ", Magic Number: ", InpMagicNumber);
   Print("Fermeture sur signal opposé: ", (InpCloseOnOppositeSignal ? "Activée" : "Désactivée"));
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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
   if(Bars < 10)
      return;
   
   // Get Parabolic SAR values
   double sar_current = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 1);
   double sar_previous = iSAR(Symbol(), Period(), InpSARStep, InpSARMaximum, 2);
   
   if(sar_current == 0 || sar_previous == 0)
      return;
   
   // Get current price data
   double close_current = Close[1];
   double close_previous = Close[2];
   
   // Determine trend direction
   bool bullish_signal = false;
   bool bearish_signal = false;
   
   // Bullish signal: SAR below price and was above price previously
   if(sar_current < close_current && sar_previous > close_previous)
      bullish_signal = true;
   
   // Bearish signal: SAR above price and was below price previously
   if(sar_current > close_current && sar_previous < close_previous)
      bearish_signal = true;
   
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
   
   // Trading logic with opposite signal closing option
   if(bullish_signal)
   {
      // Close sell positions if option is enabled
      if(InpCloseOnOppositeSignal && has_sell_position)
      {
         CloseAllPositions(OP_SELL);
         Print("Positions SELL fermées suite au signal haussier");
      }
      
      // Open buy position if we don't have one
      if(!has_buy_position)
      {
         OpenPosition(OP_BUY);
      }
   }
   else if(bearish_signal)
   {
      // Close buy positions if option is enabled
      if(InpCloseOnOppositeSignal && has_buy_position)
      {
         CloseAllPositions(OP_BUY);
         Print("Positions BUY fermées suite au signal baissier");
      }
      
      // Open sell position if we don't have one
      if(!has_sell_position)
      {
         OpenPosition(OP_SELL);
      }
   }
   
   // Alternative logic: Close on opposite signal even without new position
   if(!bullish_signal && !bearish_signal && InpCloseOnOppositeSignal)
   {
      // Check if current trend has changed from positions
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
      comment = "SAR Buy";
      
      if(InpUseStopLoss)
         sl = price - InpStopLoss * Point;
      if(InpUseTakeProfit)
         tp = price + InpTakeProfit * Point;
   }
   else if(order_type == OP_SELL)
   {
      price = Bid;
      arrow_color = clrRed;
      comment = "SAR Sell";
      
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
//| Display information on chart                                     |
//+------------------------------------------------------------------+
void DisplayInfo()
{
   string info = "=== EA Parabolic SAR ===\n";
   info += "Tendance actuelle: " + GetCurrentTrend() + "\n";
   info += "SAR Step: " + DoubleToString(InpSARStep, 3) + "\n";
   info += "SAR Maximum: " + DoubleToString(InpSARMaximum, 3) + "\n";
   info += "Lot Size: " + DoubleToString(InpLotSize, 2) + "\n";
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
   
   info += "Positions BUY: " + IntegerToString(buy_count) + "\n";
   info += "Positions SELL: " + IntegerToString(sell_count) + "\n";
   
   Comment(info);
}

//+------------------------------------------------------------------+
//| Timer function (optional)                                        |
//+------------------------------------------------------------------+
void OnTimer()
{
   DisplayInfo();
}