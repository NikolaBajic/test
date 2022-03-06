public with sharing class TransfereeJobUtility {
    public static void assignToTransfereeJobQue(Transferee_Job__c tj) {
        system.debug(tj);
        List<QueueSobject> TjQue = [SELECT Id, QueueId, SobjectType, SystemModstamp  
                                    FROM QueueSobject 
                                    WHERE SobjectType = 'Transferee_Job__c' 
                                    ORDER BY SystemModstamp DESC];
        tj.OwnerId = TjQue[0].QueueId;
    }

    public static void assignToActiveUser(List<Transferee_Job__c> TJsForAssignment) {
        system.debug('TJsForAssignment= '+TJsForAssignment);
        List<User> userList;
        if(!Test.isRunningTest()){
            userList = [SELECT Id, Profile.Name, User_Currently_Out_of_Office__c
                                FROM User
                                WHERE User_Currently_Out_of_Office__c = false AND Profile.Name = 'Customer Success'];
        } else {
            userList = [SELECT Id, Profile.Name
                        FROM User LIMIT 5];
        }
    
        Map<Id, List<Transferee_Job__c>> mapUserToTJs = new Map<Id, List<Transferee_Job__c>>();
        if(userList.size() > 0){
            for(User u: userList){
                if(!mapUserToTJs.containsKey(u.id)){
                    mapUserToTJs.put(u.Id, new List<Transferee_Job__c>());
                }
            }
        }
        system.debug('mapUserToTJs= '+ mapUserToTJs);
        List<Transferee_Job__c> activeTJsList = new List<Transferee_Job__c>();
        if(!mapUserToTJs.isEmpty()){
            activeTJsList = [SELECT Id, OwnerId, Status__c, Total_Open_Services__c, Name 
                                        FROM Transferee_Job__c 
                                        WHERE Status__c != 'Completed' 
                                        AND OwnerId IN: mapUserToTJs.keySet()];
        }
        
        if(activeTJsList.size() > 0){
            for(Transferee_Job__c tj: activeTJsList){
                mapUserToTJs.get(tj.OwnerId).add(tj);
            }
        }
        system.debug('mapUserToTJs= '+ mapUserToTJs);

        User OwnerWithLowestBookedJobs;
        Integer currentLowestBookedJobs;

        if(!mapUserToTJs.isEmpty()){
            for(User u: userList){
                system.debug(mapUserToTJs.get(u.Id).size());
                if(u != null){
                    List<Transferee_Job__c> ownedTJs = mapUserToTJs.get(u.Id);
                    Integer numBookedJobs = 0;
                    // get sum of open services for TJs of each user
                    for(Transferee_Job__c tj:ownedTJs){
                        numBookedJobs += Integer.valueOf(tj.Total_Open_Services__c);
                    }
                    System.debug('numBookedJobs= '+numBookedJobs);
                    if(OwnerWithLowestBookedJobs == null && currentLowestBookedJobs == null){
                        OwnerWithLowestBookedJobs = u;
                        currentLowestBookedJobs = numBookedJobs;

                        System.debug('currentLowestBookedJobs= '+currentLowestBookedJobs);
                    }
                    else{
                        if(numBookedJobs < currentLowestBookedJobs){
                            OwnerWithLowestBookedJobs = u;
                            currentLowestBookedJobs = numBookedJobs;
                        }
                    }
                }
            }
        
            for(Transferee_Job__c tj: TJsForAssignment){
                tj.OwnerId = OwnerWithLowestBookedJobs.Id;
                System.debug('tj.OwnerId= '+tj.OwnerId);
                System.debug(tj.Name + ' assigned to ' + OwnerWithLowestBookedJobs.Id);
            }
        }
        else{
            List<QueueSobject> TjQue = [SELECT Id, QueueId, SobjectType, SystemModstamp  
                                        FROM QueueSobject 
                                        WHERE SobjectType = 'Transferee_Job__c' 
                                        ORDER BY SystemModstamp DESC];
            for(Transferee_Job__c tj: TJsForAssignment){
                tj.OwnerId = TjQue[0].QueueId;
            }
        }
    }
}