//+------------------------------------------------------------------+
//|                     Closed Volume This Month.mq4                 |
//|                        Copyright 2024, ForexEAHub               |
//|                           https://www.forexeathub.com           |
//+------------------------------------------------------------------+
#property strict
#property version   "1.10"

// Display Settings
input int MagicNumber = 0;          // 0 = all trades, or set your Magic Number
input color TextColor = clrDodgerBlue;
input int Corner = 1;               // 1=Top Left, 2=Top Right, 3=Bottom Left, 4=Bottom Right
input int FontSize = 12;
input string FontFace = "Arial";

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
   ObjectsDeleteAll(0, "CVTM_"); // Clean up all our objects
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function (main updates happen here)                        |
//+------------------------------------------------------------------+
void OnTimer()
{
   UpdateDisplay();
}

//+------------------------------------------------------------------+
//| Calculate THIS MONTH'S closed volume                            |
//+------------------------------------------------------------------+
double GetClosedVolumeThisMonth()
{
   double volume = 0;
   datetime monthStart = iTime(NULL, PERIOD_MN1, 0); // Start of current month
   datetime now = TimeCurrent();
   
   for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         // Filter for current month and magic number (if set)
         if(OrderCloseTime() >= monthStart && OrderCloseTime() <= now && 
            (MagicNumber == 0 || OrderMagicNumber() == MagicNumber))
         {
            volume += OrderLots();
         }
      }
   }
   return NormalizeDouble(volume, 2);
}

//+------------------------------------------------------------------+
//| Update the on-chart display                                     |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
   double lots = GetClosedVolumeThisMonth();
   string monthName = TimeToStr(iTime(NULL, PERIOD_MN1, 0), TIME_DATE);
   
   string txt = StringFormat("Closed This Month (%s):\n%.2f Lots", monthName, lots);
   
   // Create or update the label
   if(ObjectFind(0, "CVTM_Label") < 0)
   {
      ObjectCreate(0, "CVTM_Label", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "CVTM_Label", OBJPROP_CORNER, Corner);
      ObjectSetInteger(0, "CVTM_Label", OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, "CVTM_Label", OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, "CVTM_Label", OBJPROP_COLOR, TextColor);
      ObjectSetInteger(0, "CVTM_Label", OBJPROP_FONTSIZE, FontSize);
      ObjectSetString(0, "CVTM_Label", OBJPROP_FONT, FontFace);
   }
   
   ObjectSetString(0, "CVTM_Label", OBJPROP_TEXT, txt);
}