@isTest
private class TransfereeJobUtilityTest {
    @isTest(SeeAllData=true) static void assignToTransfereeJobQue() {
        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        Transferee_Job__c tj2 = new Transferee_Job__c();
        tj2.Name = 'TestTj2';
        tj2.Opportunity__c = opp1.Id;
        tj2.Account__c = acc1.Id;
        tj2.Primary_Contact__c = con1.Id;
        tj2.Status__c = 'In Storage';
        tj2.Assigned_Location__c = 'International';
        insert tj2;
        System.debug('OwnerId: '+ tj2.OwnerId);
        System.assertEquals(null, tj2.OwnerId);
    }

    @isTest(SeeAllData=true) static void assignToActiveUser() {
        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        Contact con1 = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> users = [SELECT Id, Profile.Name, User_Currently_Out_of_Office__c
                                    FROM User
                                    WHERE User_Currently_Out_of_Office__c = false AND Profile.Name = 'Customer Success'
                                    ORDER BY Id Desc LIMIT 1];

        Transferee_Job__c tj1 = new Transferee_Job__c();
        tj1.Name = 'TestTj';
        tj1.Opportunity__c = opp1.Id;
        tj1.Account__c = acc1.Id;
        tj1.Primary_Contact__c = con1.Id;
        tj1.Status__c = 'In Storage';
        tj1.Assigned_Location__c = 'Belgrade';
        List<Transferee_Job__c> tjList = new List<Transferee_Job__c>();
        tjList.add(tj1);
        insert tjList;
        System.debug('2OwnerId: '+ tj1.OwnerId);
        Transferee_Job__c tjVerify = [SELECT Id, OwnerId FROM Transferee_Job__c WHERE Name = 'TestTj' LIMIT 1];
        if(users.size() > 0){
            // there should be an Id in the OwnerId field, meaning that the TJ is not in the queue
            System.assertNotEquals(null, tjVerify.OwnerId);
        } else {
            System.assertEquals('0056g000003ObuHAAS', tjVerify.OwnerId);
        }
    }
}