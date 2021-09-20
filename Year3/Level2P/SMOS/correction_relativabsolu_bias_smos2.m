% Ce code permet de lire les donnees SMOS corriges de la SST et biais lat et de les corriger par rapport au biais absolu et relatif
% il merge deux programmes (lecL2_SMOS + correction_relativabsolu_bias initiaux)
% 27/04/2021 : ajout rain rate dans les sorties
% isc_qc non mis partout à -1 entre 45S et 45N


clear
close all;

load ('F:\vergely\SMOS\CCI\livrables\CCI_soft_year3\corrbias2021_v3.2','-mat')                            %fichier biais
load('F:\vergely\SMOS\CCI\livrables\CCI_soft_year3\aux_files\maskdmin_ease2.mat')                           %fichier grille distance min cote
load ('F:\vergely\SMOS\CCI\livrables\CCI_soft_year3\aux_files\latlon_ease.mat')                             %fichier grille ease
load ('F:\vergely\SMOS\CCI\livrables\CCI_soft_year3\aux_files\ERR_REP\ERR_REP_1d50km_30d50km_mr2_ctm.mat')  %variabilite hebdomadaire
load('mask_smos.mat')

nlat=length(lat_ease);
nlon=length(lon_ease);

output='J:\SSS\data\sat\dataSMOS\CCI_repro2020\Totallycorrected_smos\';                 %output directory
input_dir='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corrRR\';               %input directory
input_dir2='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corr_lat_pac_RR_new\'; %input directory
input_Acard='J:\SSS\CCI\2020\Acard_mask\masqueAcard_10\';                               %input directory

% traitement de la terre : masque de la v2.3 (mask_smos.mat)
ind=find(mask==1);
mask(ind)=0;
ind=find(isnan(mask));
mask(ind)=1;

if exist(output)==0; mkdir(output); end;

dirL2=dir(input_dir);
dirL22=dir(input_dir2);
L4_dir=('J:\SSS\CCI\2021\res3\30days\');

indxswath=find(abs(xswath)<xswathlim);
maxidw=max(indxswath);
minidw=min(indxswath);

for orb=['A']
    for ii=3:length(dirL2)
        if strcmp(orb,dirL2(ii).name(5))
            
            yyyy=dirL2(ii).name(7:10);
            mm=dirL2(ii).name(11:12);
            
            % fichier SSS SMOS L2 uncorr
            fic=([input_dir,dirL2(ii).name]);
            load(fic,'SSS0','Rain_Rate0','chiSSS0','WS0','SST0');   % 'SSS0  (uncorr)
            SSS_uncorr=SSS0;
            ind=find(Rain_Rate0>10/1000);  % RR en m/heure dans le produit
            SSS_uncorr(ind)=NaN;
            
            % fichier SSS SMOS L2 corr RR et lat
            fic2=([input_dir2,dirL2(ii).name]); % meme nom de fichier. On extrait SSScorrRR (correction RR et lat)
            load(fic2,'SSScorrRR','eSSS0','idwSSS0');
            
            orb=dirL2(ii).name(5);
            
            SSS_LatSSTcorrection=SSScorrRR-SSS_uncorr;  %remplace ce qui est fait dans lecL2_SMOS
            
            nplan=size(SSScorrRR,3);
            
            SSSsel=nan(nlon,nlat,nplan);
            SSS_latSSTcorr=nan(nlon,nlat,nplan);
            SSS_random=nan(nlon,nlat,nplan);
            sss_qc_smos=zeros(nlon,nlat,nplan);
            SSS_corrabs=nan(nlon,nlat,nplan);
            
            %on coupe les bouts de la trace
            II=[];
            II=find(idwSSS0<=maxidw & idwSSS0>=minidw);
            SSSsel(II)=SSScorrRR(II);  % year3 : SSS corrigees de la pluie et lat
            SSS_latSSTcorr(II)=SSS_LatSSTcorrection(II);
            SSS_random(II)=eSSS0(II);
            
            %on fait correction absolue pour les differents plans
            for iplan=1:nplan
                SSS_corrabs(:,:,iplan)=SSSsel(:,:,iplan)-biais_absolu;
            end
            
            %on fait correction relative plan par plan
            if orb=='A'
                biais_dwell=biais_relative(:,:,1:34);
            else
                biais_dwell=biais_relative(:,:,35:68);
            end
            SSS_corr=nan(nlon,nlat,nplan);
            for iplan=1:nplan
                idwplan=squeeze(idwSSS0(:,:,iplan));
                SSS_corrabsplan=squeeze(SSS_corrabs(:,:,iplan));
                SSS_corrplan=nan(nlon,nlat);
                for indx=1:length(indxswath)
                    II=find(idwplan==indxswath(indx));
                    Biais_relatif=squeeze(biais_dwell(:,:,indx));
                    SSS_corrplan(II)=SSS_corrabsplan(II)+Biais_relatif(II);
                end
                SSS_corr(:,:,iplan)=SSS_corrplan;
            end
            
            % estimer correction totale
            totalcorrection=SSS_latSSTcorr+SSS_corr-SSSsel;
            
            KK=find(abs(totalcorrection)>=20); % ajoute le 05/10/2020
            SSS_corr(KK)=nan; % ajoute le 05/10/2020
            
            % corriger erreur aleatoire salinite
            p1=-1.773e-11; p2=1.025e-07; p3=-2.057e-04;  p4=1.140;
            
            error_factor_smos=p1.*dmin.^3+p2.*dmin.^2+p3.*dmin+p4;
            ind=find(error_factor_smos<1);
            error_factor_smos(ind)=1;
            
            % estimer sss_qc_smos
            L4_file=[L4_dir yyyy '\ESACCI-SEASURFACESALINITY-L4-SSS-MERGED_OI_Monthly_CENTRED_15Day_25km-',yyyy,mm,'15-fv3.2.nc'];
            nc=netcdf.open(L4_file,'nowrite');
            
            sss_ID=netcdf.inqVarID(nc,'sss');
            sss_ref_L4=double(netcdf.getVar(nc,sss_ID));
            ssserror_ID=netcdf.inqVarID(nc,'sss_random_error');
            sss_erreur_L4=double(netcdf.getVar(nc,ssserror_ID));
            netcdf.close(nc);
            
            imonth=str2num(mm);
            hebdo=squeeze(errrepres(:,:,imonth));
            
            % on dupplique la SSS L4 et l'erreur L4 sur le nombre de plan
            sss_ref_L4_2=nan(nlon,nlat,nplan);
            sss_erreur_L4_2=nan(nlon,nlat,nplan);
            error_factor_smos_2=nan(nlon,nlat,nplan);
            hebdo_2=nan(nlon,nlat,nplan);
            for iplan=1:nplan
                sss_ref_L4_2(:,:,iplan)=sss_ref_L4;
                sss_erreur_L4_2(:,:,iplan)=sss_erreur_L4;
                error_factor_smos_2(:,:,iplan)=error_factor_smos;
                hebdo_2(:,:,iplan)=hebdo;
            end
            
            SSS_random=SSS_random.*error_factor_smos_2.*chiSSS0;
            sigma=sqrt(SSS_random.^2+hebdo_2.^2+sss_erreur_L4_2.^2);
            
            II=find(abs(SSS_corr-sss_ref_L4_2)>3*sigma | SSS_random>3);  % cas ou on leve le flag
            sss_qc_smos(II)=1;
            
            % flag glace
            SSTseuil=8;
            nameAcard=[input_Acard filesep 'Acard_' dirL2(ii).name(7:14) '.mat'];
            load(nameAcard,'propsup1','SST_mean','ndata','indlat');
            % ind_ice=find(Acard_mean<40);
            ind_ice=find((propsup1>0.2 & SST_mean<=SSTseuil) | ndata<5);
            mask_ice=zeros(size(SST_mean,1),size(SST_mean,2));
            mask_ice(ind_ice)=1;

            II=find(isnan(sss_ref_L4_2) | isnan(SSS_corr) |  isnan(sigma) | SSS_corr<0 | SSS_corr>40); % cas ou on ne regarde pas le flag, on le met = fillvalue

           % initialisation masque glace
           % si SSS est NaN, mask1=-1
            mask1=zeros(length(lon_ease),length(lat_ease),nplan);  % d'abord sur l'ensemble de la carte initialisation du flag ice a 0
            mask1(II)=-1;
            
            % on met le flag sur les differents plans
            isc_qc=zeros(nlon,nlat,nplan);
            for iplan=1:nplan
                mask2=squeeze(mask1(:,:,iplan));
                mask2(:,indlat,1)=mask_ice;
                isc_qc(:,:,iplan)=mask2;
            end
            
            % flag terre
            lsc_qc=zeros(nlon,nlat,nplan);
            for iplan=1:nplan
                lsc_qc(:,:,iplan)=mask;
            end
            
            % cas ou la SSS n'est pas renseignee, on met les flag a fill value = -1
            sss_qc_smos(II)=-1;
            isc_qc(II)=-1;
            lsc_qc(II)=-1;
            SSS_corr(II)=nan;
            SSS_random(II)=nan;
            sigma(II)=nan;
            totalcorrection(II)=nan;
            chiSSS0(II)=nan;
            WS0(II)=nan;
            SST0(II)=nan;
                        
            output_file=[output,dirL2(ii).name] % meme nom de fichier
            save(output_file,'SSS_corr','totalcorrection','WS0','SST0','chiSSS0','SSS_random','sigma','sss_qc_smos','isc_qc','lsc_qc','Rain_Rate0');
        end
    end
    
end
