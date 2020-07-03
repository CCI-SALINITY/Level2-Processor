%write netcdf L2 SMAP file

clear all;
close all;

fileversion='2.3';
fillvalu=-9999;

load('../../auxilary/latlon_ease.mat') %fichier grille
load('../../auxilary/lsc_flag_ease.mat') %fichier flag lsc
nlon=length(lon_ease);
nlat=length(lat_ease);
for ii=1:2
	lscflag(ii,:,:)=lsc_flag;
end

% chemin des produits corriges latitudinalement et de la SST
input_dir='../../../L2_output/Level2_intermediate/Totallycorrected_smap/';%input directory
dirL2P=dir(input_dir);
output_dir='../../../L2_output/L2P_nc/SMAP/';%output directory

days19700101=datenum(1970,1,1,0,0,0);

for kk=3:length(dirL2P)
	
	SSS_corr=[];
	totalcorrection=[];
	SST0=[];
	WS0=[];
	SSS_random=[];
	tSSS0=[];
	sss_qc_smap=[];

	%lecture des donnees
	
	input_file=([input_dir,dirL2P(kk).name]);
	load(input_file);
	orbite=dirL2P(kk).name(end-4);
	date=dirL2P(kk).name(17:24);

	%%%%definition of time

	YYYYtime=str2num(date(1:4));
	MMtime=str2num(date(5:6));
	JJtime=str2num(date(7:8));
	date_time=datenum(YYYYtime,MMtime,JJtime,0,0,0);

	JJ=[];
	JJ=find(totalcorrection>20);
	SSS_corr(JJ)=nan;
	SSS_random(JJ)=nan;
	totalcorrection(JJ)=nan;

	JJ=[];
	JJ=find(isnan(SSS_corr));
	tSSS0(JJ)=nan;
	II=[];
	II=find(tSSS0>0);
	if (length(II)>0)
		date_start_ind=min(min(tSSS0(II)));
		date_end_ind=max(max(tSSS0(II)));

		date_start=datestr(date_start_ind,30);
		date_end=datestr(date_end_ind,30);

		time_duration_ind=date_end_ind-date_start_ind;
		time_duration=datestr(time_duration_ind,30);

		%ice flag
		sss_flag=fillvalu*ones(2,nlon,nlat);
		isc_flag=fillvalu*ones(2,nlon,nlat);
		lsc_flag=fillvalu*ones(2,nlon,nlat);
		%KK=[];
		%KK=find(SSS_corr>0);
		isc_flag(II)=0;
		lsc_flag(II)=lscflag(II);
		sss_flag(II)=sss_qc_smap(II);

		%ecriture des donnees

		L2C_ncfile=([output_dir,'ESACCI-SEASURFACESALINITY-L2P-SSS-SMAP_',orbite,'_DAILY_25km-',date,'-fv',fileversion,'.nc']);%output file
		nc=netcdf.create(L2C_ncfile,'netcdf4');

		%%%%%%%%%%%%%%%%%%%%%%%

		%dimensions

		dimidW = netcdf.defDim(nc,'time',1);
		dimidX = netcdf.defDim(nc,'view',2);
		dimidY = netcdf.defDim(nc,'lat',length(lat_ease));
		dimidZ = netcdf.defDim(nc,'lon',length(lon_ease));

		%%time  mettre a jour

		%%global attributes

		NC_GLOBAL = netcdf.getConstant('NC_GLOBAL');

		netcdf.putAtt(nc,NC_GLOBAL,'creation_time',datestr(now));
		
		Value= 'ACRI-ST; LOCEAN' ;
		netcdf.putAtt(nc,NC_GLOBAL,'institution',Value);
		
		Value =  'CF-1.7';
		netcdf.putAtt(nc,NC_GLOBAL,'Conventions',Value);
		
		Value =  'Ocean, Ocean Salinity, Sea Surface Salinity, Satellite';
		netcdf.putAtt(nc,NC_GLOBAL,'keywords',Value);

		Value =  'European Space Agency - ESA Climate Office';
		netcdf.putAtt(nc,NC_GLOBAL,'naming_authority',Value);

		Value =  'NASA Global Change Master Directory (GCMD) SCience Keywords';
		netcdf.putAtt(nc,NC_GLOBAL,'keywords_vocabulary',Value);
		
		Value =  'Grid';
		netcdf.putAtt(nc,NC_GLOBAL,'cdm_data_type',Value);
		
		Value= 'ACRI-ST; LOCEAN';
		netcdf.putAtt(nc,NC_GLOBAL,'creator_name',Value);
		
		Value= 'http://cci.esa.int/salinity';
		netcdf.putAtt(nc,NC_GLOBAL,'creator_url',Value);
		
		Value= 'Climate Change Initiative - European Space Agency';
		netcdf.putAtt(nc,NC_GLOBAL,'project',Value);
		
		Value= 'ESA CCI Data Policy: free and open access';%tocheck
		netcdf.putAtt(nc,NC_GLOBAL,'license',Value);
		
		Value= 'NetCDF Climate and Forecast (CF) Metadata Convention version 1.7';
		netcdf.putAtt(nc,NC_GLOBAL,'standard_name_vocabulary',Value);

		Value= 'SMAP'; 
		netcdf.putAtt(nc,NC_GLOBAL,'platform',Value);

		Value= 'SMAP';
		netcdf.putAtt(nc,NC_GLOBAL,'sensor',Value);
		
		Value= '50km';
		netcdf.putAtt(nc,NC_GLOBAL,'spatial_resolution',Value);
		
		Value= 'degrees_north';
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_units',Value);
		
		Value= 'degrees_east';
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_units',Value);
		
		Value= ' ';
		netcdf.putAtt(nc,NC_GLOBAL,'date_modified',Value);
		
		UUID = java.util.UUID.randomUUID;
		Value= char(UUID);
		netcdf.putAtt(nc,NC_GLOBAL,'tracking_id',Value); 

		Value= 'meriem.chakroun@acri-st.fr';%tocheck
		netcdf.putAtt(nc,NC_GLOBAL,'creator_email',Value);

		Value =  time_duration; %(?)
		netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_duration',Value);
		
		Value= -90.0;
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_min',Value);
		
		Value= 90.0;
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_max',Value);
		
		Value= -180.0;
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_min',Value);
		
		Value= 180.0;
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_max',Value);

		Value= datestr(now,30);
		netcdf.putAtt(nc,NC_GLOBAL,'date_created',Value);

		Value= date_start;
		netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_start',Value);

		Value= 'ESA CCI Sea Surface Salinity ECV Product - Daily forward and backward SMAP L2 data';
		netcdf.putAtt(nc,NC_GLOBAL,'title',Value)

		Value= ['SMAP L2Cv4/RSS'];%tocheck        
		netcdf.putAtt(nc,NC_GLOBAL,'source',Value);
		
		Value= 'http://cci.esa.int/salinity';
		netcdf.putAtt(nc,NC_GLOBAL,'references',Value);

		
		Value= 'It is a version issued for evaluation purposes by voluntary scientists and for framing CCI+SSS products. In case you discover some flaws not listed below, we (Mngt_CCI-Salinity@argans.co.uk) are very keen to get your feedback'; %tocheck
		netcdf.putAtt(nc,NC_GLOBAL,'comment',Value);   
		 
		[path,fname,extension]=fileparts(L2C_ncfile);       
		Value= [fname extension];
		netcdf.putAtt(nc,NC_GLOBAL,'id',Value);
	       
		Value= 'P1D';
		netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_resolution',Value);

		Value =  fileversion;
		netcdf.putAtt(nc,NC_GLOBAL,'product_version',Value);
		          
		Value= single(0.25);
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_resolution',Value);
		
		Value= single(0.25);
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_resolution',Value);
	       
		Value= '25km EASE 2 grid';
		netcdf.putAtt(nc,NC_GLOBAL,'spatial_grid',Value);

		Value= single(0);
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_vertical_min',Value);
		
		Value= single(0);
		netcdf.putAtt(nc,NC_GLOBAL,'geospatial_vertical_max',Value);
		
		Value =  'ESA CCI Sea Surface Salinity';
		netcdf.putAtt(nc,NC_GLOBAL,'summary',Value);
		
		Value =  date_end ;
		netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_end',Value);
		
		Value =  ' ';
		netcdf.putAtt(nc,NC_GLOBAL,'history',Value);
		    
		%%%%%%variables%%%%%%%

		varid=netcdf.defVar(nc,'time','float',[dimidW]);
		netcdf.putAtt(nc,varid,'long_name','time');
		netcdf.putAtt(nc,varid,'units','days since 1970-01-01 00:00:00 UTC');
		netcdf.putAtt(nc,varid,'standard_name','time');
		netcdf.putAtt(nc,varid,'calendar','standard');
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,date_time-days19700101);

		varid=netcdf.defVar(nc,'view','short',[dimidX]);
		netcdf.putAtt(nc,varid,'long_name','forward measure: view = 1; backward measure: view =2');
		netcdf.putAtt(nc,varid,'valid_min',int16(1));
		netcdf.putAtt(nc,varid,'valid_max',int16(2));
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,int16([1,2]));

		varid=netcdf.defVar(nc,'lat','float',[dimidY]);
		netcdf.putAtt(nc,varid,'long_name','latitude');
		netcdf.putAtt(nc,varid,'units','degrees_north');
		netcdf.putAtt(nc,varid,'standard_name','latitude');
		netcdf.putAtt(nc,varid,'valid_min',single(-90));
		netcdf.putAtt(nc,varid,'valid_max',single(90));
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,lat_ease);

		varid=netcdf.defVar(nc,'lon','float',[dimidZ]);
		netcdf.putAtt(nc,varid,'long_name','longitude');
		netcdf.putAtt(nc,varid,'units','degrees_east');
		netcdf.putAtt(nc,varid,'standard_name','longitude');
		netcdf.putAtt(nc,varid,'valid_min', single(-180));
		netcdf.putAtt(nc,varid,'valid_max', single(180));
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,lon_ease);

		varid=netcdf.defVar(nc,'Mean_Acq_Time','float',[dimidZ dimidY dimidX dimidW]);
		netcdf.putAtt(nc,varid,'long_name','Mean Acquisition Time');
		netcdf.putAtt(nc,varid,'units','days since 1970-01-01 00:00:00 UTC');
		netcdf.putAtt(nc,varid,'standard_name','time');
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,permute(tSSS0,[2,3,1])-days19700101);

		varid=netcdf.defVar(nc,'sss','float',[dimidZ dimidY dimidX dimidW]);
		netcdf.putAtt(nc,varid,'long_name','Unbiased Sea Surface Salinity');
		%netcdf.putAtt(nc,varid,'units','');
		netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity');
		netcdf.putAtt(nc,varid,'valid_min',single(0));
		netcdf.putAtt(nc,varid,'valid_max',single(50));
		%netcdf.putAtt(nc,varid,'scale_factor',1);
		%netcdf.putAtt(nc,varid,'add_offset',0);
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,permute(SSS_corr,[2,3,1]));
	   
		varid=netcdf.defVar(nc,'sss_random_error','float',[dimidZ dimidY dimidX dimidW]);     
		netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Random Error');
		%netcdf.putAtt(nc,varid,'units','');
		%netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_random_error');
		netcdf.putAtt(nc,varid,'valid_min',single(0));
		netcdf.putAtt(nc,varid,'valid_max',single(100));
		%netcdf.putAtt(nc,varid,'scale_factor',1);
		%netcdf.putAtt(nc,varid,'add_offset',0);
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,permute(SSS_random,[2,3,1]));
	 
		varid=netcdf.defVar(nc,'sss_bias','float',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','Bias in Sea Surface Salinity');
		%netcdf.putAtt(nc,varid,'units','pss');
		%netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_bias');
		netcdf.putAtt(nc,varid,'valid_min',single(-100));
		netcdf.putAtt(nc,varid,'valid_max',single(100));
		%netcdf.putAtt(nc,varid,'scale_factor',1);
		%netcdf.putAtt(nc,varid,'add_offset',0);
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,-permute(totalcorrection,[2,3,1]));

		varid=netcdf.defVar(nc,'sss_qc','short',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Quality Check, 0=Good; 1=Bad');
		%netcdf.putAtt(nc,varid,'units','');
		%netcdf.putAtt(nc,varid,'standard_name','SSS global quality flag');
		netcdf.putAtt(nc,varid,'valid_min',int16(0));
		netcdf.putAtt(nc,varid,'valid_max',int16(1));
		netcdf.defVarFill(nc,varid,false,fillvalu);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,int16(permute(sss_flag,[2,3,1])));  %a mettre a jour

		varid=netcdf.defVar(nc,'lsc_qc','short',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','Land Sea Contamination Quality Check, 0=Good; 1=Bad');
		%netcdf.putAtt(nc,varid,'units','');
		%netcdf.putAtt(nc,varid,'standard_name','Land sea contamination flag');
		netcdf.putAtt(nc,varid,'valid_min',int16(0));
		netcdf.putAtt(nc,varid,'valid_max',int16(1));
		netcdf.defVarFill(nc,varid,false,fillvalu);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,int16(permute(lsc_flag,[2,3,1])));  %a mettre a jour

		varid=netcdf.defVar(nc,'isc_qc','short',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','Ice Sea Contamination Quality Check, 0=Good; 1=Bad');
		%netcdf.putAtt(nc,varid,'units','');
		%netcdf.putAtt(nc,varid,'standard_name','Ice sea contamination flag');
		netcdf.putAtt(nc,varid,'valid_min',int16(0));
		netcdf.putAtt(nc,varid,'valid_max',int16(1));
		netcdf.defVarFill(nc,varid,false,fillvalu);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,int16(permute(isc_flag,[2,3,1])));  %a mettre a jour
		
		varid=netcdf.defVar(nc,'sst','float',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','Sea Surface Temperature');
		netcdf.putAtt(nc,varid,'units','K');
		netcdf.putAtt(nc,varid,'standard_name','sea_surface_temperature');
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,permute(SST0,[2,3,1]));  %a mettre a jour

		varid=netcdf.defVar(nc,'ws','float',[dimidZ dimidY dimidX dimidW]);  
		netcdf.putAtt(nc,varid,'long_name','10m neutral wind module UN10 & VN10');
		netcdf.putAtt(nc,varid,'units','m.s-1');
		netcdf.putAtt(nc,varid,'standard_name','wind_speed');
		netcdf.defVarFill(nc,varid,false,NaN);
		netcdf.defVarDeflate(nc,varid,false,true,6);
		netcdf.putVar(nc,varid,permute(WS0,[2,3,1]));  %a mettre a jour

		netcdf.close(nc);
		disp(L2C_ncfile)
	else
		II=[];
		II=find(SSS_corr>=0);
		if (length(II)>0)
			disp('SSS_corr>0 existe mais toutes tSSS0=nan')
		end
	end
end
