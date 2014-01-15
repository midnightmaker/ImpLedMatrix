goalLevel <- 0;
smsSent <- 0;
patternStepCnt <- 0;
const THE_GOAL = 10;

column3 <- hardware.pin1;
column2 <- hardware.pin2;
column1 <- hardware.pin5;
column0 <- hardware.pin6;


row0 <- hardware.pinB; 
row1 <- hardware.pinD; 
row2 <- hardware.pinE;
row3 <- hardware.pinC;

 
goalPattern <- [[0x00,0x00,0x00], [0x00,0x00,0x04], [0x00,0x00,0x06], [0x00,0x02,0x06], 
                [0x00,0x06,0x06], [0x04,0x06,0x06], [0x04,0x07,0x06], [0x04,0x07,0x07],  
                [0x06,0x07,0x07], [0x07,0x07,0x07], [0x0F,0x07,0x07] ];

testPattern    <- [ [0x00,0x00,0x00], [0x00,0x00,0x04], [0x00,0x00,0x06], [0x00,0x02,0x06], 
                [0x00,0x06,0x06], [0x04,0x06,0x06], [0x04,0x07,0x06], [0x04,0x07,0x07],  
                [0x06,0x07,0x07], [0x07,0x07,0x07], [0x0F,0x07,0x07], 
                [0x00,0x00,0x00], [0x0F,0x07,0x07], [0x00,0x00,0x00], [0x0F,0x07,0x07], // Body Flash
                [0x0B,0x07,0x06], [0x0F,0x07,0x07], [0x0F,0x02,0x07], [0x0F,0x07,0x07], // Wing Flap
                [0x0B,0x07,0x06], [0x0F,0x07,0x07], [0x0F,0x02,0x07], [0x0F,0x07,0x07],
                [0x0B,0x07,0x06], [0x0F,0x07,0x07], [0x0F,0x02,0x07], [0x0F,0x07,0x07] ];
                
diagnostics <- [ [0x00,0x00,0x00] ];


rows            <- [row0,row1,row2,row3];
columns         <- [column0,column1,column2,column3];
 
sequence        <- 0; 
interval        <- 0;
breather        <- 0;
diagnosticsMode <- 0;
activeSequence  <- testPattern;
patternStepCnt  = activeSequence.len();

//--------------------------------------------------------------------------------------------------------
// Message from the client to increment the goal counter. When the goal counter reaches the
// number of steps in the LD grid pattern, the goal is reached and the celebratory pattern
// is displayed. An SMS is sent so that all participants know that they have something to look forward
// to
//--------------------------------------------------------------------------------------------------------
agent.on("addGoalStep", function( value ) {
  
  if( value == "superA" )
    goalLevel += 2;
  else if( value == "A" )
    goalLevel += 1;
  else if( value == "B" )
    goalLevel += 0.5;
  else if( value == "C" )
    goalLevel += 0.25;
  else if ( value == "restartGoal" )  
  {
    // More results may have come in after meeting the previous
    // goal so we don't always reset to zero. W need to give
    // credit for all results
    if( goalLevel > THE_GOAL ) {
      goalLevel -= THE_GOAL;
    }
    else {
      goalLevel = 0;
    }
    smsSent = 0;
  }
    
    
  if( goalLevel >= THE_GOAL)  
  {
    if( smsSent == 0 )
    {
      smsSent = 1;
      agent.send("resultStatus", goalLevel );
    }
    sequence = 0;
    activeSequence = testPattern;
    patternStepCnt = activeSequence.len();
    
  }
  else
  {
    activeSequence = goalPattern;  
    patternStepCnt = goalLevel % goalPattern.len();
  }
  
});

//--------------------------------------------------------------------------------------------------------
// Diagnostic Button presses received from the client application via the Agent Web API
// This allows the client to illuminate each LED individually to check wiring.
//--------------------------------------------------------------------------------------------------------
agent.on("buttonPressed", function( value ) {
  
    if( value )
    {
      if( value == "resumeOperation" )
      {
        diagnosticsMode = 0;
        sequence = 0;
        activeSequence = testPattern;
        patternStepCnt = activeSequence.len();
        return;
      }
      
      diagnosticsMode = 1;
      
      if( value == "leftFeeler")
      {
        diagnostics[0][0] = diagnostics[0][0] ^ 0x08;    
      }
      else if( value == "rightFeeler" )
      {
         diagnostics[0][0] = diagnostics[0][0] ^ 0x01;    
      }
      else if( value == "face" )
      {
        diagnostics[0][0] = diagnostics[0][0] ^ 0x02;    
      }
      else if( value == "leftTopWing" )
      {
        diagnostics[0][0] = diagnostics[0][0] ^ 0x04;    
      }
      else if( value == "rightTopWing" )
      {
        diagnostics[0][1] = diagnostics[0][1] ^ 0x01;    
      }
      else if( value == "leftBottomWing" )
      {
        diagnostics[0][1] = diagnostics[0][1] ^ 0x04;    
      }
      else if( value == "rigthBottomWing" )
      {
        diagnostics[0][2] = diagnostics[0][2] ^ 0x01;    
      }
      else if( value == "thorax" )
      {
        diagnostics[0][1] = diagnostics[0][1] ^ 0x02;    
      }
      else if( value == "abdomen" )
      {
        diagnostics[0][2] = diagnostics[0][2] ^ 0x02;    
      }
      else if( value == "tip" )
      {
        diagnostics[0][2] = diagnostics[0][2] ^ 0x04;    
      }
      else
      {
        server.log("Unknown Button");
      }
      
      activeSequence  <- diagnostics;
      patternStepCnt = activeSequence.len();
    }
    
}); 

//--------------------------------------------------------------------------------------------------------
// Scans the LED grid illuminating LEDs according to predefined bit patterns
//--------------------------------------------------------------------------------------------------------
function ledScan() {
  

  
  if( hardware.millis() - interval > 250 )
  {
    interval = hardware.millis();
    sequence++;
  }

  if( patternStepCnt > 0 )
  {
    sequence = sequence % patternStepCnt;
    local columnMask = 0x01;
   
    for( local row=0; row<3; row++ ){
      
      columnMask = 0x01;
      rows[row].write(1);
      
      for( local column = 0; column <4; column++ ){
            
        if( ( (activeSequence[sequence][row] & columnMask) & 0x0F ) == ( columnMask & 0x0F ) )
        {
          columns[column].write(1);
        }
      
        for(local i=0; i<5; i++)
        {
          
        }
        columns[column].write(0);            
        columnMask = columnMask << 1;
      }
      
      rows[row].write(0);
      
    }
  }

  // Want the scan to run as fast as possible but also need to periodically 
  // check on WiFi
  if( hardware.millis() - breather > 3000 )  {
    breather = hardware.millis();
    // Take a breather to deal with WiFi
    imp.wakeup(0.01, ledScan);
  }
  else
    imp.wakeup(0.0, ledScan);
  
}
 
//--------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------
function initializeGrid()
{
  for( local i=0; i<4; i++)
  {
    columns[i].configure(DIGITAL_OUT);
    rows[i].configure(DIGITAL_OUT);
    rows[i].write(0);
    columns[i].write(0);
    
  }
}

//--------------------------------------------------------------------------------------------------------
// Program Start
//--------------------------------------------------------------------------------------------------------
initializeGrid();

// Start scanning the LED grid
ledScan();