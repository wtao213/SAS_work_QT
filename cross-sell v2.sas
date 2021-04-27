/* read the data */
libname md '/qt_home/wtao/lib/';

proc datasets library=md kill nolist;
quit;


FILENAME REFFILE '/qt_home/wtao/proj/model/QWP_xsell/qwp_cross_sell_20210315_407k.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=md.CUS;
	GUESSINGROWS= 1000;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=md.CUS; RUN;



/* remove and format the columns*/ 
data md.CUS2;
   set md.CUS;
   array change _character_;
        do over change;
            if change='NaN'  then change=.;
			if change='NULL' then change=.;
        end;
    
   array conv{*} $ EquityInCAD -- Liabilities  EquityInCAD_t_1 -- trade_t_3;
   array conv2{*}  EquityInCAD_2 Income_2 LiquidAsset_2 NetFixedAsset_2 NetWorth_2 Liabilities_2   
	EquityInCAD_t_1_2	EquityInCAD_t_1_rec_2	EquityInCAD_t_2_2	EquityInCAD_t_2_rec_2
	EquityInCAD_t_3_2 EquityInCAD_t_3_rec_2	EquityInCAD_t_3_diff_2
	AssetIn_bal_t_1_2	AssetsIn_ct_t_1_2	AssetsOut_bal_t_1_2	Assetttl_ct_t_1_2	AssetsTotal_bal_t_1_2
	AssetIn_bal_t_3_2	AssetsIn_ct_t_3_2	AssetsOut_bal_t_3_2	Assetttl_ct_t_3_2	AssetsTotal_bal_t_3_2
	trade_t_1_2	trade_t_3_2
;
	   do i=1 to dim(conv);
	    	conv2{i} = input(conv{i},best12.);
	   end;
	drop i EquityInCAD -- Liabilities  EquityInCAD_t_1 -- trade_t_3;
run;






/**********************************************/
/* part 1: meta data check */
/**********************************************/
/* meta data generated */

%metagen(data=md.CUS2,out=md.meta);

/* save file to permenant */
proc export data= md.meta
    outfile='/qt_home/wtao/sasuser.v94/qwp_meta.csv'
    dbms=csv
    replace;
run;

/* target check , base rate 5.62%*/
proc freq data= md.cus;
 table target_qwp  ;
run;




/********************************************************/
/* run EA1		*/

/*  keep only ceratin variable */
data md.CUS2;
    set md.CUS2;
    
    keep target_qwp PrimaryClientID PostalCode ACTIVE 
	Asset:  Equity:  join: trade:
	act_num age_today Income_2 Liabilities_2 LiquidAsset_2 Margin_ind MaritalStatus
	MTD tenure NetFixedAsset_2 NetWorth_2 province RRSP_ind wm_ind age_join 
	;

    drop wm_ind classtype ;
run;



/* prepare for the EA 1*/
proc contents data= md.CUS2 out= md.qwp_meta (keep=name type rename=(type=typenum)) noprint;
run;


data md.qwp_meta;
    set md.qwp_meta;
    length type $ 1 role $ 6 level $ 8 group 8;
    drop typenum;
    if typenum = 1 then type = 'N';
                   else type = 'C';
    if      name = 'target_qwp'  	then role = 'TARGET';
    else if name in ('PrimaryClientID','PostalCode')   then role = 'ID';
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


%ea1(data= md.CUS2, meta= md.qwp_meta);







/***************************************/
/* part 3: GNBC    */
data md.CUS2;
    set md.CUS2;
   
    drop act_num  trade_t_3_2 trade_t_1_2;
run;

proc contents data= md.CUS2 out= md.qwp_meta (keep=name type rename=(type=typenum)) noprint;
run;

data md.qwp_meta;
    set md.qwp_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'target_qwp'      		      		 then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PostalCode')     then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 20;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;


%gnbc5( data = md.CUS2,
        meta = md.qwp_meta,
        out= qwp_scored,
        metaout= md.metaout,
        code= '/qt_home/wtao/proj/model/QWP_xsell/qwp-gnbc-code1a.txt',
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);

/*  KS test */
%KSROC( data= md.qwp_scored, target= target_qwp, prob=_phat,gbin=0.05);

/*
proc means data=__base;
    var _phat target_tfsa;
run;
*/ 
 
/*  KS test */
%KSROC( data= md.qwp_scored, target= target_qwp, prob=_phat,gbin=0.05);





















/**********************************************/
/* part 4: target/non target adjustment 	 */
/*		  1. remove only 1 wm acct as one 
		  2.Equity >= $500									*/
/**********************************************/

data md.CUS2;
	set md.CUS2;

	where EquityInCAD_2 >= 500;

	If act_num =1 and classtype ='WM' then delete;
run;


/* in new criteria, base rate is 4.38% for 360k clietns */
proc freq data= md.cus2;
 table target_qwp  ;
run;


/* run EA1		*/

/*  keep only ceratin variable */
data md.CUS2;
    set md.CUS2;
    
    keep target_qwp PrimaryClientID PostalCode ACTIVE 
	Asset:  Equity:  join: trade:
	act_num age_today Income_2 Liabilities_2 LiquidAsset_2 Margin_ind MaritalStatus
	MTD tenure NetFixedAsset_2 NetWorth_2 province RRSP_ind wm_ind age_join 
	;

    drop wm_ind classtype ;
run;



/* prepare for the EA 1*/
proc contents data= md.CUS2 out= md.wm_meta (keep=name type rename=(type=typenum)) noprint;
run;


data md.wm_meta;
    set md.wm_meta;
    length type $ 1 role $ 6 level $ 8 group 8;
    drop typenum;
    if typenum = 1 then type = 'N';
                   else type = 'C';
    if      name = 'target_qwp'  	then role = 'TARGET';
    else if name in ('PrimaryClientID','PostalCode')   then role = 'ID';
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


%ea1(data= md.CUS2, meta= md.wm_meta);


/***************************************/
/* part : GNBC    */
data md.CUS2;
    set md.CUS2;
   
    drop act_num  trade_t_3_2 trade_t_1_2;
run;

proc contents data= md.CUS2 out= md.wm_meta (keep=name type rename=(type=typenum)) noprint;
run;

data md.wm_meta;
    set md.wm_meta;
    length type $ 1 role $ 6 scale $ 5 group smooth 8;
    drop typenum;

    if typenum = 1 	 then type = 'N';
                         else type = 'C';

    if      name = 'target_qwp'      		      		 then role = 'TARGET';       /*  Choose TARGET   */
    else if name in ('PrimaryClientID','PostalCode')     then role = 'ID';               /*  Choose ID       */
    else do;                                                                /*  Choose INPUT    */
        role        = 'INPUT';
        group       = 20;
        smooth      = 0.6;
        scale       = 'RANKS';
    end;
run;


%gnbc5( data = md.CUS2,
        meta = md.wm_meta,
        out= md.qwp_scored,
        metaout= md.metaout,
        code= '/qt_home/wtao/proj/model/QWP_xsell/qwp-gnbc-code2a-no-wmonly.txt',
        method=gnbc, ba_iter=10, selection=backward fast, maxvar=20, relwald=0.01
);

/*  KS test */
%KSROC( data= md.qwp_scored, target= target_qwp, prob=_phat,gbin=0.05);

/*
proc means data=__base;
    var _phat target_tfsa;
run;
*/ 
 
/*  KS test */
%KSROC( data= md.qwp_scored, target= target_qwp, prob=_phat,gbin=0.05);






/***************************************************/
/* 				customer profile 				   */
/***************************************************/
proc sort data= md.cus2;
	by PrimaryClientID;
run;


proc sort data= md.qwp_scored;
	by PrimaryClientID;
run;


data md.cus3;
 merge md.cus2(in=a) md.qwp_scored(in=b);
 by PrimaryClientID;

 If a and b;
run;



/* get ranking for the probability */
proc rank data= md.cus3 out= md.qwp_scored descending groups=10;
	var 	_phat;
	ranks 	rank;
run;




/*  			*/
proc summary data= md.qwp_scored;
 class rank ;
 var _phat  target_qwp MTD age_today RRSP_ind MTD EquityInCAD_t_3_diff_2 Income_2 EquityInCAD_t_3_2
	Margin_ind LiquidAsset_2 EquityInCAD_t_2_rec_2 NetFixedAsset_2 AssetsTotal_bal_t_1_2;
 output  out=md.profile sum(target_qwp)=  mean= median= /autoname;
run;
