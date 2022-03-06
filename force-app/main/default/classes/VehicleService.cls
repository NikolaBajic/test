/******************************************************************************
// Details: This class implements logic around the Vehicle_Quotes__c object
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/03/2020 - created
*******************************************************************************/

global with sharing class VehicleService 
{
	public class VehicleServiceException extends Exception {}
	
    private static VehicleService instance;
    
    /*********************** STATIC SECTION ***********************/

    public static VehicleService getInstance()
    {
        if (instance == null) instance = new VehicleService();
        return instance;
    }
    
    /*********************** INVOKE SECTION ***********************/
    
    global class VehicleServiceInput
	{
	    @InvocableVariable(label='Method Name' required=true description='The service method name.')
	    global String method;
	    
	    @InvocableVariable(label='Record ID' required=false description='The Vehicle Quotes record id.')
	    global ID recordId;
	    
	    @InvocableVariable(label='Data' required=false description='The input data. Optional.')
	    global String data;
	}
	
	global class VehicleServiceOutput
	{
	    @InvocableVariable(required=false description='The result param 1.')
	    global String param1;
	    
	    @InvocableVariable(required=false description='The result param 2.')
	    global String param2;
	}
	
	@InvocableMethod(label='Invoke Vehicle Service Method' description='The method to invoke Vehicle Service class methods.')
    global static List<VehicleServiceOutput> invoke(List<VehicleServiceInput> inputParameters) 
    {
    	VehicleServiceInput inputData = inputParameters[0];
    	List<VehicleServiceOutput> outputResult = new List<VehicleServiceOutput>();
    	
    	if(inputData.method == 'Pass Service Package Id') {
    		passServicePackageId(inputData.recordId, inputData.data);
    	}
    	
    	return outputResult;
    }
    
    /*********************** PUBLIC SECTION ***********************/
    
    @future(callout=true)
    public static void passServicePackageId(ID recordId, String servicePackageId)
    {
    	try
    	{
    		if(recordId == null) throw new VehicleServiceException('Empty Vehicle Quotes record Id.'); 				
			if(String.isBlank(servicePackageId)) throw new VehicleServiceException('Empty Service Package record Id.'); 
				
			System.debug(VehicleService.getInstance().makeRequest('salesforcevehicle', '{"SalesforceServicePackageId": "' + servicePackageId + '"}', 'POST'));
			
			update new Vehicle_Quotes__c(Id=recordId, Surveybot_GET_Sent__c=true);
    	}catch(Exception ex){
    		System.debug(ex);
    	}
    }
    
    /*********************** PRIVATE SECTION ***********************/
    
    private String makeRequest(String url, String body, String method) 
    {
        List<Surveybot_Endpoint__mdt> endpoints = [select Production_URL__c, Sandbox_URL__c, Auth_Key__c from Surveybot_Endpoint__mdt];
        if(endpoints.size() == 0) throw new VehicleServiceException('Endpoint metadata settings not found.');

        Organization currentOrg = [select IsSandbox from Organization LIMIT 1];
        HttpRequest request = new HttpRequest();
        request.setEndpoint(currentOrg.IsSandbox ? endpoints[0].Sandbox_URL__c + url : endpoints[0].Production_URL__c + url);
        request.setMethod(method);
        request.setHeader('X-AUTH', endpoints[0].Auth_Key__c);
        
        if(body != null) {
        	request.setHeader('Content-Type', 'application/json');
        	request.setBody(body);
        }
        
        HTTPResponse response = new HttpResponse();  
        if (Test.isRunningTest()) {
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"example":"test"}');
            response.setStatusCode(200);
        }else {
			response = new Http().send(request);
        }
        
        if(response.getStatusCode() != 200){
        	throw new VehicleServiceException(response.getBody()); 				
        }

        return response.getBody();
    }
}