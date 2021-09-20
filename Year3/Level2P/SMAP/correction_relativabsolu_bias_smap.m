% Ce code permet de lire les donnees SMAP corriges de la SST et biais lat et de les corriger par rapport au biais absolu et relatif
% changement isc
% ajout rain rate

clear
close all;

load ('G:\CCI2021\corrbias2021_v3.2','-mat')                    %fichier biais
load('G:\CCI2021\maskdmin_ease2.mat')                           %fichier grille distance min cote
load ('G:\CCI2021\latlon_ease.mat')                             %fichier grille ease
load ('G:\CCI2021\ERR_REP\ERR_REP_1d50km_30d50km_mr2_ctm.mat')  %variabilite hebdomadaire
load('G:\CCI2021\mask_smos.mat')

nlat=length(lat_ease);
nlon=length(lon_ease);

output='G:\CCI2021\Smap\Totallycorrected_smap\';                %output directory
input_dir='G:\CCI2021\Smap\file_mat_40km\';                     %input directory
input_Acard='G:\CCI2021\masqueAcard_10\';                       %input directory

% traitement de la terre : masque de la v2.3 (mask_smos.mat)
ind=find(mask==1);
mask(ind)=0;
ind=find(isnan(mask));
mask(ind)=1;

if exist(output)==0; mkdir(output); end;

dirL2=dir(input_dir);
L4_dir=('G:\CCI2021\res3\30days\');
%L4_dir=('G:\CCI2021\30days\');

indxswath=find(abs(xswath)<xswathlim);
maxidw=max(indxswath);
minidw=min(indxswath);

for orb=['D']
    for ii=3:length(dirL2)
        if strcmp(orb,dirL2(ii).name(5))
            
            
            
            fic=([input_dir,dirL2(ii).name]);
            load(fic);
            yyyy=dirL2(ii).name(7:10);
            mm=dirL2(ii).name(11:12);
            orb=dirL2(ii).name(5);
            
            tSSS0(:,:,1)=tSSS1;
            tSSS0(:,:,2)=tSSS2;
            
            % filtrage pluie
            ind=find(rain1>0.5);  % on filtre si pluie > 0.5 mm/h
            SSS1(ind)=NaN;
            ind=find(rain2>0.5);  % on filtre si pluie > 0.5 mm/h
            SSS2(ind)=NaN;
            
            % correction absolue
            SSS_corrabs=nan*ones(nlon,nlat,2);
            SSS_corrabs(:,:,1)=SSS1-biais_absolu;
            SSS_corrabs(:,:,2)=SSS2-biais_absolu;
            
            % correction relative
            
            biais_dwell=nan*ones(nlon,nlat);
            if orb=='A'
                biais_dwell=biais_relative(:,:,69:70);
            else
                biais_dwell=biais_relative(:,:,71:72);
            end
            
            %definition des variables a sauvegarder
            
            SSS_corr=nan*ones(nlon,nlat,2);
            SST0=nan*ones(nlon,nlat,2);
            WS0=nan*ones(nlon,nlat,2);
            chiSSS0=ones(nlon,nlat,2);
            totalcorrection=nan*ones(nlon,nlat,2);
            SSS_random=nan*ones(nlon,nlat,2);
            Rain_Rate0=nan*ones(nlon,nlat,2);
            
            SST0(:,:,1)=SST1;
            SST0(:,:,2)=SST2;
            
            WS0(:,:,1)=WS1;
            WS0(:,:,2)=WS2;
            
            Rain_Rate0(:,:,1)=rain1./1000;  % conversion en m/h
            Rain_Rate0(:,:,2)=rain2./1000;
            
            SSS_corr(:,:,1)=squeeze(SSS_corrabs(:,:,1))+biais_dwell(:,:,1);% unbiased sss
            SSS_corr(:,:,2)=squeeze(SSS_corrabs(:,:,2))+biais_dwell(:,:,2);
            
            totalcorrection(:,:,1)=biais_dwell(:,:,1)-biais_absolu;% -systematic error on sss
            totalcorrection(:,:,2)=biais_dwell(:,:,2)-biais_absolu;
            
            II=[];
            II=find(isnan(SSS_corr));
            totalcorrection(II)=NaN;
            KK=[];% ajoute le 05/10/2020
            KK=find(abs(totalcorrection)>=20);% ajoute le 05/10/2020
            SSS_corr(KK)=nan;% ajoute le 05/10/2020
            
            %random error on sss
            
            SSS_random(:,:,1) = 0.38./(0.015.*SST1+0.25);
            SSS_random(:,:,2) = 0.38./(0.015.*SST2+0.25);
            
            p1=0.002991909878747; p2=-0.057895699052765; p3=0.454231563716574;
            p4=-1.869918681721869; p5=4.369867374935416; p6=-5.877381371897917;
            p7=4.439753964071140; p8=-1.785811244191490; p9=1.353937878613555;
            
            dmin1=dmin/1000;
            error_factor_smap=p1.*dmin1.^8+p2.*dmin1.^7+p3.*dmin1.^6+p4.*dmin1.^5+p5.*dmin1.^4+p6.*dmin1.^3+p7.*dmin1.^2+p8.*dmin1+p9;
            ind=find(error_factor_smap<1 | dmin>3000); error_factor_smap(ind)=1;
            
            SSS_random(:,:,1)=squeeze(SSS_random(:,:,1)).*error_factor_smap;
            SSS_random(:,:,2)=squeeze(SSS_random(:,:,2)).*error_factor_smap;
            
            %sss quality check
            L4_file=([L4_dir yyyy '\ESACCI-SEASURFACESALINITY-L4-SSS-MERGED_OI_Monthly_CENTRED_15Day_25km-',yyyy,mm,'15-fv3.2.nc']);
            %L4_file=([L4_dir yyyy '\ESACCI-SEASURFACESALINITY-L4-SSS-MERGED_OI_Monthly_CENTRED_15Day_25km-',yyyy,mm,'15-fv3.1.nc']);
            
            nc=netcdf.open(L4_file,'nowrite');
            
            sss_ID=netcdf.inqVarID(nc,'sss');
            sss_ref_L4=double(netcdf.getVar(nc,sss_ID));
            
            ssserror_ID=netcdf.inqVarID(nc,'sss_random_error');
            sss_erreur_L4=double(netcdf.getVar(nc,ssserror_ID));
            
            sss_qc_smap=zeros(nlon,nlat,2);
            hebdo=squeeze(errrepres(:,:,str2num(mm)));
            
            sss_ref_L4_2=0*SSS_random;
            for dd=1:2
                sigma(:,:,dd)=sqrt(squeeze(SSS_random(:,:,dd)).^2+hebdo.^2+sss_erreur_L4.^2);
                sss_ref_L4_2(:,:,dd)=sss_ref_L4;
            end
            
            II=find(abs(SSS_corr-sss_ref_L4_2)>3*sigma | SSS_random>3);  % cas ou on leve le flag
            sss_qc_smap(II)=1;
                                        
            % flag glace
            SSTseuil=8;
            nameAcard=[input_Acard filesep 'Acard_' dirL2(ii).name(7:14) '.mat'];
            load(nameAcard,'propsup1','SST_mean','ndata','indlat');
            % ind_ice=find(Acard_mean<40);
            nlatice=length(indlat);
            propsup2=zeros(nlon,nlatice,2);
            ndata2=zeros(nlon,nlatice,2);
            SST_mean2=zeros(nlon,nlatice,2);            
            for dd=1:2
                propsup2(:,:,dd)=propsup1;
                ndata2(:,:,dd)=ndata;
                SST_mean2(:,:,dd)=SST_mean;
            end
            
            ind_ice=find((propsup2>0.2 & SST_mean2<=SSTseuil) | ndata2<5);
            
            II=find(isnan(sss_ref_L4_2) | isnan(SSS_corr) |  isnan(sigma) | SSS_corr<0 | SSS_corr>40); % cas ou on ne regarde pas le flag, on le met = fillvalue

            mask1=zeros(length(lon_ease),length(lat_ease),2);  % d'abord sur l'ensemble de la carte initialisation du flag ice a 0
            mask1(II)=-1;
            
            mask_ice=zeros(size(SST_mean,1),size(SST_mean,2),2);
            mask_ice(ind_ice)=1;
            mask1(:,indlat,:)=mask_ice;
            % on met le flag sur les differents plans
            isc_qc=mask1;
           
             % flag terre
            lsc_qc=zeros(nlon,nlat,2);
            for iplan=1:2
                lsc_qc(:,:,iplan)=mask;
            end
                        
            % cas ou la SSS n'est pas renseignee, on met les flag a fill value = -1
            sss_qc_smap(II)=-1;
            isc_qc(II)=-1;
            lsc_qc(II)=-1;
            SSS_corr(II)=nan;
            SSS_random(II)=nan;
            totalcorrection(II)=nan;
            chiSSS0(II)=nan;
            
            output_file=[output,dirL2(ii).name] % meme nom de fichier
            save(output_file,'SSS_corr','totalcorrection','chiSSS0','WS0','SST0','tSSS0','SSS_random','sss_qc_smap','isc_qc','lsc_qc','Rain_Rate0');
                        
        end
    end
    
end
