/** using old version file to do the testing **/
/** be caureful to clear out NULL data **/
%web_drop_table(WORK.CUS);

FILENAME REFFILE '/qt_home/wtao/sasuser.v94/cross_sell_TFSA_2020/TFSA_cus_full_84k_v2.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.CUS;
	GUESSINGROWS= 1000;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.CUS; RUN;
%web_open_table(WORK.CUS);


data WORK.CUS;
   set WORK.CUS;
   array change _character_;
        do over change;
            if change='NaN' then change=.;
        end;
    
    WSPRIMREAVG2 = input(WSPRIMREAVG, best16.);
run;









/***********************************************************************/
/* meta data generated */

%metagen(data=WORK.CUS,out=WORK.meta);





/** EA 1 **/
/** get subset of data to run **/

/* method 1: delete ws data */
data WORK.CUS2;
    set WORK.CUS;
    
    drop WS: ; /* drop all columns start with WS */
    drop EquityInCAD_rsp_01avg act_tfsa cross_p PostalCode CMANAMEE_1;
run;



/* method 2: keep only ceratin variable */
data WORK.CUS2;
    set WORK.CUS;
    
    keep target_tfsa PrimaryClientID PC_ref ACTIVE classtype Asset:  Equity:  join: Total: trade:
	CMANAMEE act_num age_1231 Income Liabilities LIQASTAVG LIQASTPEN LiquidAsset Margin_ind MaritalStatus
	MTD_1231 NetFixedAsset NetWorth province RRSP_ind wm_ind age_join 
	LIQASTPEN WSINVETFPEN	WSLIQORPEN
	WSMORTPEN WSPRIMREPEN WSSAVNGPEN WSSAVNTFPEN LIQASTAVG WSINVETFAVG
	WSLIQORAVG WSMORTAVG WSPRIMREAVG2 WSSAVNGAVG WSSAVNTFAVG
	;

    drop EquityInCAD_rsp_01avg join_date;
run;





proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;


data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 level $ 8 group 8;
    drop typenum;
    if typenum = 1 then type = 'N';
                   else type = 'C';
    if      name = 'target_tfsa'  	then role = 'TARGET';
    else if name in ('PrimaryClientID','PC_ref')   then role = 'ID';
    else do;
        role = 'INPUT';
        if type = 'N' then do;
            level = 'INTERVAL';
            group = 20;
        end;
        else do;
            level = 'FACTOR  ';
            group = 0;
        end;
    end;
run;

%ea1(data=WORK.CUS2, meta= WORK.tfsa_meta);



/** GNBC  **/
proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;

data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'target_tfsa'      		       then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PC_ref')       then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 20;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;


%gnbc5( data = WORK.CUS2,
        meta = WORK.tfsa_meta,
        out= tfsa_scored,
        metaout= work.metaout,
        code= '/qt_home/wtao/sasuser.v94/tfsa-gnbc-code41a.txt',
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);

/*
proc means data=__base;

    var _phat target_tfsa;
run;
*/ 
 
 
 
/*  KS test */
%KSROC( data=WORK.tfsa_scored, target= target_tfsa, prob=_phat,gbin=0.05);








/*********************************************************************************************/
/* step 2: look at ea1 rebin some input varaibles  */




data WORK.CUS2;
    set WORK.CUS;
    where classtype ~= 'IN' and Equity_1231 ~= . and Assetttl_txn_overal ~= .;
      
    keep target_tfsa PrimaryClientID PC_ref  classtype Asset:  Equity:  join: Total: trade:
	act_num age_1231 Income Liabilities LIQASTAVG LIQASTPEN LiquidAsset Margin_ind MaritalStatus
	MTD_1231 NetFixedAsset NetWorth province RRSP_ind wm_ind age_join 
	LIQASTPEN WSINVETFPEN	WSLIQORPEN
	WSMORTPEN WSPRIMREPEN WSSAVNGPEN WSSAVNTFPEN LIQASTAVG WSINVETFAVG
	WSLIQORAVG WSMORTAVG WSPRIMREAVG2 WSSAVNGAVG WSSAVNTFAVG 
	;

    drop EquityInCAD_rsp_01avg join_date EquityInCAD_lm_rec EquityInCAD_lq_rec Equity_today;
run;





































/*****************************************************************************/
/* groups of target :*/

data WORK.CUS2;
    set WORK.CUS;
    /*where classtype ~= 'IN' and Equity_1231 ~= . and Assetttl_txn_overal ~= . and cross_p in ('March','');*/  
     where classtype ~= 'IN' and Equity_1231 ~= . and Assetttl_txn_overal ~= . and cross_p in ('Jan_feb',''); 
     
    keep target_tfsa PrimaryClientID PC_ref  classtype Asset:  Equity:  join: Total: trade:
	act_num age_1231 Income Liabilities LIQASTAVG  LiquidAsset Margin_ind MaritalStatus
	MTD_1231 NetFixedAsset NetWorth province RRSP_ind wm_ind age_join 
	/* LIQASTPEN 	WSLIQORPEN WSSAVNGPEN */
	WSMORTPEN WSPRIMREPEN WSSAVNTFPEN WSINVETFPEN
	LIQASTAVG WSINVETFAVG
	WSLIQORAVG WSMORTAVG WSPRIMREAVG2 WSSAVNGAVG WSSAVNTFAVG 
	;

    drop EquityInCAD_rsp_01avg join_date EquityInCAD_lm_rec EquityInCAD_lq_rec Equity_today join_yr
    	 ;
    rename Equity_1231=Equity_t0  MTD_1231 = MTD_t0	 MTD_1231 = MTD_t0	 TotalAssets_lm = AssetsTotal_bal_t_1 	AssetsOut_lq = AssetsOut_bal_t_3
    	 age_1231 = age_t0	AssetsOut_lm= AssetsOut_bal_t_1		AssetsIn_txn_overal = AssetsIn_ct_overal	TotalAssets_overal=AssetsTotal_bal_overal
    	 trade_lm = trade_t_1;	
    
run;



/* EA1 for Jan-feb */

proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;


data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 level $ 8 group 8;
    drop typenum;
    if typenum = 1 then type = 'N';
                   else type = 'C';
    if      name = 'target_tfsa'  	then role = 'TARGET';
    else if name in ('PrimaryClientID','PC_ref')   then role = 'ID';
    else do;
        role = 'INPUT';
        if type = 'N' then do;
            level = 'INTERVAL';
            group = 20;
        end;
        else do;
            level = 'FACTOR  ';
            group = 0;
        end;
    end;
run;

%ea1(data=WORK.CUS2, meta= WORK.tfsa_meta);



/* GNBC for jan-feb */

proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;

data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'target_tfsa'      		       then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PC_ref')       then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 20;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;


%gnbc5( data = WORK.CUS2,
        meta = WORK.tfsa_meta,
        out= tfsa_scored_group,
        metaout= work.metaout_group,
        code= '/qt_home/wtao/sasuser.v94/tfsa-gnbc-code-v2.txt',
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);

%KSROC( data=WORK.tfsa_scored_group, target= target_tfsa, prob=_phat,gbin=0.05);















/**************************************/
/* 	cross- p      */
/*  testing method 2  */

data WORK.CUS2;
    set WORK.CUS;    
  
    where classtype ~= 'IN' and Equity_1231 ~= . and Assetttl_txn_overal ~= . and target_tfsa = 1; 
    
    If 	   cross_p = 'March'  then  cross_p2 = 1;
    else   			    cross_p2 = 0;

    keep  PrimaryClientID PC_ref  classtype Asset:  Equity:  join: Total: trade:
	 act_num age_1231 Income Liabilities LIQASTAVG LIQASTPEN LiquidAsset Margin_ind MaritalStatus
	MTD_1231 NetFixedAsset NetWorth province RRSP_ind wm_ind age_join 
	LIQASTPEN WSINVETFPEN	WSLIQORPEN
	WSMORTPEN WSPRIMREPEN WSSAVNGPEN WSSAVNTFPEN LIQASTAVG WSINVETFAVG
	WSLIQORAVG WSMORTAVG WSPRIMREAVG2 WSSAVNGAVG WSSAVNTFAVG
	cross_p2
	;    
      
    drop EquityInCAD_rsp_01avg join_date ;
run;



/* EA 1 */

proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;


data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 level $ 8 group 8;
    drop typenum;
    if typenum = 1 then type = 'N';
                   else type = 'C';
    if      name = 'cross_p2'  	then role = 'TARGET';
    else if name in ('PrimaryClientID','PC_ref')   then role = 'ID';
    else do;
        role = 'INPUT';
        if type = 'N' then do;
            level = 'INTERVAL';
            group = 20;
        end;
        else do;
            level = 'FACTOR  ';
            group = 0;
        end;
    end;
run;

%ea1(data=WORK.CUS2, meta= WORK.tfsa_meta);





/* GNBC  */
proc contents data=WORK.CUS2 out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;

data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'cross_p2'      		       		 then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PC_ref','cross_p')       then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 10;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;




%gnbc5( data = WORK.CUS2,
        meta = WORK.tfsa_meta,
     /*   out= tfsa_scored_group, */
        metaout= work.metaout_group,
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);




/***********************************************************************************************/
/* testing scoring */

proc surveyselect data=WORK.CUS2 out=WORK.CUS2tt method=srs samprate=0.70 outall seed=12345 noprint;
  samplingunit PrimaryClientID;
run;

data train;
   set WORK.CUS2tt;
   where selected =1 ;
run;

proc contents data=train out=WORK.tfsa_meta (keep=name type rename=(type=typenum)) noprint;
run;

data WORK.tfsa_meta;
    set WORK.tfsa_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'target_tfsa'       		       		 then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PC_ref','cross_p')       then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 10;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;



%gnbc5( data = WORK.train,
        meta = WORK.tfsa_meta,
     	 out= tfsa_scored_group, 
    	code= '/qt_home/wtao/sasuser.v94/tfsa-gnbc-code-v2.txt',
        metaout= work.metaout_group,
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);

%KSROC( data=WORK.tfsa_scored_group, target= target_tfsa, prob=_phat,gbin=0.05);


/* apply to test data */

data test;
   set WORK.CUS2tt;
   where selected = 0 ;
run;


data test_score; 
	set WORK.test;
	%inc '/qt_home/wtao/sasuser.v94/tfsa-gnbc-code-v2.txt'; 
run;

%KSROC( data=WORK.test_score, target= target_tfsa, prob=_phat,gbin=0.05);
%KSROC( data=WORK.tfsa_scored_group, target= target_tfsa, prob=_phat,gbin=0.05);







/************************************************************************************************************/
/**  scoring */
%web_drop_table(WORK.scoring_data);

FILENAME REFFILE '/qt_home/wtao/sasuser.v94/cross_sell_TFSA_2020/TFSA_cus_full_112k_1103.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.scoring_data;
	GUESSINGROWS= 1000;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.scoring_data; RUN;
%web_open_table(WORK.scoring_data);


data WORK.scoring_data;
    set WORK.scoring_data;
     
    keep target_tfsa PrimaryClientID PC_ref  classtype Asset:  Equity:  join:  trade:
	act_num age_t0 Income Liabilities LIQASTAVG  LiquidAsset Margin_ind MaritalStatus
	MTD_t0 NetFixedAsset NetWorth province RRSP_ind wm_ind age_join 
	/* LIQASTPEN 	WSLIQORPEN WSSAVNGPEN */
	WSMORTPEN WSPRIMREPEN WSSAVNTFPEN WSINVETFPEN
	LIQASTAVG WSINVETFAVG
	WSLIQORAVG WSMORTAVG WSPRIMREAVG2 WSSAVNGAVG WSSAVNTFAVG 
	;

    drop  join_date EquityInCAD_lm_rec EquityInCAD_lq_rec Equity_today join_yr
    	 ;

run;



data score; 
	set WORK.scoring_data;
	%inc '/qt_home/wtao/sasuser.v94/tfsa-gnbc-code41a.txt'; 
run; 

/* save file to permenant ,but in sas datafile*/
libname perm '/qt_home/wtao/sasuser.v94';

proc copy inlib=work outlib=perm ;
  select score;
run;



/* save file to permenant */
proc export data=score
    outfile='/qt_home/wtao/sasuser.v94/score.csv'
    dbms=csv
    replace;
run;
