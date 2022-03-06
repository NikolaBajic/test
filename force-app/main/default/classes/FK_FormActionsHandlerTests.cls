/******************************************************************************
// Details:         The test class for the class FK_FormActionsHandler
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/10/2020 - created.
*******************************************************************************/

@isTest
public with sharing class FK_FormActionsHandlerTests {
    public static testMethod void run(){
    	Account accountRecord = new Account();
        accountRecord.RecordTypeId = [select Id from RecordType where Name = 'Partners' and SObjectType = 'Account'].Id;
        accountRecord.Name = 'Test Account';
        accountRecord.Referral_Type__c = 'Roommates';
        accountRecord.Account_Status__c = 'Active';
        insert accountRecord;
        
     	FK_FormActionsHandler controller = new FK_FormActionsHandler();
     	controller.loadRelatedListData(null);
     	controller.loadListData(null);
     	controller.loadLookupData(new Map<String, Object>{
     		'filter' => 'Test'
     	});
     }
}