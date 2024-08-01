GetInputDates: {[input.start.date; input.end.date]
    dates: {[n] {x+2000.01.01}each n}[til (.z.d-2000.01.01)]; /get all days til yesterday
    calendar: desc raze (`mon;`tue;`wed;`thur;`fri)!(dates where ((5+til count dates) mod 7)= 0;dates where ((4+til count dates) mod 7)= 0;dates where ((3+til count dates) mod 7)= 0;dates where ((2+til count dates) mod 7)= 0;dates where ((1+til count dates) mod 7)= 0);
    calendar: calendar where calendar <= input.end.date;
    :0N 3#calendar 1 + til calendar?last calendar where calendar>=input.start.date;
    }
calendar: GetInputDates[2024.05.01;2024.05.31];


//Constant Values
input.symbols :`;
input.startTime : 09:30:00.000;
input.endTime : 16:00:00.000;
input.columnsT : `sym`time`volume`price`total_value`listing_mkt`event`sequence_number`mkt`s_short`s_short_marking_exempt`b_short_marking_exempt`s_user_name`b_user_name`b_po_name`s_po_name`s_program_trade`b_type`s_type`b_market_maker`s_market_maker`b_active_passive`s_active_passive`trade_stat`trade_correction`s_dark`b_dark;
input.columnsQ : `sym`listing_mkt`mkt`time`nat_best_bid`nat_best_offer`nat_best_bid_size`nat_best_offer_size`ask_price`bid_price;
input.tableQ : `quote;
input.tableT : `trade;
input.applyFilter : (); 



//Create empty table to store results
output.cols: `date`mkt`sym`listing_mkt`maxbid`min_ask`last_bid`last_ask`last_mid_price`total_volume`total_value`vwap`adv`range`maxprice`minprice`last_price`num_of_trades`num_of_block_trades`block_volume`block_value`dark_volume`dark_value`num_of_dark_trades`short_volume`total_short_value`num_of_short_trades`twap_closing_price`dqs`pqs`num_quotes`des_k`pes_k`wmid`volumebuy`volumesell`orderbookimbalance`realized_vol`drs_k_1m`prs_k_1m`drs_k_5m`prs_k_5m`dpi_k_1m`ppi_k_1m`dpi_k_5m`ppi_k_5m;
dailyliqmet: flip (output.cols)!(`date$();`symbol$();`symbol$();`symbol$();`float$();`float$();`float$();`float$();`float$();`long$();`float$();`float$();`float$();`float$();`float$();`float$();`float$();`long$();`long$();`long$();`float$();`long$();`float$();`long$();`long$();`float$();`long$();`float$();`float$();`float$();`long$();`float$();`float$();`float$();`long$();`long$();`float$();`float$();`float$();`float$();`float$();`float$();`float$();`float$();`float$();`float$());
//Inititate while loop
i:0;
while[i<count[calendar];
    //Get Pairs in right order for Kalman Filter
    input.startDate: last calendar[i];
    input.endDate: first calendar[i];
    
    //Get Trade Data
    getData.edwT: `..getTicks[`assetClass`dataType`symList`startDate`endDate`startTime`endTime`columns`applyFilter!(`equity;
        input.tableT;
        input.symbols;
        input.startDate;input.endDate;
        input.startTime;input.endTime;
        input.columnsT;
        input.applyFilter)];
    
    //Filter Trade Data
    Trades: .mapq.summarystats.filtertrades getData.edwT;
    
    {[t] ![t;enlist(>;`i;-1);0b;`$()]} each `getData.edwT; /delete all records for tables in memory
    
    //Get Quote Data
    getData.edwQ: `..getTicks[`assetClass`dataType`symList`startDate`endDate`startTime`endTime`columns`applyFilter!(`equity;
        input.tableQ;
        input.symbols;
        input.startDate;input.endDate;
        input.startTime;input.endTime;
        input.columnsQ;
        input.applyFilter)];
    
    //Filter Quote Data
    Quotes: .mapq.summarystats.filterquotes getData.edwQ;
    
    {[t] ![t;enlist(>;`i;-1);0b;`$()]} each `getData.edwQ; /delete all records for tables in memory

    //Execute functions
    
    summarystatsquotes_natbidask: .mapq.summarystats.summarystatsquotes[Quotes; `nat_best_bid`nat_best_offer; input.startTime;input.endTime]; //summary stats quotes
   
    summarystats_trades: .mapq.summarystats.summarystatstrades[Trades; input.startTime;input.endTime]; //summary stats trades
    
    twap_natbidask: .mapq.summarystats.twapcprice[Quotes;`nat_best_bid`nat_best_offer;15:50:00.000; input.endTime]; //Time-Weigthed Average Price over Period of Time
      
    
    qs_natbidask: .mapq.summarystats.qs[Quotes;`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //Quoted Spreads
    
    es: .mapq.summarystats.es[.mapq.summarystats.tradesnquotes[Trades;Quotes];`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //Effective Spreads
    
    short_trades: .mapq.summarystats.shorttrades[Trades;input.startTime;input.endTime]; //Short Trade Statistics
    
    orderbook_depth: .mapq.summarystats.midorderbook[Quotes;`nat_best_bid`nat_best_offer`nat_best_bid_size`nat_best_offer_size;input.startTime;input.endTime]; //orderbook depth
    
    rs_1m: `date`mkt`sym`listing_mkt`drs_k_1m`prs_k_1m xcol .mapq.summarystats.rs[Trades;Quotes;00:01:00.000;`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //realized spreads
    rs_5m: `date`mkt`sym`listing_mkt`drs_k_5m`prs_k_5m xcol .mapq.summarystats.rs[Trades;Quotes;00:05:00.000;`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //realized spreads

    pi_1m: `date`mkt`sym`listing_mkt`dpi_k_1m`ppi_k_1m xcol .mapq.summarystats.pi[Trades;Quotes;00:01:00.000;`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //price impact
    pi_5m: `date`mkt`sym`listing_mkt`dpi_k_5m`ppi_k_5m xcol .mapq.summarystats.pi[Trades;Quotes;00:05:00.000;`nat_best_bid`nat_best_offer;input.startTime;input.endTime]; //price impact
    
    orderbook_imbalance: .mapq.summarystats.orderbookimbalance[Trades; input.startTime; input.endTime]; //orderbook_imbalance
    
    r_volatitlity: .mapq.summarystats.realizedvolatility[Trades;input.startTime;input.endTime]; //realized volatility
    
    {[t] ![t;enlist(>;`i;-1);0b;`$()]} each `Trades`Quotes; /delete all records for tables in memory
    
    //Join Liquidity metrics and Append Results to empty table
    dailyliqmet,: 0!(uj/)(summarystatsquotes_natbidask;summarystats_trades;short_trades;twap_natbidask;qs_natbidask;es;orderbook_depth;orderbook_imbalance;r_volatitlity;rs_1m;rs_5m;pi_1m;pi_5m);
    
    //Sleep 8 munites to bypass timeout
    {t:.z.p;while[.z.p<t+x]} 00:05:00;  

    //Iterate again
    i+: 1;
    ];

\\Constant Values order data
input.symbols :`ABTC`ABTC.U`ACAA`AGLB`AGSG`ALFA`APLY`ARB`ARKG`ARKK`ARKW`ATSX`AUGB.F`BANK`BASE`BASE.B`BBIG`BBIG.U`BDEQ`BDIC`BDIV`BDOP`BEPR`BEPR.U`BESG`BFIN`BFIN.U`BGC`BGU`BGU.U`BHAV`BILT`BITC`BITC.U`BITI`BITI.U`BKCC`BKL.C`BKL.F`BKL.U`BLCK`BLDR`BLOV`BMAX`BNC`BND`BPRF`BPRF.U`BREA`BRKY`BSKT`BTCC`BTCC.B`BTCC.J`BTCC.U`BTCQ`BTCQ.U`BTCX.B`BTCX.U`BTCY`BTCY.B`BTCY.U`BUFR`BXF`CACB`CAFR`CAGG`CAGS`CALL`CALL.B`CALL.U`CAN`CAPS`CAPS.B`CAPS.U`CARB`CARS`CARS.B`CARS.U`CASH`CBAL`CBCX`CBGR`CBH`CBIL`CBND`CBNK`CBO`CBON`CBON.U`CBUG`CCBI`CCDN`CCEI`CCLN`CCNS`CCOM`CCOR`CCOR.B`CCOR.U`CCRE`CCX`CDEF`CDIV`CDLB`CDLB.B`CDLB.U`CDNA`CDZ`CED`CEMI`CES`CES.B`CESG`CESG.B`CEW`CFLX`CFRT`CGAA`CGBI`CGDV`CGDV.B`CGHY`CGHY.U`CGIN`CGIN.U`CGL`CGL.C`CGLO`CGR`CGRA`CGRB`CGRB.U`CGRE`CGRN`CGRN.U`CGRO`CGXF`CGXF.U`CHB`CHCL.B`CHNA.B`CHPS`CHPS.U`CIBR`CIC`CIE`CIEH`CIEI`CIEM`CIEM.U`CIF`CINC`CINC.B`CINC.U`CINF`CINT`CINV`CINV.U`CJP`CLF`CLG`CLML`CLML.U`CLMT`CLU`CLU.C`CMAG`CMAG.U`CMAR`CMAR.U`CMCE`CMCX.B`CMCX.U`CMDO`CMDO.U`CMEY`CMEY.U`CMGG`CMGG.U`CMR`CMUE`CMUE.F`CMVX`CNAO`CNAO.U`CNCC`COMM`COPP`COW`CPD`CPLS`CQLC`CQLI`CQLU`CRED`CRED.U`CROP`CROP.U`CRQ`CRYP`CRYP.B`CRYP.U`CSAV`CSBA`CSBG`CSBI`CSCB`CSCE`CSCP`CSD`CSGE`CSY`CTIP`CUD`CUDV`CUDV.B`CUEH`CUEI`CUSA.B`CUSM.B`CUTL`CUTL.B`CVD`CWO`CWW`CXF`CYBR`CYBR.B`CYBR.U`CYH`DAMG`DAMG.U`DANC`DANC.U`DATA`DATA.B`DCC`DCG`DCP`DCS`DCU`DFC`DFD`DFE`DFU`DGR`DGR.B`DGRC`DISC`DIVS`DLR`DLR.U`DQD`DQI`DRCU`DRFC`DRFD`DRFE`DRFG`DRFU`DRMC`DRMD`DRME`DRMU`DSAE`DWG`DXB`DXC`DXDB`DXEM`DXET`DXF`DXG`DXIF`DXM`DXN`DXO`DXP`DXQ`DXR`DXU`DXV`DXW`DXZ`EAAI`EAAI.U`EAFT`EAFT.U`EAGB`EAGB.U`EARK`EARK.U`EARN`EAUT`EAUT.U`EAXP`EAXP.U`EBIT`EBIT.U`EBNK`EBNK.B`EBNK.U`EDGE`EDGE.U`EDGF`EGIF`EHE`EHE.B`ELV`EMV.B`ENCC`EPCA`EPCA.U`EPCH`EPCH.U`EPGC`EPGC.U`EPWR`EPZA`EPZA.U`EQE`EQE.F`EQL`EQL.F`EQL.U`ERCV`ERDO`ERDV`EREO`EREV`ERFO`ERFV`ERGO`ESG`ESG.F`ESGA`ESGB`ESGC`ESGE`ESGF`ESGG`ESGH`ESGH.F`ESGY`ESGY.F`ESPX`ESPX.B`ETAC`ETC`ETC.U`ETHH`ETHH.B`ETHH.J`ETHH.U`ETHI`ETHQ`ETHQ.U`ETHR`ETHR.U`ETHX.B`ETHX.U`ETHY`ETHY.B`ETHY.U`ETP`ETP.A`ETSX`EUR`EUR.A`FAI`FBAL`FBCN`FBE`FBGO`FBT`FBTC`FBTC.U`FBU`FCCB`FCCD`FCCL`FCCM`FCCQ`FCCV`FCGB`FCGB.U`FCGC`FCGI`FCGS`FCGS.U`FCHH`FCHY`FCID`FCIG`FCIG.U`FCII`FCIL`FCIM`FCIQ`FCIQ.U`FCIV`FCLC`FCLH`FCMH`FCMI`FCMO`FCMO.U`FCNS`FCQH`FCRH`FCRR`FCRR.U`FCSB`FCSI`FCSW`FCUD`FCUD.U`FCUH`FCUL`FCUL.U`FCUQ`FCUQ.U`FCUV`FCUV.U`FCVH`FDE`FDE.A`FDL`FDN`FDN.F`FDV`FEBB.F`FEQT`FETH`FETH.U`FGB`FGGE`FGO`FGO.U`FGRO`FGSG`FHB`FHG`FHG.F`FHH`FHH.F`FHI`FHI.B`FHI.U`FHIS`FHQ`FHQ.F`FIE`FIG`FIG.U`FINN`FINN.U`FINO`FINT`FIVE`FIVE.B`FIVE.U`FIXD`FJFB`FJFG`FLAM`FLB`FLBA`FLCD`FLCI`FLCP`FLDM`FLEM`FLGA`FLGD`FLI`FLJA`FLRM`FLSD`FLSL`FLUI`FLUR`FLUS`FLX`FLX.B`FLX.U`FMTV`FOUR`FPR`FQC`FSB`FSB.U`FSD`FSD.A`FSEM`FSF`FSL`FSL.A`FST`FST.A`FTB`FUD`FUD.A`FUT`FWCP`FXM`GBAL`GBND`GCBD`GCNS`GCSC`GDEP`GDEP.B`GDIV`GDPY`GDPY.B`GEQT`GGAC`GGEM`GGRO`GHD`GHD.F`GIGR`GIGR.B`GIQG`GIQG.B`GIQU`GIQU.B`GLC`GLCC`GLDE`GOGO`GPMD`GRNI`HAB`HAC`HAD`HADM`HAEB`HAF`HAJ`HAL`HARB`HARB.J`HARB.U`HARC`HAU`HAU.U`HAZ`HBA`HBAL`HBB`HBD`HBF`HBF.B`HBF.U`HBFE`HBG`HBG.U`HBGD`HBGD.U`HBIT`HBKD`HBKU`HBLK`HBU`HBUG`HCA`HCAL`HCB`HCBB`HCLN`HCN`HCON`HCRE`HDGE`HDIF`HDIV`HDOC`HEAL`HEB`HED`HEMB`HEMC`HERO`HERS`HERS.B`HESG`HEU`HEUR`HEW`HEWB`HFA`HFD`HFG`HFIN`HFMU`HFMU.U`HFP`HFR`HFT`HFU`HFY`HFY.U`HGC`HGD`HGGB`HGGG`HGM`HGR`HGRO`HGU`HGY`HHF`HHL`HHL.B`HHL.U`HHLE`HID`HID.B`HIG`HIG.U`HII`HISA`HISU.U`HIU`HIX`HLFE`HLIF`HLIT`HLPR`HMAX`HMJI`HMJR`HMJU`HMMJ`HMMJ.U`HMP`HMUS`HMUS.U`HND`HNU`HNY`HOD`HOG`HOU`HPF`HPF.U`HPR`HQD`HQD.U`HQU`HRA`HRAA`HRED`HRES`HREU`HRIF`HSAV`HSD`HSH`HSL`HSPN`HSPN.U`HSU`HSUV.U`HTA`HTA.B`HTA.U`HTAE`HTB`HTB.U`HTH`HUBL`HUBL.U`HUC`HUF`HUF.U`HUG`HUIB`HUL`HUL.U`HULC`HULC.U`HUM`HUM.U`HUN`HURA`HUTE`HUTL`HUTS`HUV`HUZ`HVAX`HWF`HXCN`HXD`HXDM`HXDM.U`HXE`HXEM`HXF`HXH`HXQ`HXQ.U`HXS`HXS.U`HXT`HXT.U`HXU`HXX`HYBR`HYDR`HYI`HYLD`HYLD.U`HZD`HZU`ICAE`ICPB`IDEF.B`IDIV.B`IEMB`IFRF`IGAF`IGB`IGCF`IGLB`IIAE`IICE`IICE.F`IITE`IITE.F`ILGB`ILV`ILV.F`INOC`INSR`IQD`IQD.B`ISIF`ISTE`ISTE.F`IUAE`IUAE.F`IUCE`IUCE.F`IUTE`IUTE.F`IWBE`IXTE`JAPN`JAPN.B`KILO`KILO.B`KILO.U`LDGR`LEAD`LEAD.B`LEAD.U`LIFE`LIFE.B`LIFE.U`LINK`LONG`LYCT`LYFR`MAYB.F`MBAL`MCKG`MCLC`MCON`MCSB`MCSM`MDIV`MDVD`MDVD.U`MEE`MEME.B`MESH`MEU`MFT`MGAB`MGB`MGRW`MGSB`MHCD`MHYB`MIND`MINF`MINN`MINT`MINT.B`MIVG`MJJ`MKB`MKC`MNU.U`MNY`MOM`MOM.F`MOM.U`MPCF`MPY`MREL`MTAV`MUB`MULC`MULC.B`MUMC`MUMC.B`MUS`MUSA`MUSC`MUSC.B`MWD`MWMN`MXU`NACO`NAHF`NALT`NBND`NCG`NDIV`NFAM`NGPE`NHYB`NINT`NNRG`NNRG.U`NOVB.F`NPRF`NREA`NRGI`NSAV`NSCB`NSCC`NSCE`NSGE`NSSB`NUBF`NUSA`NXF`NXF.B`NXF.U`NXTG`ONEB`ONEC`ONEQ`ORBT`ORBT.U`PAYF`PBD`PBI`PBI.B`PCF`PCON`PCOR`PDC`PDF`PDIV`PEU`PEU.B`PFAA`PFAE`PFCB`PFG`PFH.F`PFIA`PFL`PFLS`PFMN`PFMS`PFSS`PGB`PGL`PHE`PHE.B`PHR`PHW`PIB`PID`PIN`PINC`PINV`PLDI`PLV`PMIF`PMIF.U`PMM`PMNT`PPS`PR`PRA`PREF`PRP`PSA`PSB`PSU.U`PSY`PSY.U`PSYK`PTB`PUD`PUD.B`PXC`PXG`PXG.U`PXS`PXS.U`PXU.F`PYF`PYF.B`PYF.U`PZC`PZW`PZW.F`PZW.U`QAH`QBB`QBTL`QCB`QCD`QCE`QCH`QCLN`QCN`QDX`QDXB`QDXH`QEBH`QEBL`QEE`QEF`QEM`QGB`QGL`QHY`QIE`QIF`QINF`QMA`QMY`QQC`QQC.F`QQCC`QQCE`QQCE.F`QQEQ`QQEQ.F`QQJE`QQJE.F`QQJR`QQJR.F`QRET`QSB`QTIP`QUB`QUDV`QUIG`QUS`QUU`QUU.U`QXM`RATE`RBDI`RBNK`RBO`RBOT`RBOT.U`RCAN`RCD`RCDB`RCDC`RCE`RCEI`RCSB`RCUB`RDE`REEM`REIT`REM`REMD`RENG`RGPM`RGQQ`RGQR`RGRE`RID`RID.U`RIDH`RIE`RIE.U`RIEH`RIFI`RIG`RIG.U`RIGU`RIIN`RINT`RIRA`RIT`RLB`RLD`RLDR`RLE`RMBO`RNAG`RNAV`RPD`RPD.U`RPDH`RPF`RPS`RPSB`RPU`RPU.B`RPU.U`RQG`RQH`RQI`RQJ`RQK`RQL`RQN`RQO`RQP`RQQ`RQR`RTA`RTEC`RUBH`RUBY`RUBY.U`RUD`RUD.U`RUDB`RUDB.U`RUDC`RUDH`RUE`RUE.U`RUEH`RUSA`RUSB`RUSB.U`RWC`RWE`RWE.B`RWU`RWU.B`RWW`RWW.B`RWX`RWX.B`RXD`RXD.U`RXE`RXE.U`SBCM`SBCV`SBEA`SBQM`SBQV`SBT`SBT.B`SBT.U`SCAD`SCGI`SCGR`SEED`SFIX`SHC`SHE`SHZ`SID`SINT`SITB`SITC`SITE`SITI`SITU`SIXT`SKYY`SLVE`SLVE.U`SRIB`SRIC`SRII`SRIU`STPL`SUSA`SVR`SVR.C`SYLD`TBNK`TCBN`TCLB`TCLV`TCSB`TDB`TDOC`TDOC.U`TEC`TEC.U`TECE`TECE.B`TECE.U`TECH`TECH.B`TECH.U`TECI`TECX`TERM`TGED`TGED.U`TGFI`TGGR`TGRE`THE`THNK`THU`TIF`TILV`TIME`TINF`TIPS`TIPS.F`TIPS.U`TLF`TLF.U`TLV`TMCC`TMEC`TMEI`TMEU`TMUC`TOCA`TOCC`TOCM`TOWR`TPAY`TPE`TPRF`TPU`TPU.U`TQCD`TQGD`TQGM`TQSM`TRVI`TRVL`TRVL.U`TTP`TUED`TUED.U`TUEX`TUHY`TULB`TULV`TUSB`TUSB.U`TXF`TXF.B`TXF.U`UBIL.U`UDA`UDEF`UDEF.B`UDEF.U`UDIV`UDIV.B`UDIV.U`UHD`UHD.F`UHD.U`ULV.C`ULV.F`ULV.U`UMI`UMI.B`USB`USB.U`USCC`USCC.U`USMJ`UTIL`UXM`UXM.B`VA`VAB`VAH`VALT`VALT.B`VALT.U`VBAL`VBG`VBU`VCB`VCE`VCIP`VCN`VCNS`VDU`VDY`VE`VEE`VEF`VEH`VEQT`VFV`VGAB`VGG`VGH`VGRO`VGV`VI`VIDY`VIU`VLB`VLQ`VMO`VRE`VRIF`VSB`VSC`VSG`VSP`VUN`VUS`VVL`VVO`VXC`VXM`VXM.B`WOMN`WSGB`WSHR`WSRD`WSRI`WXM`XAGG`XAGG.U`XAGH`XAW`XAW.U`XBAL`XBB`XBM`XCB`XCBG`XCBU`XCBU.U`XCD`XCG`XCH`XCLN`XCLR`XCNS`XCS`XCSR`XCV`XDG`XDG.U`XDGH`XDIV`XDLR`XDNA`XDRV`XDSR`XDU`XDU.U`XDUH`XDV`XEB`XEC`XEC.U`XEF`XEF.U`XEG`XEH`XEI`XEM`XEMC`XEN`XEQT`XESG`XEU`XEXP`XFA`XFC`XFF`XFH`XFI`XFLB`XFN`XFR`XFS`XFS.U`XGB`XGD`XGGB`XGI`XGRO`XHAK`XHB`XHC`XHD`XHU`XHY`XIC`XID`XIG`XIGS`XIN`XINC`XIT`XIU`XLB`XLVE`XMA`XMC`XMC.U`XMD`XMH`XMI`XML`XMM`XMS`XMTM`XMU`XMU.U`XMV`XMW`XMY`XPF`XQB`XQLT`XQQ`XRB`XRE`XSAB`XSB`XSC`XSE`XSEA`XSEM`XSH`XSHG`XSHU`XSHU.U`XSI`XSMC`XSMH`XSP`XSQ`XST`XSTB`XSTH`XSTP`XSTP.U`XSU`XSUS`XTLH`XTLT`XTLT.U`XTR`XUH`XULR`XUS`XUS.U`XUSR`XUT`XUU`XUU.U`XVLU`XWD`XXM`XXM.B`YAMZ`YGOG`YTSL`YXM`YXM.B`ZACE`ZAG`ZAUT`ZBAL`ZBAL.T`ZBBB`ZBI`ZBK`ZCB`ZCDB`ZCH`ZCLN`ZCM`ZCN`ZCON`ZCPB`ZCS`ZCS.L`ZDB`ZDH`ZDI`ZDJ`ZDM`ZDV`ZDY`ZDY.U`ZEA`ZEAT`ZEB`ZEF`ZEM`ZEO`ZEQ`ZEQT`ZESG`ZEUS`ZFC`ZFH`ZFIN`ZFL`ZFM`ZFN`ZFS`ZFS.L`ZGB`ZGD`ZGEN`ZGI`ZGQ`ZGRN`ZGRO`ZGRO.T`ZGSB`ZHP`ZHU`ZHY`ZIC`ZIC.U`ZID`ZIN`ZINN`ZINT`ZJG`ZJK`ZJK.U`ZJN`ZJO`ZJPN`ZJPN.F`ZLB`ZLC`ZLD`ZLE`ZLH`ZLI`ZLU`ZLU.U`ZMBS`ZMI`ZMI.U`ZMID`ZMID.F`ZMID.U`ZMMK`ZMP`ZMSB`ZMT`ZMU`ZNQ`ZNQ.U`ZPAY`ZPAY.F`ZPAY.U`ZPH`ZPL`ZPR`ZPR.U`ZPS`ZPS.L`ZPW`ZPW.U`ZQB`ZQQ`ZRE`ZRR`ZSB`ZSDB`ZSML`ZSML.F`ZSML.U`ZSP`ZSP.U`ZST`ZST.L`ZSU`ZTIP`ZTIP.F`ZTIP.U`ZTL`ZTL.F`ZTL.U`ZTM`ZTM.U`ZTS`ZTS.U`ZUAG`ZUAG.F`ZUAG.U`ZUB`ZUD`ZUE`ZUH`ZUP`ZUP.U`ZUQ`ZUQ.F`ZUQ.U`ZUS.U`ZUS.V`ZUT`ZVC`ZVI`ZVU`ZWA`ZWB`ZWB.U`ZWC`ZWE`ZWEN`ZWG`ZWH`ZWH.U`ZWHC`ZWK`ZWP`ZWS`ZWT`ZWU`ZXM`ZXM.B`ZZZD;
input.startTime : 12:00:00.000;
input.endTime :  13:18:00.000;
input.columnsO: `eventTimestamp`instrumentID`listing_mkt`event`b_po`s_po`price`volume; 
input.applyFilter : (in;`listing_mkt;enlist(`TSE`AQL));

order_results: flip `date`instrumentID`listing_mkt`po`bid_depth`b_orders`id_b`ask_depth`s_orders`id_s!(`date$();`symbol$(); `symbol$(); `int$();`float$();`long$();`symbol$();`float$();`long$();`symbol$());

.mapq.summarystats.filterorders:{[OO]
// Order-based filters
    OO: eval (!;0;(?;OO;enlist((in;`event;enlist`Order);(>;`price;0);(>;`volume;0));0b;()));
    : @[;`instrumentID;`p#] `instrumentID xasc OO;
    }; 

mm_orders:{[t] 
    bids: `date`instrumentID`listing_mkt`po xkey distinct 0! delete second from update id_b: ?[0.5<=(count distinct second)%486.5;`A;`P], bid_depth: 5*sum bid_depth, b_orders: 5*sum b_orders by date, instrumentID, listing_mkt, po from 
    select bid_depth: sum price*volume, b_orders: count i by 5 xbar eventTimestamp.second, date: `date$eventTimestamp, instrumentID, listing_mkt, po: b_po from 
    select from orders where 100000<=price*volume, b_po<>0n;
    asks: `date`instrumentID`listing_mkt`po xkey distinct 0! delete second from update id_s: ?[0.5<=(count distinct second)%486.5;`A;`P], ask_depth: 5*sum ask_depth, s_orders: 5*sum s_orders by date, instrumentID, listing_mkt, po from 
    select ask_depth: sum price*volume, s_orders: count i by 5 xbar eventTimestamp.second, date: `date$eventTimestamp, instrumentID, listing_mkt, po: s_po from 
    select from orders where 100000<=price*volume, s_po<>0n;
    :0! delete second from (uj/)(bids;asks);
    };


//Inititate while loop
i:0;
/i<count[calendar]
while[i<50;
    input.startDate: last calendar[i];
    input.endDate: first calendar[i];
    
    //Get Order Data
    getData.edwO: `..getTicks[`symList`assetClass`dataType`startDate`endDate`startTime`endTime`idType`columns`applyFilter!(input.symbols;`equity;`order;input.startDate;input.endDate;input.startTime;input.endTime;`instrumentID;input.columnsO;input.applyFilter)]; /13.6m 
    
    //Filter Order Data
    orders: .mapq.summarystats.filterorders getData.edwO;
    
    {[t] ![t;enlist(>;`i;-1);0b;`$()]} each `getData.edwO; /delete all records for tables in memory
    
    
    //Join Summary Stats and Append Results to empty table
    order_results,: mm_orders orders;
    
    
    {[t] ![t;enlist(>;`i;-1);0b;`$()]} each `orders; /delete all records for tables in memory

    //Iterate again
    i+: 1;
    
    system "sleep 20";
    
    //Sleep 5 munites to bypass timeout
    
    /20.5m  
    /1.38m
    /1.17m
    
    ];
