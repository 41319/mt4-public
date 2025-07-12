//+------------------------------------------------------------------+
//|                  Closed P&L Positions This Month.mq4             |
//|                        Copyright 2024, ForexEAHub                |
//|                           https://www.forexeathub.com            |
//+------------------------------------------------------------------+
#property strict
#property version   "1.20"

// Display Settings
input int MagicNumber = 0;          // 0 = all trades, or set your Magic Number
input color ProfitColor = clrLime;
input color LossColor = clrRed;
input int Corner = 3;               // 1=Top Left, 2=Top Right, 3=Bottom Left, 4=Bottom Right
input int FontSize = 12;
input string FontFace = "Arial";
input int X_Offset = 820;           // Horizontal offset from corner
input int Y_Offset = 20;            // Vertical offset from corner

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(10); // Update every 10 seconds
   UpdateDisplay();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "PLTM_"); // Clean up all our objects
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                  |
//+------------------------------------------------------------------+
void OnTimer()
{
   UpdateDisplay();
}

//+------------------------------------------------------------------+
//| Calculate profitable/loss positions for current month           |
//+------------------------------------------------------------------+
void CountPLPositionsThisMonth(int &profitCount, int &lossCount, 
                              double &profitVolume, double &lossVolume,
                              double &avgProfitTime, double &avgLossTime)
{
   profitCount = 0;
   lossCount = 0;
   profitVolume = 0;
   lossVolume = 0;
   double totalProfitSeconds = 0;
   double totalLossSeconds = 0;
   
   datetime monthStart = iTime(NULL, PERIOD_MN1, 0);
   datetime now = TimeCurrent();
   
   for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         // Filter for current month, closed positions, and magic number
         if(OrderType() <= OP_SELL && 
            OrderCloseTime() >= monthStart && 
            OrderCloseTime() <= now &&
            (MagicNumber == 0 || OrderMagicNumber() == MagicNumber))
         {
            double profit = OrderProfit() + OrderSwap() + OrderCommission();
            double duration = OrderCloseTime() - OrderOpenTime();
            
            if(profit > 0.01) // Profit position
            {
               profitCount++;
               profitVolume += OrderLots();
               totalProfitSeconds += duration;
            }
            else if(profit < -0.01) // Loss position
            {
               lossCount++;
               lossVolume += OrderLots();
               totalLossSeconds += duration;
            }
         }
      }
   }
   
   // Calculate average times
   avgProfitTime = (profitCount > 0) ? totalProfitSeconds / profitCount : 0;
   avgLossTime = (lossCount > 0) ? totalLossSeconds / lossCount : 0;
   
   profitVolume = NormalizeDouble(profitVolume, 2);
   lossVolume = NormalizeDouble(lossVolume, 2);
}

//+------------------------------------------------------------------+
//| Format time duration to readable string                         |
//+------------------------------------------------------------------+
string FormatDuration(double seconds)
{
   if(seconds <= 0) return "N/A";
   
   int days = (int)(seconds / 86400);
   seconds -= days * 86400;
   int hours = (int)(seconds / 3600);
   seconds -= hours * 3600;
   int minutes = (int)(seconds / 60);
   
   if(days > 0) return StringFormat("%dd %dh", days, hours);
   if(hours > 0) return StringFormat("%dh %dm", hours, minutes);
   return StringFormat("%dm", minutes);
}

//+------------------------------------------------------------------+
//| Update the on-chart display                                     |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
   int profitCount, lossCount;
   double profitVolume, lossVolume;
   double avgProfitTime, avgLossTime;
   
   CountPLPositionsThisMonth(profitCount, lossCount, profitVolume, lossVolume, avgProfitTime, avgLossTime);
   string monthName = TimeToStr(iTime(NULL, PERIOD_MN1, 0), TIME_DATE);
   
   string txt = StringFormat("Closed This Month (%s):\n"+
                            "Profitable: %d trades (%.2f lots) ~ %s avg\n"+
                            "Loss: %d trades (%.2f lots) ~ %s avg",
                            monthName,
                            profitCount, profitVolume, FormatDuration(avgProfitTime),
                            lossCount, lossVolume, FormatDuration(avgLossTime));
   
   // Create or update the label
   if(ObjectFind(0, "PLTM_Label") < 0)
   {
      ObjectCreate(0, "PLTM_Label", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_CORNER, Corner);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_ANCHOR, GetAnchorFromCorner(Corner));
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_XDISTANCE, X_Offset);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_YDISTANCE, Y_Offset);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_FONTSIZE, FontSize);
      ObjectSetString(0, "PLTM_Label", OBJPROP_FONT, FontFace);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_BACK, false);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, "PLTM_Label", OBJPROP_HIDDEN, true);
   }
   
   // Color the text based on net performance
   color clr = (profitCount > lossCount) ? ProfitColor : LossColor;
   ObjectSetInteger(0, "PLTM_Label", OBJPROP_COLOR, clr);
   ObjectSetString(0, "PLTM_Label", OBJPROP_TEXT, txt);
}

//+------------------------------------------------------------------+
//| Get appropriate anchor point based on corner                     |
//+------------------------------------------------------------------+
int GetAnchorFromCorner(int corner)
{
   switch(corner)
   {
      case 1: return ANCHOR_LEFT_UPPER;    // Top Left
      case 2: return ANCHOR_RIGHT_UPPER;   // Top Right
      case 3: return ANCHOR_LEFT_LOWER;    // Bottom Left
      case 4: return ANCHOR_RIGHT_LOWER;   // Bottom Right
      default: return ANCHOR_LEFT_LOWER;   // Default to Bottom Left
   }
}