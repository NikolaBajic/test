/******************************************************************************
// Details: Test class for VehicleService.cls
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/03/2020 - created
*******************************************************************************/

@IsTest
private class VehicleServiceTests 
{
	@IsTest private static void run() 
	{
		Test.startTest();

        Account accountRecord = new Account();
        accountRecord.RecordTypeId = [select Id from RecordType where Name = 'Partners' and SObjectType = 'Account'].Id;
        accountRecord.Name = 'Test Account';
        accountRecord.Referral_Type__c = 'Roommates';
        accountRecord.Account_Status__c = 'Active';
        insert accountRecord;
        
        Contact contactRecord = new Contact();
        contactRecord.LastName = 'Test Contact';
        contactRecord.AccountId = accountRecord.Id;
        insert contactRecord;
		
		Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Name = 'Test';
        opportunityRecord.AccountId = accountRecord.Id;
        opportunityRecord.Primary_Contact__c = contactRecord.Id;
        opportunityRecord.StageName = 'Draft';
        opportunityRecord.CloseDate = Date.today().addDays(1);
        insert opportunityRecord;
		
		Vehicle_Quotes__c quoteRecord = new Vehicle_Quotes__c(
			Name='Test', 
			Opportunity__c = opportunityRecord.Id,
			Model__c = 'Test',
			Make__c = 'Test',
			Year__c = '2020'
		);
		insert quoteRecord;
		
		Service_Package__c packageRecord = new Service_Package__c();
        packageRecord.Name = 'Test';
        packageRecord.Opportunity__c = opportunityRecord.Id;
        packageRecord.Vehicle_Quotes__c = quoteRecord.Id;
        insert packageRecord;
		
		VehicleService.VehicleServiceInput input = new VehicleService.VehicleServiceInput();
		input.method = 'Pass Service Package Id';
		input.recordId = quoteRecord.Id;
		input.data = packageRecord.Id;
		
		VehicleService.invoke(new List<VehicleService.VehicleServiceInput>{input});
	}
}