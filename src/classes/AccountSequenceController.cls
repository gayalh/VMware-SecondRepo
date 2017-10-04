//*********************************************************************************************************************************************************
// Name             : AccountSequenceController.cls
// Description      : Class to Maintain the Sequence of trigger operations for Accounts
// Created By       : Accenture
// Created Date     : 08/22/2011

// ************************Version Updates*****************************************************************************************************************
// v1.1 - Accenture - Dated:  05/14/2012 Implemented ETM CR-00012188.
//        Changes made to re-order sequence for TA Dispute Unresolved Status
// Updated Date     Updated By          Update Comments 
//
// 17/04/2015       Khalid Ansari         ETM Upgrade - BUG-00118397 - Do not update territory to blank if a blank value is send by Informatica
// 9/06/2015        Khalid Ansari         ETM Upgrade - Moved BUG-00118397 to AccountSequenceController from Account to make sure the triggers 
//                                                      execution happens in correct sequence. This will resolve the issue of GEO/Region/Sub getting empty
// 07/06/2015       BHUMIKA UDANI        AIRWATCH CHANGES ADDED : afterUpdate 
//*********************************************************************************************************************************************************
public with sharing class AccountSequenceController {
    
    //Method to perform operation Sequentially
    public static void beforeUpdateAccounts(){
        
        //Creating Instance of ETM_ValidateTADisputeProcess 
        ETM_ValidateTADisputeProcess validateTADispute = new ETM_ValidateTADisputeProcess();
        
        // Creating instance for Locking mechanism for Multipicklict value
        ETM_AccountTerritoryLockingMechanism  lockingMechanism = new ETM_AccountTerritoryLockingMechanism();
       
        //Calling Validate Dispute method to fill the Dispute list - CR-00012188               
        validateTADispute.validateTerritoryFromDispute();

       
        // Creating method for Locking Mechanism
        lockingMechanism.ETM_LockingMechanism();

        //Creating Instance of ETM_AccountOwnerAssignmentEngine cls
        ETM_AccountOwnerAssignmentEngine acctOwnerAssignment = new ETM_AccountOwnerAssignmentEngine();
        
        //Calling method to reflect correct territories
        acctOwnerAssignment.updateProperTerritory();
        
        //Calls method to update Account type & Ownership
        acctOwnerAssignment.updateAccountTypeAndOwnership();
        
        //START - ETM Upgrade - Yet to be created - Khalid Ansari - Moved the logic of BUG-00118397 from Account trigger to AccountSequenceController
        //START - ETM Upgrade - BUG-00118397 - Khalid Ansari - Do not update territory to blank if a blank value is send by Informatica
        if (Trigger.isBefore && Trigger.isUpdate 
            && ETM_Do_Not_Delete_Territory_Values__c.getOrgDefaults().Target_Objects__c.contains('Account')
            && UserInfo.getUserName().contains('etmintegration@vmware.com.vmw')) {
    
            TAUtilities.revertINFABlankTerrUpdate_Account(trigger.oldMap, trigger.new);            
        }
        //END - ETM Upgrade - BUG-00118397 - Khalid Ansari - Do not update territory to blank if a blank value is send by Informatica
        //END - ETM Upgrade - Yet to be created - Khalid Ansari - Moved the logic of BUG-00118397 from Account trigger to AccountSequenceController
        
        //Calling method to update Geo Info
        acctOwnerAssignment.updateTerritoryInfo();
        //Modified as part of ETM Upgrade project
        TARealignmentPerformanceSwitch__c TAPerformance = TARealignmentPerformanceSwitch__c.getOrgDefaults();
        If(TAPerformance.Switch__c == FALSE){
            //Creating Instance of AccountSharingChange cls
            ETM_AccountSharingChange acctShareChange = new ETM_AccountSharingChange();
            
            //Calling methods to update share
            acctShareChange.getAccountForSharing();
            acctShareChange.updateAccountShare();
        }
        else{
           if(trigger.isupdate && trigger.isbefore)
           ETM_AccountSharingChangeUtility.markAccountsForTA(trigger.new);
        }
        //Calling method to update the Dispute list - CR-00012188
        validateTADispute.updateValidatedDisputeRecords();


    }
    /***********************************************************************************************
    Method Name: afterUpdate
    Description: Contains sequential logic for after update on account
    @Param: none
    @return: None
    @throws: none
    ***********************************************************************************************/
    public static void afterUpdate(){
        //START - BUG-00123983 - 07.06.2015 - BHUMIKA UDANI - UPDATE RESELLER / DISTRIBUTOR CONTACT DETAILS      
        AW_ConnectionUtility.checkValidAccount(trigger.oldMap, trigger.newMap);
        //END - BUG-00123983 - 07.06.2015 - BHUMIKA UDANI - UPDATE RESELLER / DISTRIBUTOR CONTACT DETAILS
    }
}