% prepare les attributs et les champs d'un fichier L2
% commun a SMOS, SMAP et Aquarius
% ajout RR pour L2P

%generic
window0='dail'  % dail, hebd ou mens
sensor='SMOS';
sensor_att='SMOS/MIRAS';
platform_att='PROTEUS';


sensor='SMAP';
sensor_att='SMAP';
platform_att='SMAP';


fileversion='3.2';
Level='L2P';
days19700101=datenum(1970,1,1,0,0,0);
% comment_att='Daily SMOS L2 data corrected from LSC, SST and seasonal latitudinal biases';
tt235959=(23*3600+59*60+59)/24/3600;  % 23h59mn59s en jour
nplan=1;  % nombre de plan temporel (différent de 1 seulement pour les L2 SMOS)

%input_dir='J:\SSS\data\sat\dataSMOS\CCI_repro2020\Totallycorrected_smos_v3.2\';                 %output directory
input_dir='G:\CCI2021\Smap\Totallycorrected_smap_v3.2\';
%input_dir2='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corrRR\';                 %output directory
%output_dir=['J:\SSS\data\sat\dataSMOS\CCI_repro2020\L2_output\L2P_nc_v3.2\' sensor '\'];

output_dir='G:\CCI2021\Smap\L2_output\L2P_nc_v3.2\';

if exist(output_dir)==0; mkdir(output_dir); end;

dirinput=dir(input_dir);
nfile=length(dirinput);
%dirinput2=dir(input_dir2);

load('mask_smos.mat');
load('latlon_ease.mat') %fichier grille
lat_fixgrid=lat_ease;
lon_fixgrid=lon_ease;
nlon=length(lon_ease);
nlat=length(lat_ease);

for ifile=3:nfile
    
    nametot=[input_dir dirinput(ifile).name];
    %  nametot2=[input_dir2 dirinput(ifile).name];
    % load(nametot2,'WS0','SST0','tSSS0');
    % load(nametot,'SSS_corr','totalcorrection','chiSSS0','SSS_random','sss_qc_smos','isc_qc','lsc_qc','Rain_Rate0','WS0','SST0','tSSS0');
    
    fff=dir(nametot);
    
    if fff.bytes > 600000 & strcmp(fff.name(5),'D')   % fichiers .mat vide
        
        load(nametot,'SSS_corr','totalcorrection','chiSSS0','SSS_random','sss_qc_smap','isc_qc','lsc_qc','Rain_Rate0','WS0','SST0','tSSS0');
        
        % calcul du nombre de plan valide (on retire les plans avec des NaN)
        % valable pour tous les capteurs; meme si nbre de plan = 1
        kplan=0;
        iplan=[];
        for ipp=1:size(SSS_corr,3)
            indNaN=find(isnan(SSS_corr(:,:,ipp))==0);
            if length(indNaN)>1
                kplan=kplan+1;
                iplan(kplan)=ipp;  % indices OK
            end
        end
        
        SSS_corr=SSS_corr(:,:,iplan);
        tSSS0=tSSS0(:,:,iplan);
        WS0=WS0(:,:,iplan);
        SST0=SST0(:,:,iplan);
        Rain_Rate0=Rain_Rate0(:,:,iplan);
        SSS_random=SSS_random(:,:,iplan);
        totalcorrection=totalcorrection(:,:,iplan);
        % sss_qc=sss_qc_smos(:,:,iplan);
        sss_qc=sss_qc_smap(:,:,iplan);
        isc_qc=isc_qc(:,:,iplan);
        lsc_qc=lsc_qc(:,:,iplan);
        
        orbite=dirinput(ifile).name(5);
        date1=dirinput(ifile).name(7:14);
        yyyc=dirinput(ifile).name(7:10);
        ttt=datenum(str2num(dirinput(ifile).name(7:10)),str2num(dirinput(ifile).name(11:12)),str2num(dirinput(ifile).name(13:14)));
        
        if exist([output_dir yyyc])==0; mkdir([output_dir yyyc]); end;
        
        nameNC=([output_dir yyyc  '\ESACCI-SEASURFACESALINITY-' Level '-SSS-' sensor '_' orbite '_DAILY_25km-',date1,'-fv',fileversion,'.nc']);%output file
        if exist(nameNC)~=0; delete(nameNC); end;
        nameNC
        nccreate(nameNC,'lat','Dimensions',{'lat' size(lat_fixgrid,1)},'Datatype','single','DeflateLevel',6,'fillValue',NaN);
        ncwrite(nameNC,'lat',lat_fixgrid);
        % ncwriteatt(nameNC,'lat','FillValue',fillval);
        ncwriteatt(nameNC,'lat','long_name','latitude');
        ncwriteatt(nameNC,'lat','units','degrees_north');
        ncwriteatt(nameNC,'lat','standard_name','latitude');
        ncwriteatt(nameNC,'lat','valid_min',-90); % correction 24/03/2020
        ncwriteatt(nameNC,'lat','valid_max',90); % correction 24/03/2020
        
        nccreate(nameNC,'lon','Dimensions',{'lon' size(lon_fixgrid,1)},'Datatype','single','DeflateLevel',6,'fillValue',NaN);
        ncwrite(nameNC,'lon',lon_fixgrid);
        ncwriteatt(nameNC,'lon','long_name','longitude');
        ncwriteatt(nameNC,'lon','units','degrees_east');
        ncwriteatt(nameNC,'lon','standard_name','longitude');
        ncwriteatt(nameNC,'lon','valid_min',-180); % correction 24/03/2020
        ncwriteatt(nameNC,'lon','valid_max',180); % correction 24/03/2020
        
        ncwriteatt(nameNC,'/','creation_time',datestr(now));
        
        if strcmp(window0,'mens')
            Value= 'ESA CCI Sea Surface Salinity ECV produced at a spatial resolution of 50 km and time resolution of 1 month and spatially resampled on 25 km EASE grid and 15 days of time sampling';  % year2 correction
        else
            Value= 'ESA CCI Sea Surface Salinity ECV produced at a spatial resolution of 50 km and time resolution of one week and spatially resampled on 25 km EASE grid and 1 day of time sampling';  % year2 correction
        end
        ncwriteatt(nameNC,'/','title',Value);
        
        Value=['This CCI+SSS product has not been fully validated yet ', ...
            'and may contain flaws. In case you discover some, we ',...
            '(Mngt_CCI-Salinity@argans.co.uk) are very keen to get your feedback. ',...
            'In case you would like to use them in a presentation or publication, ',...
            'please contact us to get their correct reference (doi attribution in progress)'];
        ncwriteatt(nameNC,'/','comment',Value);
        
        Value= 'ACRI-ST,LOCEAN'; % year3
        ncwriteatt(nameNC,'/','institution',Value);
        
        % fichier entree (origine des L2OS)
        Value= ['SMOS CCI v3 L2OS reprocessing (ERA5,ref OTT SSS:ISAS, RFI filtering) from DPGS L1 v620, L2OS v662 modified as in DOI:10.1109/tgrs.2020.3030488, SMAP L2 RSS v4.0 - DOI:10.5067/SMP40-2SOCS, Aquarius L3 v5.0 - DOI:10.5067/AQR50-3SQCS'];   % year3 DOI SMAP complete
        
        ncwriteatt(nameNC,'/','source',Value);
        
        Value= ' ';  % year2 correction
        ncwriteatt(nameNC,'/','history',Value);
        
        Value= 'http://cci.esa.int/salinity';    % year2
        ncwriteatt(nameNC,'/','references',Value);
        
        ncwriteatt(nameNC,'/','product_version',fileversion);
        
        Value = 'CCI Data Standards v2.2' ;  % year3
        ncwriteatt(nameNC,'/','format_version',Value);
        
        Value =  'CF-1.8';   % year3 passage de la 1.7 a la 1.8
        ncwriteatt(nameNC,'/','Conventions',Value);
        
        Value =  'ESA CCI Sea Surface Salinity';  % year2
        ncwriteatt(nameNC,'/','summary',Value);   % correction year2 Summary -> summary
        
        Value =  'Ocean, Ocean Salinity, Sea Surface Salinity, Satellite';  % year2
        ncwriteatt(nameNC,'/','keywords',Value);
        
        Value =  'sss,sss_random_error';  % year3
        ncwriteatt(nameNC,'/','key_variables',Value);
        
        Value =  'European Space Agency - ESA Climate Office';  % year2
        ncwriteatt(nameNC,'/','naming_authority',Value);
        
        Value =  'NASA Global Change Master Directory (GCMD) Science Keywords'; % year2
        ncwriteatt(nameNC,'/','keywords_vocabulary',Value);
        
        Value =  'Grid';  % year2
        ncwriteatt(nameNC,'/','cdm_data_type',Value);
        
        Value= 'ACRI-ST,LOCEAN';  % year3
        ncwriteatt(nameNC,'/','creator_name',Value);
        
        Value= 'jean-luc.vergely@acri-st.fr';  % year2
        ncwriteatt(nameNC,'/','creator_email',Value);
        
        Value= 'http://cci.esa.int/salinity';  % year2
        ncwriteatt(nameNC,'/','creator_url',Value);
        
        Value= 'Climate Change Initiative - European Space Agency';  % year2
        ncwriteatt(nameNC,'/','project',Value);
        
        Value= lat_ease(1);  % year2 type ?
        ncwriteatt(nameNC,'/','geospatial_lat_min',Value);
        
        Value= lat_ease(end);  % year2 type ?
        ncwriteatt(nameNC,'/','geospatial_lat_max',Value);
        
        Value= lon_ease(1);  % year2 type ?
        ncwriteatt(nameNC,'/','geospatial_lon_min',Value);
        
        Value= lon_ease(end); % year2 type ?
        ncwriteatt(nameNC,'/','geospatial_lon_max',Value);
        
        Value= 'ESA CCI Data Policy: free and open access';  % year2
        ncwriteatt(nameNC,'/','license',Value);
        
        Value= 'NetCDF Climate and Forecast (CF) Metadata Convention version 1.8';  % year3 passage de la 1.7 a la 1.8
        ncwriteatt(nameNC,'/','standard_name_vocabulary',Value);
        
        ncwriteatt(nameNC,'/','platform',platform_att);
        
        ncwriteatt(nameNC,'/','sensor',sensor_att);
        
        Value= '50km';  % year2
        ncwriteatt(nameNC,'/','spatial_resolution',Value);
        
        Value= 'degrees_north';  % year2
        ncwriteatt(nameNC,'/','geospatial_lat_units',Value);
        
        Value= 'degrees_east';  % year2
        ncwriteatt(nameNC,'/','geospatial_lon_units',Value);
        
        Value=0;   % year2 ajout
        ncwriteatt(nameNC,'/','geospatial_vertical_min',Value);
        
        Value=0;   % year2 ajout
        ncwriteatt(nameNC,'/','geospatial_vertical_max',Value);
        
        Value= [datestr(now,30) 'Z'];  % year2
        ncwriteatt(nameNC,'/','date_created',Value);
        
        Value= ''; % year2
        ncwriteatt(nameNC,'/','date_modified',Value);
        
        if strcmp(window0,'hebd')  % year2
            % demande de correction Fred R. year2
            ttt_init=ttt-4;  % correction year2
            ttt_end=ttt+3+tt235959 ;   % correction year2
        elseif strcmp(window0,'mens')
            ttt_init=ttt-14;    % correction year2
            ttt_end=ttt+15+tt235959;  % correction year2
        elseif strcmp(window0,'dail')
            ttt_init=tsnanmin(tsnanmin(tsnanmin(tSSS0)));   % correction year2
            ttt_end=tsnanmax(tsnanmax(tsnanmax(tSSS0)));  % correction year2
        end
        
        Value= [datestr(ttt_init,30) 'Z'];  % year2
        ncwriteatt(nameNC,'/','time_coverage_start',Value);
        
        Value= [datestr(ttt_end,30) 'Z'];   % year2
        ncwriteatt(nameNC,'/','time_coverage_end',Value);  % correction time_coverage_stop -> time_coverage_end
        
        if strcmp(window0,'hebd')   % year2
            Value= 'P7D';
        elseif strcmp(window0,'mens')
            Value= 'P1M';
        elseif strcmp(window0,'dail')
            Value= 'P1D';
        end
        
        ncwriteatt(nameNC,'/','time_coverage_duration',Value);
        
        if strcmp(window0,'hebd')   % year3
            Value= 'P1D';  % year3 correction
        elseif strcmp(window0,'mens')
            Value= 'P15D';  % year3 correction
        elseif strcmp(window0,'dail')
            Value= 'P1D';
        end
        ncwriteatt(nameNC,'/','time_coverage_resolution',Value);
        
        [path,fname,extension]=fileparts(nameNC);
        Value= [fname extension];  % year2
        ncwriteatt(nameNC,'/','id',Value);
        
        UUID = java.util.UUID.randomUUID;
        Value= char(UUID);  % year2
        ncwriteatt(nameNC,'/','tracking_id',Value);    % uid : librairie  getuid
        
        Value = '25km EASE 2 cylindrical grid';   % ajout year2 correction year 3
        ncwriteatt(nameNC,'/','spatial_grid',Value);
        
        
        if strcmp(window0,'mens') | strcmp(window0,'hebd')  % temps moyen pour produit mens et hebd
            ttt0=ttt-days19700101;
            nccreate(nameNC,'time','Dimensions',{'time' Inf},'Datatype','single','DeflateLevel',6,'fillValue',NaN);
            ncwrite(nameNC,'time',single(ttt0));
            ncwriteatt(nameNC,'time','long_name','time');
            ncwriteatt(nameNC,'time','units','days since 1970-01-01 00:00:00 UTC');
            ncwriteatt(nameNC,'time','standard_name','time');
            ncwriteatt(nameNC,'time','calendar','standard');   % correction 24/03/2020
            
            nccreate(nameNC,'noutliers','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','int16','DeflateLevel',6,'Shuffle',true);
            ncwriteatt(nameNC,'noutliers','long_name','Count of the Number of Outliers within this bin cell');
            ncwriteatt(nameNC,'noutliers','valid_min',int16(0));
            ncwriteatt(nameNC,'noutliers','valid_max',int16(10000));
            ncwriteatt(nameNC,'noutliers','scale_factor',1); % correction 24/03/2020
            
            nccreate(nameNC,'total_nobs','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','int16','DeflateLevel',6,'Shuffle',true);
            ncwriteatt(nameNC,'total_nobs','long_name','Number of SSS in the time interval');
            ncwriteatt(nameNC,'total_nobs','valid_min',int16(0));
            ncwriteatt(nameNC,'total_nobs','valid_max',int16(10000));
            ncwriteatt(nameNC,'total_nobs','scale_factor',1);  % correction 24/03/2020
            
        elseif strcmp(window0,'dail')   % temps pour chaque acquisition si produit journalier
            nccreate(nameNC,'Mean_Acq_Time','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'Mean_Acq_Time','long_name','Mean Acquisition Time');
            ncwriteatt(nameNC,'Mean_Acq_Time','units','days since 1970-01-01 00:00:00 UTC');   % correction 24/03/2020
            ncwriteatt(nameNC,'Mean_Acq_Time','standard_name','time');
            ncwrite(nameNC,'Mean_Acq_Time',single(tSSS0-days19700101));
        end
        
        nccreate(nameNC,'sss','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
        %  ncwrite(nameNC,'sss',single(rand(size(lon_fixgrid,1),size(lat_fixgrid,1))));
        ncwriteatt(nameNC,'sss','long_name','Unbiased merged Sea Surface Salinity');
        % ncwriteatt(nameNC,'sss','units','pss');   % correction 24/03/2020
        ncwriteatt(nameNC,'sss','standard_name','sea_surface_salinity');
        ncwriteatt(nameNC,'sss','valid_min',0);
        ncwriteatt(nameNC,'sss','valid_max',50);
        ncwrite(nameNC,'sss',single(SSS_corr));
        ncwriteatt(nameNC,'sss','ancilliary','noutliers total_nobs sss_qc');  % variables en  liens avec la sss
        
        nccreate(nameNC,'sss_random_error','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
        ncwriteatt(nameNC,'sss_random_error','long_name','Sea Surface Salinity Random Error');
        ncwriteatt(nameNC,'sss_random_error','valid_min',0);
        ncwriteatt(nameNC,'sss_random_error','valid_max',100);
        ncwrite(nameNC,'sss_random_error',single(SSS_random));
        ncwriteatt(nameNC,'sss_random_error','ancilliary','pct_var');
        %  ncwriteatt(nameNC,'sss_random_error','scale_factor',1); % correction 24/03/2020
        
        
        % uniquement pour les produits L2
        if strcmp(Level,'L2P')
            % biais sss
            nccreate(nameNC,'sss_bias','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'sss_bias','long_name','Bias in Sea Surface Salinity');
            ncwriteatt(nameNC,'sss_bias','valid_min',-100);
            ncwriteatt(nameNC,'sss_bias','valid_max',100);
            ncwrite(nameNC,'sss_bias',single(-totalcorrection));
            
            % WS
            nccreate(nameNC,'ws','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'ws','long_name',['10m neutral wind module UN10 & VN10']);
            ncwriteatt(nameNC,'ws','units','m.s-1');
            ncwriteatt(nameNC,'ws','standard_name','wind_speed');
            ncwrite(nameNC,'ws',single(WS0));
            
            % SST
            nccreate(nameNC,'sst','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'sst','long_name','Sea Surface Temperature');
            ncwriteatt(nameNC,'sst','units','C');
            ncwriteatt(nameNC,'sst','standard_name','sea_surface_temperature');
            ncwriteatt(nameNC,'sst','valid_min',-100);
            ncwriteatt(nameNC,'sst','valid_max',100);
            ncwrite(nameNC,'sst',single(SST0));
            
            % Precipitation
            nccreate(nameNC,'rain_rate','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'rain_rate','long_name','Instantaneous Rain Rate');
            ncwriteatt(nameNC,'rain_rate','units','mm/hr');
            ncwriteatt(nameNC,'rain_rate','standard_name','rainfall_rate');
            ncwriteatt(nameNC,'rain_rate','valid_min',0);
            ncwriteatt(nameNC,'rain_rate','valid_max',100);
            ncwrite(nameNC,'rain_rate',single(Rain_Rate0*1000));
            
        end
        
        % uniquement pour produits L4
        if strcmp(Level,'L4')
            nccreate(nameNC,'pct_var','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' 1},'Datatype','single','DeflateLevel',6,'Shuffle',true,'fillValue',NaN);
            ncwriteatt(nameNC,'pct_var','long_name','Percentage of SSS_variability that is expected to be not explained by the products');
            ncwriteatt(nameNC,'pct_var','units','%');
            ncwriteatt(nameNC,'pct_var','valid_min',0);
            ncwriteatt(nameNC,'pct_var','valid_max',100);
        end
        
        % ncwriteatt(nameNC,'pct_var','scale_factor',1);  % correction 24/03/2020
        
        nccreate(nameNC,'sss_qc','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','int8','DeflateLevel',6,'Shuffle',true);
        ncwriteatt(nameNC,'sss_qc','long_name','Sea Surface Salinity Quality, 0=Good; 1=Bad');
        ncwriteatt(nameNC,'sss_qc','valid_min',int8(0));
        ncwriteatt(nameNC,'sss_qc','valid_max',int8(1));
        ncwrite(nameNC,'sss_qc',int8(sss_qc));
        
        nccreate(nameNC,'lsc_qc','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','int8','DeflateLevel',6,'Shuffle',true);
        ncwriteatt(nameNC,'lsc_qc','long_name','Land Sea Contamination Quality Check, 0=Good; 1=Bad');
        ncwriteatt(nameNC,'lsc_qc','valid_min',int8(0));
        ncwriteatt(nameNC,'lsc_qc','valid_max',int8(1));
        ncwrite(nameNC,'lsc_qc',int8(lsc_qc));
        
        nccreate(nameNC,'isc_qc','Dimensions',{'lon' size(lon_fixgrid,1) 'lat' size(lat_fixgrid,1) 'time' kplan},'Datatype','int8','DeflateLevel',6,'Shuffle',true);
        ncwriteatt(nameNC,'isc_qc','long_name','Ice Sea Contamination Quality Check, 0=Good; 1=Bad');
        ncwriteatt(nameNC,'isc_qc','valid_min',int8(0));
        ncwriteatt(nameNC,'isc_qc','valid_max',int8(1));
        ncwrite(nameNC,'isc_qc',int8(isc_qc));
        
    end
    
    %  keyboard
    
end

% verif
ipl=1;
sss=ncread(nameNC,'sss');
sss_bias=ncread(nameNC,'sss_bias');
sss_random_error=ncread(nameNC,'sss_random_error');
Mean_Acq_Time=ncread(nameNC,'Mean_Acq_Time');
ws=ncread(nameNC,'ws');
sst=ncread(nameNC,'sst');

sss_qc=ncread(nameNC,'sss_qc');
lsc_qc=ncread(nameNC,'lsc_qc');
isc_qc=ncread(nameNC,'isc_qc');

figure;
subplot(3,3,1); hold on; title('sss'); imagesc(squeeze(sss(:,:,ipl))'); axis tight; caxis([28 38]); colorbar; hold off
subplot(3,3,2); hold on; title('sss_bias','Interpreter','none'); imagesc(squeeze(sss_bias(:,:,ipl))'); axis tight; caxis([-2 2]); colorbar; hold off
subplot(3,3,3); hold on; title('sss_random_error','Interpreter','none'); imagesc(squeeze(sss_random_error(:,:,ipl))'); axis tight; caxis([0 2]); colorbar; hold off
subplot(3,3,4); hold on; title('Mean_Acq_Time','Interpreter','none'); imagesc(squeeze(Mean_Acq_Time(:,:,ipl))'); axis tight;  colorbar; hold off
subplot(3,3,5); hold on; title('ws'); imagesc(squeeze(ws(:,:,ipl))'); axis tight; caxis([0 15]); colorbar; hold off
subplot(3,3,6); hold on; title('sst'); imagesc(squeeze(sst(:,:,ipl))'); axis tight; caxis([0 35]); colorbar; hold off
subplot(3,3,7); hold on; title('sss_qc','Interpreter','none'); imagesc(squeeze(sss_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off
subplot(3,3,8); hold on; title('lsc_qc','Interpreter','none'); imagesc(squeeze(lsc_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off
subplot(3,3,9); hold on; title('isc_qc','Interpreter','none'); imagesc(squeeze(isc_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off



% ajouter ecriture de tSSS0 dans Mean_Acq_Time
% sss_bias=-totalcorrection


