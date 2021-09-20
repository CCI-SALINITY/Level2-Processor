% lecture des produits SMOS CATDS version 662 (repro 2020), fichiers netcdf
% preparation des fichiers fichier journalier
% separation asc/desc
% grille carree et polaires


clear

set(groot,'DefaultFigureColormap',jet)

% XSWATH
xswathmax=662.5;
pasxswath=25;
xswath=-xswathmax:pasxswath:xswathmax;

orb='D';   % A pour asc, D pour desc
if orb=='A'; orbc='Asc'; else; orbc='Des'; end;

grids=3;  % 1 pour carre, 2 pour North, 3 pour South

if grids==1
    grillesel='PlateCarree';
    lat=ncread([grillesel '.nc'],'lat');
    lon=ncread([grillesel '.nc'],'lon');
elseif grids==2   % grille 392x392
    grillesel='Polar_North';
    lat=ncread([grillesel '.nc'],'latitude');
    lon=ncread([grillesel '.nc'],'longitude');
else
    grillesel='Polar_South';
    lat=ncread([grillesel '.nc'],'latitude');
    lon=ncread([grillesel '.nc'],'longitude');
end

filename=['ESACCI-SEASURFACESALINITY-L2-SSS-SMOS_Daily_' orbc '_' grillesel '_25km-20170505-fv3.0.nc'];

nlat=length(lat);
nlon=length(lon);

pathsave=['J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full\'];
if exist(pathsave)==0; mkdir(pathsave); end

pathREPRO=['J:\SSS\data\sat\dataSMOS\CCI_repro2020\version_nsig3\'];

dateref=datenum(2000,1,1);  % reference SMOS 1/1/2000

for year0=2010:2020;
    
    dateyear0=datenum(year0,1,1,0,0,0);
    
    start_time_day_of_year=zeros(366,1);
    nameprod=struct([]);
    fileday=struct([]);
    yearc=num2str(year0);
    pathREPROyear=[pathREPRO yearc '\'];
    
    dirp=dir(pathREPROyear);
    nmonth=length(dirp);
    
    k=0;
    for imonth=1:nmonth
        
        monthn=str2num(dirp(imonth).name);
        monthc=num2str(monthn);
        
        sprintf('year=%d,month=%d\n',year0,monthn)
        
        if monthn<10; monthc=['0' monthc]; end;
        pathREPROyearmonth=[pathREPROyear monthc '\'];
        
        dirmonth=dir([pathREPROyearmonth]);
        nday=length(dirmonth)-2
        
        % map1=NaN(length(dirname),nlon,nlat);
        % map2=NaN(length(dirname),nlon,nlat);
        % 'Dg_Suspect_ice0','WS0','SST0','SSS0','eSSS0','idwSSS0','chiSSS0','tSSS0','xswath','dualfull','Acard','Acard_mod','Dg_chi2_Acard','flag_many_outlier','flag_maxiter'
        
        for iday=1:nday %length(dirname)
            
            % iday
            dayc=num2str(iday);
            if length(dayc)==1; dayc=['0' dayc]; end;
            pathREPROyearmonthday=[pathREPROyearmonth dayc '\'];
            dirday=dir([pathREPROyearmonthday]);
            filenamesave=[pathsave 'smos' orb '_' yearc monthc dayc];
            filename(66:73)=[yearc monthc dayc];
            tJul0=datenum(2000,1,1,0,0,0);
                
            filnamepath=[pathREPROyearmonthday filename];

            if exist([filenamesave '.mat'])==0 & exist(filnamepath)~=0
                filenamesave
                
                infout=ncinfo(filnamepath);
                
                WS=ncread(filnamepath,'WS');
                Acard=ncread(filnamepath,'Param_postR2_param1');  % Acard estimation retrieval 2
                SSS=ncread(filnamepath,'Param_postR1_param1');  % SSS estimation retrieval 1
                tSSS=ncread(filnamepath,'Mean_Acq_Time')+tJul0;
                eSSS=ncread(filnamepath,'Param_postR1_param1_sigma');
                xswathSSS=ncread(filnamepath,'X_Swath');
                Dg_chi2_1=ncread(filnamepath,'Param_postR1_Dg_chi2');  % pas de division par 100 dans la version netcdf
                Dg_chi2_Acard=ncread(filnamepath,'Param_postR2_Dg_chi2');
                Rain_Rate=ncread(filnamepath,'Rain_Rate');
                Ctrl_flags_1=ncread(filnamepath,'Param_R1_Control_Flags');
                SST=ncread(filnamepath,'SST')-273.15;   % en deg C (pas besoin de faire le conversion)
                
                nti=size(SSS,3);
                
                WS=reshape(WS,nlon*nlat,nti);
                Acard=reshape(Acard,nlon*nlat,nti);
                SSS=reshape(SSS,nlon*nlat,nti);
                tSSS=reshape(tSSS,nlon*nlat,nti);
                eSSS=reshape(eSSS,nlon*nlat,nti);
                xswathSSS=reshape(xswathSSS,nlon*nlat,nti);
                Dg_chi2_1=reshape(Dg_chi2_1,nlon*nlat,nti)./100;
                Dg_chi2_Acard=reshape(Dg_chi2_Acard,nlon*nlat,nti)./100;
                Rain_Rate=reshape(Rain_Rate,nlon*nlat,nti);
                Ctrl_flags_1=reshape(Ctrl_flags_1,nlon*nlat,nti);
                SST=reshape(SST,nlon*nlat,nti);
                
                
                indnan=find(SSS<0 | SSS>50 | Dg_chi2_1<=0 | isnan(SSS) | eSSS>5 | SST<-3 | Rain_Rate<0 | Dg_chi2_1>10);
                WS(indnan)=0;
                Acard(indnan)=0;
                SSS(indnan)=0;
                tSSS(indnan)=0;
                eSSS(indnan)=0;
                xswathSSS(indnan)=0;
                Dg_chi2_1(indnan)=0;
                Dg_chi2_Acard(indnan)=0;
                Rain_Rate(indnan)=0;
                Ctrl_flags_1(indnan)=0;
                SST(indnan)=0;
                
                chiSSS=sqrt(Dg_chi2_1);
                chiAcard=sqrt(Dg_chi2_Acard);
                
                % on concentre les plans temporels
                SSS1=SSS./SSS;
                SSS1(indnan)=0;
                % on somme les plans
                sumSSS=sum(SSS1,2);
                nplan=max(sumSSS);
                
                WS0=nan(nlon*nlat,nplan);
                Acard0=nan(nlon*nlat,nplan);
                SSS0=nan(nlon*nlat,nplan);
                tSSS0=nan(nlon*nlat,nplan);
                eSSS0=nan(nlon*nlat,nplan);
                xswathSSS0=nan(nlon*nlat,nplan);
                chiSSS0=nan(nlon*nlat,nplan);
                chiAcard0=nan(nlon*nlat,nplan);
                Rain_Rate0=nan(nlon*nlat,nplan);
                Ctrl_flags_10=nan(nlon*nlat,nplan);
                SST0=nan(nlon*nlat,nplan);
                
                % on traite le plan 1 a part pour plus de rapidite
                indp=find(sumSSS==1);
                SSS2=sum(SSS,2);
                WS2=sum(WS,2);
                Acard2=sum(Acard,2);
                tSSS2=sum(tSSS,2);
                eSSS2=sum(eSSS,2);
                xswathSSS2=sum(xswathSSS,2);
                chiSSS2=sum(chiSSS,2);
                chiAcard2=sum(chiAcard,2);
                Rain_Rate2=sum(Rain_Rate,2);
                Ctrl_flags_12=sum(Ctrl_flags_1,2);
                SST2=sum(SST,2);
                
                WS0(indp,1)=WS2(indp);
                Acard0(indp,1)=Acard2(indp);
                SSS0(indp,1)=SSS2(indp);
                tSSS0(indp,1)=tSSS2(indp);
                eSSS0(indp,1)=eSSS2(indp);
                xswathSSS0(indp,1)=xswathSSS2(indp);
                chiSSS0(indp,1)=chiSSS2(indp);
                chiAcard0(indp,1)=chiAcard2(indp);
                Rain_Rate0(indp,1)=Rain_Rate2(indp);
                Ctrl_flags_10(indp,1)=Ctrl_flags_12(indp);
                SST0(indp,1)=SST2(indp);
                
                % on traite les autres plans
                indpp=find(sumSSS>=2);
                for ii=1:length(indpp)
                    igp=indpp(ii);
                    SSS1sel=SSS1(igp,:);
                    isel=find(SSS1sel==1);
                    for jj=1:sumSSS(igp)
                        isel1=isel(jj);
                        WS0(igp,jj)=WS(igp,isel1);
                        Acard0(igp,jj)=Acard(igp,isel1);
                        SSS0(igp,jj)=SSS(igp,isel1);
                        tSSS0(igp,jj)=tSSS(igp,isel1);
                        eSSS0(igp,jj)=eSSS(igp,isel1);
                        xswathSSS0(igp,jj)=xswathSSS(igp,isel1);
                        chiSSS0(igp,jj)=chiSSS(igp,isel1);
                        chiAcard0(igp,jj)=chiAcard(igp,isel1);
                        Rain_Rate0(igp,jj)=Rain_Rate(igp,isel1);
                        Ctrl_flags_10(igp,jj)=Ctrl_flags_1(igp,isel1);
                        SST0(igp,jj)=SST(igp,isel1);
                        
                    end
                end
                
              %  keyboard
                
                WS0=reshape(WS0,nlon,nlat,nplan);
                Acard0=reshape(Acard0,nlon,nlat,nplan);
                SSS0=reshape(SSS0,nlon,nlat,nplan);
                tSSS0=reshape(tSSS0,nlon,nlat,nplan);
                eSSS0=reshape(eSSS0,nlon,nlat,nplan);
                xswathSSS0=reshape(xswathSSS0,nlon,nlat,nplan);
                chiSSS0=reshape(chiSSS0,nlon,nlat,nplan);
                chiAcard0=reshape(chiAcard0,nlon,nlat,nplan);
                Rain_Rate0=reshape(Rain_Rate0,nlon,nlat,nplan);
                Ctrl_flags_10=reshape(Ctrl_flags_10,nlon,nlat,nplan);
                SST0=reshape(SST0,nlon,nlat,nplan);
                
%                 iplan=1;
%                 figure; hold on; title('WS0');  imagesc(WS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('Acard0'); imagesc(Acard0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('SSS0'); imagesc(SSS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('tSSS0'); imagesc(tSSS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('eSSS0'); imagesc(eSSS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('xswathSSS0'); imagesc(xswathSSS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('chiSSS0'); imagesc(chiSSS0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('Dgchi2Acard0'); imagesc(chiAcard0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('RainRate0'); imagesc(Rain_Rate0(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('Ctrlflags10'); imagesc(Ctrl_flags_10(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('SST0'); imagesc(SST0(:,:,iplan)'); colorbar; hold off
               
                idwSSS0=floor((xswathSSS0+xswathmax)/pasxswath)+1;
                dualfull='full';
                                
                ind=find(isnan(Ctrl_flags_10));
                Ctrl_flags_10(ind)=0;
                cSSSbin=dec2bin(Ctrl_flags_10,32);
                
                % many outlier = 14
                ifl=double(cSSSbin(:,32-14+1));
                ifl=floor(ifl./49);
                ifl2=ifl;
                flag_many_outlier=ifl2;
                
                flag_many_outlier=reshape(flag_many_outlier,nlon,nlat,nplan);
                
                % max iter = 11
                ifl=double(cSSSbin(:,32-11+1));
                ifl=floor(ifl./49);
                ifl3=ifl;
                flag_maxiter=ifl3;
                flag_maxiter=reshape(flag_maxiter,nlon,nlat,nplan);
                
                [epsr]=KS(SST0,SSS0);
                Acard0_mod=eps2acard(epsr);
                
                
%                 figure; hold on; title('Acard0-Acardmod'); imagesc(Acard0(:,:,iplan)'-Acard0_mod(:,:,iplan)'); caxis([-2 2]); colorbar; hold off
%                 figure; hold on; title('flag_many_outlier','Interpreter','none'); imagesc(flag_many_outlier(:,:,iplan)'); colorbar; hold off
%                 figure; hold on; title('flag_maxiter','Interpreter','none'); imagesc(flag_maxiter(:,:,iplan)'); colorbar; hold off 
                
                save(filenamesave,'nplan','Rain_Rate0','WS0','SST0','SSS0','eSSS0','idwSSS0','chiSSS0','tSSS0','xswath','dualfull','Acard0','Acard0_mod','chiAcard0','flag_many_outlier','flag_maxiter')
                
                
                %  keyboard
            end
            %  keyboard
        end
        
    end
end



