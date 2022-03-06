/******************************************************************************
// Details:		 The class handler for Flexi Kanban Form List/Related List/Lookup components
// Test Classes:	FK_FormActionsHandlerTests
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/10/2020 - created
*******************************************************************************/

public with sharing class FK_FormActionsHandler implements FLX_KB.KanBanInterfaces.FormBuilderApiInterface
{
    public Object loadRelatedListData(Map<String, Object> parameters)
    {
    	return null;
    }
    
    public Object loadListData(Map<String, Object> parameters)
    {
		return null;
    }
    
    public Object loadLookupData(Map<String, Object> parameters)
    {
    	List<Map<String, Object>> result = new List<Map<String, Object>>();
    	String filterText = (String)parameters.get('filter');
    	
    	List<SObject> records;
    	if(String.isBlank(filterText)) records = [select Referral_Type__c from Account where Referral_Type__c != null and RecordType.Name = 'Partners' and Recap_Email__c = true and Account_Status__c = 'Active' group by Referral_Type__c];
    	else records = [select Referral_Type__c from Account where Referral_Type__c like :(filterText + '%') and RecordType.Name = 'Partners' and Recap_Email__c = true and Account_Status__c = 'Active' group by Referral_Type__c];
    	
    	for(SObject record : records)
    	{
    		result.add(new Map<String, Object>{
    			'Id' => (String)record.get('Referral_Type__c'),
    			'Name' => (String)record.get('Referral_Type__c')
    		});
    	}
    	
    	return result;
    }
}