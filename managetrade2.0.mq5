//+------------------------------------------------------------------+
//| 包含標準庫                                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh> // MQL5 交易函數庫

//+------------------------------------------------------------------+
//| 全局變量                                                          |
//+------------------------------------------------------------------+
CTrade trade; // 創建一個交易對象，用於處理交易操作

// 記錄已經部分平倉的訂單
struct ClosedOrder
{
   ulong ticket;
   bool isClosedPartial;
};

ClosedOrder closedOrders[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA Initialized.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| 部分平倉功能                                                      |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    int totalOrders = PositionsTotal();
    
    for (int i = totalOrders - 1; i >= 0; i--) // 从后向前关闭订单
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if (trade.PositionClose(ticket))
            {
                Print("成功关闭订单: ", ticket);
            }
            else
            {
                Print("关闭订单失败: ", ticket, " - 错误: ", GetLastError());
            }
        }
    }
}


void ClosePartialPosition(ulong ticket, double percentage)
{
   double volume = PositionGetDouble(POSITION_VOLUME);
   double volumeToClose = volume * percentage / 100.0;
   if (trade.PositionClosePartial(ticket, volumeToClose))
   {
      Print("Partial close successful for ticket: ", ticket);
      // 標記已經部分平倉
      for (int i = 0; i < ArraySize(closedOrders); i++)
      {
         if (closedOrders[i].ticket == ticket)
         {
            closedOrders[i].isClosedPartial = true;
            return;
         }
      }
      // 如果找不到訂單，新增記錄
      ClosedOrder newOrder;
      newOrder.ticket = ticket;
      newOrder.isClosedPartial = true;
      ArrayResize(closedOrders, ArraySize(closedOrders) + 1);
      closedOrders[ArraySize(closedOrders) - 1] = newOrder;
   }
   else
   {
      Print("Partial close failed for ticket: ", ticket, " - Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 設置止損和止盈                                                   |
//+------------------------------------------------------------------+
void SetSLTP(ulong ticket, double TP, double SL)
{
   Print("訂單號: ", ticket, " 沒有設置SL 或 TP.");
   double stopLoss = 0, takeProfit = 0;
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   long minStopLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if (minStopLevelPoints < 0)
   {
      minStopLevelPoints = 10;
   }
   double minStopLevel = minStopLevelPoints * _Point;
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      stopLoss = openPrice - SL * _Point;
      takeProfit = openPrice + TP * _Point;
      if (stopLoss > openPrice - minStopLevel)
         stopLoss = openPrice - minStopLevel;
      trade.PositionModify(ticket, stopLoss, takeProfit);

      if (takeProfit < openPrice + minStopLevel)
         takeProfit = openPrice + minStopLevel;
      trade.PositionModify(ticket, stopLoss, takeProfit);
   }
   else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
   {
      stopLoss = openPrice + SL * _Point;
      takeProfit = openPrice - TP * _Point;
      if (stopLoss < openPrice + minStopLevel)
         stopLoss = openPrice + minStopLevel;
      trade.PositionModify(ticket, stopLoss, takeProfit);
      if (takeProfit > openPrice - minStopLevel)
         takeProfit = openPrice - minStopLevel;
      trade.PositionModify(ticket, stopLoss, takeProfit);
   }
   if (!trade.PositionModify(ticket, stopLoss, takeProfit))
   {
      Print("設置SL和TP失敗: ", ticket, " - Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 確認盈利                                                         |
//+------------------------------------------------------------------+
int inprofits(ulong ticket, double TP, double securedpips, double closepercentage)
{
   if (PositionSelectByTicket(ticket))
   {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double takeProfit = 0;

      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         if (currentPrice >= openPrice + securedpips * _Point)
         {
            takeProfit = openPrice + TP * _Point;
            trade.PositionModify(ticket, openPrice, takeProfit);
            ClosePartialPosition(ticket, closepercentage);
            return 1;
         }
      }
      else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         if (currentPrice <= openPrice - securedpips * _Point)
         {
            takeProfit = openPrice - TP * _Point;
            trade.PositionModify(ticket, openPrice, takeProfit);
            ClosePartialPosition(ticket, closepercentage);
            return 1;
         }
      }
   }
   else
   {
      Print("Position not found for ticket: ", ticket);
   }
   return 0;
}

//+------------------------------------------------------------------+
//| 檢查訂單                                                         |
//+------------------------------------------------------------------+
int Check()
{
   int totalOrders = PositionsTotal();
   double securedpips = 5000;  // 保證盈利
   double managepips = 5000;   // 降低損失
   double closepercentage = 80; // 倉位關閉多少百分比
   double managedpercentage = 50;
   double TP = 50000;
   double SL = 50000;

   for (int i = 0; i < totalOrders; i++)
   {
      ulong ticket = PositionGetTicket(i);

      if (PositionSelectByTicket(ticket))
      {
         if (PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentprice = PositionGetDouble(POSITION_PRICE_CURRENT);
            int positionType = PositionGetInteger(POSITION_TYPE);

            if (PositionGetDouble(POSITION_SL) == 0 || PositionGetDouble(POSITION_TP) == 0)
            {
               SetSLTP(ticket, TP, SL);
            }
            else if ((positionType == POSITION_TYPE_BUY && currentprice <= openPrice - managepips * _Point) ||
                     (positionType == POSITION_TYPE_SELL && currentprice >= openPrice + managepips * _Point))
            {
               bool isClosedPartial = false;
               for (int j = 0; j < ArraySize(closedOrders); j++)
               {
                  if (closedOrders[j].ticket == ticket && closedOrders[j].isClosedPartial)
                  {
                     isClosedPartial = true;
                     break;
                  }
               }
               if (!isClosedPartial)
               {
                  ClosePartialPosition(ticket, managedpercentage);
               }
            }
            else if (PositionGetDouble(POSITION_SL) != openPrice)
            {
               inprofits(ticket, TP, securedpips, closepercentage);
            }
         }
      }
   }
   return 0;
}

//+------------------------------------------------------------------+
//| 管理訂單                                                         |
//+------------------------------------------------------------------+
void ManageOrders()
{
   Check();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    ManageOrders();
    int SomeConditionToCloseAll=0;
    // 条件触发时关闭所有订单
    if (SomeConditionToCloseAll==1) // 替换为你的条件
    {
        CloseAllPositions();
    }
}



/*
void ClosePartialPositionSecond(ulong ticket, double percentage, double securedPips, double managePips)
{
    if (PositionSelectByTicket(ticket))
    {
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        int positionType = PositionGetInteger(POSITION_TYPE);

        // 判断是否需要进行第二次部分平仓
        if (positionType == POSITION_TYPE_BUY)
        {
            if (currentPrice >= openPrice + securedPips * _Point)
            {
                ClosePartialPosition(ticket, percentage);
            }
        }
        else if (positionType == POSITION_TYPE_SELL)
        {
            if (currentPrice <= openPrice - securedPips * _Point)
            {
                ClosePartialPosition(ticket, percentage);
            }
        }
    }
}
*/
