/******************************************************************************
// File Name:       PartnerRestEndpoint.cls
// Details:         The Apex REST Service for Shyft Moving partners
// Test Classes:    PartnerRestEndpointTests
====================
// Modification Log: (Name - Change Summary - Initial)
// Roman Bulgakov    - 23/09/2020 - created
*******************************************************************************/

@RestResource(urlMapping='/partnerwebhook')
global with sharing class PartnerRestEndpoint 
{  
	public class PartnerWebhookHandlerException extends Exception {}
	
    @HttpPost
    global static void postHandler() 
    {
        new PartnerWebhookPostHandler(RestContext.request.requestBody.toString()).handle();
    }

    /******************************* REQUEST HANDLERS *******************************/
    
    private static Map<String, String> handlers = new Map<String, String>{
    	'recap_email' => 'RecapEmailRestHandler'
    };

    private abstract class PartnerWebhookHandler 
    {
    	private Object request;

        public virtual Object handle() 
        { 
            return getResponse(null); 
        }
        
        private virtual Object getRequest() 
        {
            return request;
        }
        
        private virtual Object getResponse(Object parameters) 
        {
        	System.debug(parameters);
        	
        	RestResponse response = RestContext.response;
        	if(parameters != null && parameters instanceof Exception) {
	        	response.statusCode = 500;
	            response.responseBody = Blob.valueOf(((Exception)parameters).getMessage());
        	}else if(parameters != null) {
        		response.responseBody = Blob.valueOf(parameters instanceof String ? (String)parameters : String.valueOf(parameters));
        	}

            return response;
        }
    }
    
    //******************************* POST HANDLER *******************************

    private class PartnerWebhookPostHandler extends PartnerWebhookHandler 
    {
    	public PartnerWebhookPostHandler(Object request) 
    	{
    		this.request = request;
    	}
    	
        public override Object handle() 
        {
            try
            {
                System.debug(getRequest());

                Map<String, Object> requestDataMap = (Map<String, Object>)JSON.deserializeUntyped((String)getRequest());
     
                String eventType = (String)requestDataMap.get('type');
                if(String.isBlank(eventType)) throw new PartnerWebhookHandlerException('Invalid request. Missing event type.');

                Map<String, Object> eventData = (Map<String, Object>)requestDataMap.get('data');
                if(eventData == null) throw new PartnerWebhookHandlerException('Invalid request. Missing event data.');
                
                String handlerType = handlers.get(eventType);
                if(String.isBlank(handlerType)) throw new PartnerWebhookHandlerException('Invalid request. Invalid event type.');
                
                Callable handler = (Callable)Type.forName(handlerType).newInstance();
                return getResponse(handler.call(eventType, eventData));
            }catch(Exception ex) {
                return getResponse(ex);
            }
        }
    }
}