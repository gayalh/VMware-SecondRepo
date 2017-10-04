/**************************************************************************************************************
Name           : ACR_ReqByControllerTest
Decription     : Test class to cover ACR_ReqByController
Created by     : Accenture

Modified By          Modified Date             Comments 
Bhumika Udani        24.06.2015                added checkUpdate() coverage for RS2_AccountRequest_AfterUpdate 

**************************************************************************************************************/
@isTest(SeeAllData=false)
public class ACR_ReqByControllerTest{
    public static Account acc;
    public static Account_Request__c accReq2;
    public static List<Account_Request__c> newAccReqList = new List<Account_Request__c>();
    public static Account_Request__c accReq;
    public static Account_Request__c accReq3;
    public static Account_Request__c accReq4;
    public static Deal_Registration__c dealreg; 
    
    public static void setupData1(){
        AW_ConnectionUtilityDataFactory.createCustomSettings();
        if((XFIRE_Config_Settings__c.getAll()).IsEmpty()){
            XFire_TestDataFactory.createXfireConfigSettingsData();
        }

        if(Record_Type_Settings__c.getInstance('Lead_XSUS') == null || Record_Type_Settings__c.getInstance('Lead_Vmware_Record_Type') == null || Record_Type_Settings__c.getInstance('XSUS_Cross_Sell_Up_Sell_Renewals') == null){
            XFire_TestDataFactory.createRecordType();
        }

        if((Xfire_Lead_PullBack_Configuration__c.getAll()).IsEmpty()){
            XFire_TestDataFactory.createXfireLeadPullBackConfiguration(); 
        }

        if((XFire_Product__c.getAll()).IsEmpty()){
            XFire_TestDataFactory.createXfireTargetedProductData();
        }

        if((XfireCampaginProdMapping__c.getAll()).IsEmpty()){
            XFire_TestDataFactory.cretaeXfireCampProdMapping();
        }
        
        XFire_TestDataFactory.createDaaS_Call_Geo_Switch_ORTN();
        
        XFire_TestDataFactory.createXFire_Project_Switch();
        

        ID recTypeAccountId = Id.valueOf(Record_Type_Settings__c.getInstance('SFA_Acc_EC').Record_Type_ID__c);
        acc = new Account (Name  = 'VMW Test Distributor - AMER - Test',Country__c = 'UNITED STATES',Geo__c = 'AMER',Region__c = 'North America',Zip_Postal_Code__c = '11111113',Address_1_del__c = 'Test Address',City__c = 'Chicago',State__c = 'CA',RecordTypeId=recTypeAccountId);

        insert acc;
        
        dealreg = new Deal_Registration__c (GEO__c = 'EMER',Country__c = 'India', Project_Name__c = 'TestDeal',Campaign_Name__c = 'Partner Led Activity (non-MDF)',CloseDate__c = Date.today()+2 ,Is_Account_Request__c = true);
        insert dealreg;

        accReq = new Account_Request__c ( Account_Name__c = 'Test',Additional_Name__c = 'Test',Address_1__c = 'Test',City__c = 'Pune'  ,Country__c='India',State_Other__c='Maharashtra' ,Account_Name_Native_Language__c='Test',Address_2__c='Testing', Postal_Code__c = '123456',State_Province__c = 'Maharashtra',Industry__c='Agriculture');
        accReq2 = new Account_Request__c (Existing_Account_Name__c=acc.id,DA_Account_Name__c=acc.id,DS_Account_Name__c=acc.id);       
        accReq3 = new Account_Request__c ( Account_Name__c = 'Test1',Additional_Name__c = 'Test1',Address_1__c = 'Testnew',City__c = 'Pune',Country__c='India',State_Other__c='Maharashtra' ,Account_Name_Native_Language__c='Test1',Address_2__c='Testing1',Postal_Code__c = '123456',State_Province__c = 'Maharashtra',Industry__c='Agriculture',ConvertedRegistrationId__c = dealreg.Id);
        
        newAccReqList.add(accReq);
        newAccReqList.add(accReq2);
        newAccReqList.add(new Account_Request__c ( Request_Process__c = RS2_OI_Static_Values__c.getInstance('Request Process').Value__c , Account_Name__c = 'Test',Additional_Name__c = 'Test',Address_1__c = 'Test',City__c = 'Pune'  ,Country__c='India',State_Other__c='Maharashtra' ,Account_Name_Native_Language__c='Test',Address_2__c='Testing', Postal_Code__c = '123456',State_Province__c = 'Maharashtra',Industry__c='Agriculture'));
        
        insert newAccReqList;       
        
        insert accReq3;
        accReq3.Address_1__c ='test_new';
        accReq3.Request_Process__c = 'Deal Registration';
        accReq3.Request_Status__c = 'Cancelled';
        
        update accReq3;
       
       /*accReq4 = new Account_Request__c ( Account_Name__c = 'Test1',Additional_Name__c = 'Test1',Address_1__c = 'Testmodified',City__c = 'Pune'        
                ,Country__c='India',State_Other__c='Maharashtra' ,Account_Name_Native_Language__c='Test1',Address_2__c='Testing1',
                Postal_Code__c = '123456',State_Province__c = 'Maharashtra',Industry__c='Agriculture',Request_Process__c = 'Deal Registration',
                Request_Status__c = 'Cancelled');
       insert accReq4 ;*/
       
       
    }    

    static testMethod void myUnitTest1() { 
        setupData1();
        List<String> ListAccountRequestId = new List<String>();
        ListAccountRequestId.add(newAccReqList[0].Id);
        String accountId = acc.Id;
        
        Test.startTest();
        accReq.Account_Name__c = 'Test new';
        update accReq;
        ACR_ReqByController.populateRequestedBy(newAccReqList);
        ACR_ReqByController.acceptAccReqFromQueue(ListAccountRequestId);
        ACR_ReqByController.createAccountRequest(accountId);
        
        Test.stopTest();
    
    }
    /***********************************************************************************************
    Method Name: checkUpdate
    Description: Covers AW updates to RS2_AccountRequest_AfterUpdate 
    @Param: None
    @return: None
    @throws: none
    ***********************************************************************************************/
    static testMethod void checkUpdate(){
        setupData1();       
        accReq.Request_Status__c = 'Validate';
        accReq.System_Source__c = AWStaticValues__c.getInstance('ARSource').Value__c;  
        
        
        update accReq;
        //System.assertEquals(accReq.System_Source__c,'Airwatch (SFDC)');
        System.assertEquals(accReq.System_Source__c, AWStaticValues__c.getInstance('ARSource').Value__c);
        System.assertEquals(accReq.Request_Status__c, 'Validate');
        accReq.Request_Status__c = 'In Progress';     
        accReq.Data_Validation_Source__c = 'Source System';
        accReq.Request_Disposition__c = 'Created in Source';
        accReq.DS_Account_Name__c = acc.id;        
        update accReq;
        
        accReq.Request_Status__c = 'Completed';               
        
        Test.startTest();
        update accReq;        
        System.assertEquals(accReq.Request_Status__c, 'Completed');
        Test.stopTest();
    
    }
}