//+------------------------------------------------------------------+
//|                                                          7up.mq4 |
//|                                       Scarpelli/Combes/Vega 2017 |
//|                                                     Somos2SR.com |
//+------------------------------------------------------------------+
#property copyright "Scarpelli/Combes/Vega 2017"
#property link      "Somos2SR.com"
#property version   "1.21"
#property strict

//--- Parámetros de entrada.

input int      StopLoss=80;//Stop Loss en Porcentaje (%))
input int      TP=40;//TP en Porcentaje (%)
input int      TrailingStop=15;//Trailing Stop (Puntos)
input int      MN=16;//Magic Number
input double   Lots=0.1;//Lote
input int      P=14;//RSI Periodo
input int      RSImin=30;//RSI minimo
input int      RSImax=70;//RSI maximo
int TiempoAntes, TiempoAhora;

//+------------------------------------------------------------------+
//| INICIO DEL EXPERTO                                               |
//+------------------------------------------------------------------+
int init()
{

TiempoAntes==TiempoAhora==0;
   return(0);
}
int deinit()
{
   return(0);
}
int start()
  {
   double Vela8, Vela7, Vela6, Vela5, Vela4, Vela3, Vela2, Vela1, PC, PV, SC, SV, RSI1;
  int ticket, total, cnt, Mult, Comp;
  string Simbolo, Ventana;
    
//+------------------------------------------------------------------+
//| CONTROL DE ORDENES                                               |
//+------------------------------------------------------------------+
 
 //Comparando Tiempo de vela actual con vela anterior

 TiempoAhora=Time[0];
 if(TiempoAntes==TiempoAhora)
 {
 return(0);
 }
 else 
 {
 Print("Probando si hay ordenes metidas");
 
  if(Bars<100)
     {
      Print("menos de 100 barras");
      return(0);  
     }
   if(TP<10)
     {
      Print("TakeProfit inferior a 10");
      return(0); } // comprobación de TakeProfit
      
 Vela8=Close[8];  
 Vela7=Close[7];
 Vela6=Close[6];
 Vela5=Close[5];
 Vela4=Close[4];
 Vela3=Close[3];
 Vela2=Close[2];
 Vela1=Close[1]; 
 RSI1  = iRSI(NULL,0,P,PRICE_OPEN,1);
 total=OrdersTotal(); 
  
 Mult=1000;
 Simbolo=ChartSymbol();
 Ventana="JPY";
 Comp=StringFind(Simbolo,Ventana,0);
 
  if(Comp==3) //Busca si en el par esta la divisa JPY para cambiar el factor de multiplicación por sus digitos.
  {
  Mult=10;
  }
 
  if(total<1) 
     {
      // no se identifican órdenes abiertas
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("No hay dinero. Margen libre = ", AccountFreeMargin());
         return(0);  
        }

//+------------------------------------------------------------------+
//| CONDICIÓN DE COMPRA                                              |
//+------------------------------------------------------------------+
  
      // comprobamos la posibilidad de posición larga (BUY)
      if(Vela8>Vela7&&Vela7>Vela6&&Vela6>Vela5&&Vela5>Vela4&&Vela4>Vela3&&Vela3>Vela2&&Vela2>Vela1&&RSI1<RSImin)
        {
         RefreshRates ();
         ResetLastError ();
         SC=((Vela8-Vela1)*Mult*StopLoss); //Calculando el SL de Compra 
         PC=((Vela8-Vela1)*Mult*TP); //Calculando el TP de Compra
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,100,,Ask+PC*Point,"7UPv1.21",MN,0,clrNONE);
         if(ticket>0)
           {
           TiempoAntes=Time[0];
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Orden BUY abierta : ",OrderOpenPrice());       
           }
         else Print("Error de apertura de posición BUY : ",GetLastError()); 
         return(0);
        }
        
//+------------------------------------------------------------------+
//| CONDICIÓN DE VENTA                                               |
//+------------------------------------------------------------------+     
        
      // comprobamos la posibilidad de posición corta (SELL)
      if(Vela8<Vela7&&Vela7<Vela6&&Vela6<Vela5&&Vela5<Vela4&&Vela4<Vela3&&Vela3<Vela2&&Vela2<Vela1&&RSI1>RSImax)
        {
         RefreshRates ();
         ResetLastError ();
         SV=((Vela1-Vela8)*Mult*StopLoss); //Calculando el SL de Venta
         PV=((Vela1-Vela8)*Mult*TP); //Calculando el TP de Venta
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,100,Bid+SV*Point,Bid-PV*Point,"7UPv1.21",MN,0,clrNONE);
         if(ticket>0)
           {
           TiempoAntes=Time[0];
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Orden SELL abierta : ",OrderOpenPrice());
           }
         else Print("Error de apertura de posición SELL : ",GetLastError()); 
         return(0);}
       }
 
//+------------------------------------------------------------------+
//| TRAILING STOP                                                    |
//+------------------------------------------------------------------+ 
 
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // comprobación de posición abierta 
         OrderSymbol()==Symbol())  // comprobación del símbolo
        {
         if(OrderType()==OP_BUY)   // apertura de posición larga
           {
            // comprobación del trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
           }
         else // ir a la posición corta
           {
            // comprobación del trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   } 
 return(0);}
 
//+------------------------------------------------------------------+
//| FIN                                                              |
//+------------------------------------------------------------------+ 