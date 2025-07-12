//+------------------------------------------------------------------+
//|                  Closed P&L Positions This Month.mq4             |
//|                        Copyright 2024, ForexEAHub                |
//|                           https://www.forexeathub.com            |
//+------------------------------------------------------------------+
#property strict
#property version   "1.40"

// Display Settings
input int MagicNumber = 0;          // 0 = all trades, or set your Magic Number
input color ProfitColor = clrLime;
input color LossColor = clrRed;
input int Corner = 3;               // 1=Top Left, 2=Top Right, 3=Bottom Left, 4=Bottom Right
input int FontSize = 12;
input string FontFace = "Arial";
input int X_Offset = 20;            // Horizontal offset from corner
input int Y_Offset = 20;            // Vertical offset from corner
input int Line_Spacing = 18;        // Vertical spacing between lines

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
   CleanUpChart();
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
//| Remove all our objects from chart                               |
//+------------------------------------------------------------------+
void CleanUpChart()
{
   ObjectsDeleteAll(0, "PLTM_");
}

//+------------------------------------------------------------------+
//| Calculate profitable/loss positions for current month           |
//+------------------------------------------------------------------+
void CountPLPositionsThisMonth(int &profitCount, int &lossCount, 
                              double &profitVolume, double &lossVolume,
                              double &avgProfitTime, double &avgLossTime,
                              double &tradesPerDay)
{
   profitCount = 0;
   lossCount = 0;
   profitVolume = 0;
   lossVolume = 0;
   double totalProfitSeconds = 0;
   double totalLossSeconds = 0;
   
   datetime monthStart = iTime(NULL, PERIOD_MN1, 0);
   datetime now = TimeCurrent();
   
   // To calculate trades per day, we need to track trading days
   int totalTradingDays = 0;
   int lastProcessedDay = -1;
   int currentMonth = -1;
   
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
            // Count trading days
            MqlDateTime closeTimeStruct;
            TimeToStruct(OrderCloseTime(), closeTimeStruct);
            
            if(currentMonth == -1) currentMonth = closeTimeStruct.mon;
            
            if(closeTimeStruct.day != lastProcessedDay || closeTimeStruct.mon != currentMonth)
            {
               totalTradingDays++;
               lastProcessedDay = closeTimeStruct.day;
               currentMonth = closeTimeStruct.mon;
            }
            
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
   
   // Calculate trades per day
   int totalTrades = profitCount + lossCount;
   tradesPerDay = (totalTradingDays > 0) ? (double)totalTrades / totalTradingDays : 0;
   
   profitVolume = NormalizeDouble(profitVolume, 2);
   lossVolume = NormalizeDouble(lossVolume, 2);
   tradesPerDay = NormalizeDouble(tradesPerDay, 2);
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
   // First clean up previous objects
   CleanUpChart();
   
   int profitCount, lossCount;
   double profitVolume, lossVolume;
   double avgProfitTime, avgLossTime;
   double tradesPerDay;
   
   CountPLPositionsThisMonth(profitCount, lossCount, profitVolume, lossVolume, 
                           avgProfitTime, avgLossTime, tradesPerDay);
   
   string monthName = TimeToStr(iTime(NULL, PERIOD_MN1, 0), TIME_DATE);
   int yPos = Y_Offset;
   
   // Create header
   CreateLabel("PLTM_Header", StringFormat("Closed Trades This Month (%s)", monthName), 
              X_Offset, yPos, FontSize, ProfitColor);
   yPos += Line_Spacing;
   
   // Create profitable trades line
   CreateLabel("PLTM_Profit", StringFormat("Profitable: %d trades (%.2f lots) ~ %s avg", 
              profitCount, profitVolume, FormatDuration(avgProfitTime)), 
              X_Offset, yPos, FontSize, ProfitColor);
   yPos += Line_Spacing;
   
   // Create loss trades line
   CreateLabel("PLTM_Loss", StringFormat("Loss: %d trades (%.2f lots) ~ %s avg", 
              lossCount, lossVolume, FormatDuration(avgLossTime)), 
              X_Offset, yPos, FontSize, LossColor);
   yPos += Line_Spacing;
   
   // Create trades per day line
   CreateLabel("PLTM_TradesPerDay", StringFormat("Trades/Day: %.2f", tradesPerDay), 
              X_Offset, yPos, FontSize, (profitCount > lossCount) ? ProfitColor : LossColor);
}

//+------------------------------------------------------------------+
//| Create a label object                                           |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int size, color clr)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, GetAnchorFromCorner(Corner));
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, FontFace);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
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