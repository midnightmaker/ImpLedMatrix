timezone   <- -4;
ApiKey     <- "107ac1217-4cad-2a3b-xxxxx-xxxxxxxxxx";

persistentValues <- server.load();

//--------------------------------------------------------------------------------------------------------
// Processes external HTTP requests. These requests contain button press and status requests
//-------------------------------------------------------------------------------------------------------- 
function webServer( request, response )
{
    //server.log( "HTTP Request Headers: " + request.headers );
    //server.log( "HTTP Request Body: " + request.body );
    //server.log( "HTTP Request Method:" + request.method);
    
    // Needed to avoid  Access-Control-Allow-Origin header error due to AJAX browser security requirements
    // that only allows requests from the domain that served the web page
    response.header( "Access-Control-Allow-Origin", "*" );
    if( request.method=="OPTIONS" )
    {
        response.header("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
        response.header("Access-Control-Allow-Headers", "cache-control, origin, x-csrftoken, content-type, accept,x-apikey"); 
        response.send(200,"OK");
        return;
    }

    // API Key idea from http://forums.electricimp.com/discussion/comment/8281#Comment_8281
    server.log("API Key " +  request.headers["x-apikey"] );
    if ("x-apikey" in request.headers && request.headers["x-apikey"] == ApiKey) 
    {
        local jsonRequest = http.jsondecode( request.body );
        server.log( jsonRequest );
        if ( "request" in jsonRequest ) {
        
            server.log( "Requested: " + jsonRequest.request );
            
            if( jsonRequest.request == "GetStatus" ) {
                response.send(200, "Status ok" );
                //server.log("response 200");
            }
            else if( jsonRequest.request == "buttonPressed" ) {
                // Send the button ID to the imp
                device.send( jsonRequest.request, jsonRequest.button );
                response.send(200, "Status ok" );
            }
            else if( jsonRequest.request == "addGoalStep" ) {
                // Send the new achievement level to the imp
                device.send( jsonRequest.request, jsonRequest.stepValue );
                response.send(200, "Status ok" );
            }
            else if( jsonRequest.request == "persistValues" ) {
                
                server.save( jsonRequest );
                persistentValues = server.load();
                server.log(http.jsonencode(persistentValues ));
                response.send(200, "Status ok" );
            }
            else
            {
                server.log( "Unknown Command String" );
                response.send(500, "Unknown Command String");
            }
        }
        else
        {
            server.log( "Unknown Request" );
            response.send(500, "Unknown Request. Did not find request in body"); 
        }
    } 
    else 
    {
        // Unauthorized access attempt
        response.send(401, "Authorization Failed. Invalid Api Key");
    }
   
}
 
//--------------------------------------------------------------------------------------------------------
//Send SMS Door Status Message
//--------------------------------------------------------------------------------------------------------  
function sendSMSStatus( message )
{
    local json = "{\"groups\": [\""+ persistentValues["smsGroupID"] + "\" ],   \"text\": \""+message+"\"}";
    local req = http.post("https://api.sendhub.com/v1/messages/?username="+persistentValues["smsUserName"]+"&api_key="+persistentValues["smsApiKey"], 
        { "Content-Type" : "application/json" }, json );
          
    local res = req.sendsync();
    if(res.statuscode != 201) {
        server.log("Error sending SMS");
    }
    else
    {
        server.log("Sent SMS : " + message );
    }
}

//--------------------------------------------------------------------------------------------------------
// HTTP Handler
//-------------------------------------------------------------------------------------------------------- 
http.onrequest(webServer);


//--------------------------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------------------------
device.on("resultStatus", function(value) {
  
    sendSMSStatus("Congratulations! Your accomplishment will be rewarded!");
    
    
});

