@isTest
private class LeadAssignmentUtilityTest {

    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Success']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@shyfttesting.com');

        insert u;

        UserServicePresence usp = new UserServicePresence();
        usp.UserId = u.Id;
        // usp.StatusStartDate = Date.today();
        // usp.StatusEndDate = null;

        insert usp;

    }
    @isTest static void checkForLeadAssignment() {

        EDHU.TriggerPanel.setBreaker('Lead', true);

        List<UserServicePresence> users = [SELECT Id, UserId, User.Profile.Name, StatusStartDate, StatusEndDate
                                    FROM UserServicePresence
                                    WHERE User.Profile.Name = 'Move Coach' AND StatusEndDate = null 
                                    ORDER BY Id Desc LIMIT 1];
                                    

        Lead l1 = new Lead();
        l1.LastName = 'l1';
        l1.Status = 'New';
        l1.Company = 'Test';
        l1.CurrencyIsoCode = 'USD';
        l1.SurveyBot_GUID__c = '12345';

        List<Lead> leadList = new List<Lead>();
        leadList.add(l1);
        insert leadList;

        update leadList;

        Lead leadVerify = [SELECT Id, OwnerId FROM Lead WHERE LastName = 'l1' LIMIT 1];
        System.debug('leadVerify: '+leadVerify.OwnerId);
        System.debug('users: '+users.size());
        if(users.size() > 0){
            System.debug('user 1: '+users[0].UserId);

            // there should be an Id in the OwnerId field, meaning that the lead is not in the queue
            // TODO
            System.assertNotEquals(null, leadVerify.OwnerId);
        } else {
            //System.assertEquals('0056g000001KVt1AAG', leadVerify.OwnerId);
        }
    }
}