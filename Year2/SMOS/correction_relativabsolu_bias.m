%Ce code permet de lire les donnees SMOS corriges de la SST et biais lat et de les corriger par rapport au biais absolu et relatif

clear all;
close all;

load ('../../auxilary/corrbias2020.mat')  %fichier biais 
load('../../auxilary/maskdmin_ease2.mat') %fichier grille distance min cote
load ('../../auxilary/latlon_ease.mat') %fichier grille ease
load ('../../auxilary/ERR_REP_50km1d_50km30d_smooth.mat') %variabilite hebdomadaire

nlat=length(lat_ease);
nlon=length(lon_ease);

output='/net/nfs/tmp15/chakroun/L2_output/Level2_intermediate/Totallycorrected_smos/';%output directory
input_dir='/net/nfs/tmp15/chakroun/L2_output/Level2_intermediate/latSSTcorrected_smos/';%input directory

dirL2=dir(input_dir);
L4_dir=('/net/nfs/tmp15/tmpJLV/CCI/month_q2/');

indxswath=find(abs(xswath)<xswathlim);
maxidw=max(indxswath);
minidw=min(indxswath);

for ii=3:length(dirL2)
	SSSsel=nan*ones(nlon,nlat);
	SSS_latSSTcorr=nan*ones(nlon,nlat);
	SSS_random=nan*ones(nlon,nlat);
	totalcorrection=nan*ones(nlon,nlat);

	fic=([input_dir,dirL2(ii).name]);
	yyyy=dirL2(ii).name(9:12);
	mm=dirL2(ii).name(13:14);
	load(fic);
	orb=dirL2(ii).name(end-4);

	%on coupe les bouts de la trace
	II=[];
	II=find(idwSSS0<=maxidw & idwSSS0>=minidw);
	SSSsel(II)=SSS0(II);
	SSS_latSSTcorr(II)=SSS_LatSSTcorrection(II);
	SSS_random(II)=eSSS0(II);

	%on fait correction absolue
	SSS_corrabs=[];
	SSS_corrabs=SSSsel-biais_absolu;

	%on fait correction relative
	biais_dwell=nan*ones(nlon,nlat);
	if orb=='A'
        	biais_dwell=biais_relative(:,:,1:34);
    	else
        	biais_dwell=biais_relative(:,:,35:68);
    	end
	SSS_corr=nan*ones(nlon,nlat);
	for indx=1:length(indxswath)
		II=[];
		II=find(idwSSS0==indxswath(indx));
		Biais_relatif=squeeze(biais_dwell(:,:,indx));
		SSS_corr(II)=SSS_corrabs(II)+Biais_relatif(II);
	end

	%estimer correction totale
	totalcorrection=nan*ones(nlon,nlat);
	totalcorrection=SSS_latSSTcorr+SSS_corr-SSSsel;

	%corriger erreur aleatoire salinite
	p1=-1.773e-11; p2=1.025e-07; p3=-2.057e-04;  p4=1.140;

	error_factor_smos=p1.*dmin.^3+p2.*dmin.^2+p3.*dmin+p4;
	ind=find(error_factor_smos<1);
	error_factor_smos(ind)=1;
	
	SSS_random=SSS_random.*error_factor_smos.*chiSSS0;

	%estimer sss_qc_smos

	L4_file=([L4_dir,'ESACCI-SEASURFACESALINITY-L4-SSS-MERGED_OI_Monthly_CENTRED_15Day_25km-',yyyy,mm,'01-fv03.nc']);
	nc=netcdf.open(L4_file,'nowrite');

	sss_ID=netcdf.inqVarID(nc,'sss');
	sss_ref_L4=double(netcdf.getVar(nc,sss_ID));

	ssserror_ID=netcdf.inqVarID(nc,'sss_random_error');
	sss_erreur_L4=double(netcdf.getVar(nc,ssserror_ID));

	sss_qc_smos=nan(nlon,nlat);
	hebdo=squeeze(errrepres(:,:,str2num(mm)));
	sigma=sqrt(SSS_random.^2+hebdo.^2+sss_erreur_L4.^2);

	JJ=[];
	JJ=find(SSS_corr>0);
	sss_qc_smos(JJ)=0;

	II=[];
	II=find(abs(SSS_corr-sss_ref_L4)>3*sigma);
	sss_qc_smos(II)=1;

	netcdf.close(nc);

	output_file=[output,'smosL2corrected_',dirL2(ii).name(9:end-4)]
	save(output_file,'Acard','Acard_mod','Dg_Suspect_ice0','Dg_chi2_Acard','SSS_corr','totalcorrection','SST0','WS0','chiSSS0','flag_many_outlier','dualfull','SSS_random','idwSSS0','tSSS0','xswathsel', 'sss_qc_smos');
end
