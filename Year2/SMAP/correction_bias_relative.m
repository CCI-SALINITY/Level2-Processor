% Reading SSS from SMAP and apply relative and absolute corrections 

clear all;
close all;

load ('../../auxilary/corrbias2020.mat')  %SSS biases 
load('../../auxilary/maskdmin_ease2.mat') %coast min distance 
load ('../../auxilary/ERR_REP_50km1d_50km30d_smooth.mat') %natural variability
load ('../../auxilary/latlon_ease.mat') %EASE grid file
nlat=length(lat_ease);
nlon=length(lon_ease);

output='../../../L2_output/Level2_intermediate/Totallycorrected_smap/';%output directory
input_dir='../../../file_mat_40km/';%input directory with .mat SMAP files
dirL2=dir(input_dir);
L4_dir=('../../../CCI/month_q2/');%monthly Level 4 directory

for ii=3:length(dirL2)
	
	fic=([input_dir,dirL2(ii).name]);
	load(fic);
	yyyy=dirL2(ii).name(7:10);
	mm=dirL2(ii).name(11:12);
	orb=dirL2(ii).name(5);
	
	tSSS0(1,:,:)=tSSS1;
	tSSS0(2,:,:)=tSSS2;

	% correction absolue
	SSS_corrabs=nan*ones(2,nlon,nlat);
	SSS_corrabs(1,:,:)=SSS1-biais_absolu;
	SSS_corrabs(2,:,:)=SSS2-biais_absolu;

	% correction relative

	biais_dwell=nan*ones(nlon,nlat);
	if orb=='A'
        	biais_dwell=biais_relative(:,:,69:70);
    	else
        	biais_dwell=biais_relative(:,:,71:72);
    	end

	%definition des variables a sauvegarder

	SSS_corr=nan*ones(2,nlon,nlat);
	SST0=nan*ones(2,nlon,nlat);
	WS0=nan*ones(2,nlon,nlat);
	totalcorrection=nan*ones(2,nlon,nlat);
	SSS_random=nan*ones(2,nlon,nlat);

	SST0(1,:,:)=SST1;
	SST0(2,:,:)=SST2;

	WS0(1,:,:)=WS1;
	WS0(2,:,:)=WS2;

	SSS_corr(1,:,:)=squeeze(SSS_corrabs(1,:,:))+biais_dwell(:,:,1);% unbiased sss
	SSS_corr(2,:,:)=squeeze(SSS_corrabs(2,:,:))+biais_dwell(:,:,2);

	totalcorrection(1,:,:)=biais_dwell(:,:,1)-biais_absolu;% -systematic error on sss
	totalcorrection(2,:,:)=biais_dwell(:,:,2)-biais_absolu;

	II=[];
	II=find(isnan(SSS_corr));
	totalcorrection(II)=NaN;

	%random error on sss

	SSS_random(1,:,:) = 0.38./(0.015.*SST1+0.25);
	SSS_random(2,:,:) = 0.38./(0.015.*SST2+0.25);

	p1=0.002991909878747; p2=-0.057895699052765; p3=0.454231563716574;
	p4=-1.869918681721869; p5=4.369867374935416; p6=-5.877381371897917;
	p7=4.439753964071140; p8=-1.785811244191490; p9=1.353937878613555;

	dmin1=dmin/1000;
	error_factor_smap=p1.*dmin1.^8+p2.*dmin1.^7+p3.*dmin1.^6+p4.*dmin1.^5+p5.*dmin1.^4+p6.*dmin1.^3+p7.*dmin1.^2+p8.*dmin1+p9;
	ind=find(error_factor_smap<1 | dmin>3000); error_factor_smap(ind)=1;

	SSS_random(1,:,:)=squeeze(SSS_random(1,:,:)).*error_factor_smap;
	SSS_random(2,:,:)=squeeze(SSS_random(2,:,:)).*error_factor_smap;

	%sss quality check

	L4_file=([L4_dir,'ESACCI-SEASURFACESALINITY-L4-SSS-MERGED_OI_Monthly_CENTRED_15Day_25km-',yyyy,mm,'01-fv03.nc']);
	nc=netcdf.open(L4_file,'nowrite');

	sss_ID=netcdf.inqVarID(nc,'sss');
	sss_ref_L4=double(netcdf.getVar(nc,sss_ID));

	ssserror_ID=netcdf.inqVarID(nc,'sss_random_error');
	sss_erreur_L4=double(netcdf.getVar(nc,ssserror_ID));

	sss_qc_smap=zeros(2,nlon,nlat);
	hebdo=squeeze(errrepres(:,:,str2num(mm)));

	for dd=1:2
		sigma(dd,:,:)=sqrt(squeeze(SSS_random(dd,:,:)).^2+hebdo.^2+sss_erreur_L4.^2);
	end

	sss_qcsmap=nan(nlon,nlat);
	JJ=[];
	JJ=find(SSS_corr>0);
	sss_qc_smap(JJ)=0;

	II=[];
	II=find(abs(squeeze(SSS_corr(1,:,:))-sss_ref_L4)>3*squeeze(sigma(1,:,:)));
	sss_qcsmap(II)=1;
	sss_qc_smap(1,:,:)=sss_qcsmap;

	sss_qcsmap=nan(nlon,nlat);
	JJ=[];
	JJ=find(abs(squeeze(SSS_corr(2,:,:))-sss_ref_L4)>3*squeeze(sigma(2,:,:)));
	sss_qcsmap(JJ)=1;
	sss_qc_smap(2,:,:)=sss_qcsmap;	

	%write .mat output file

	output_file=[output,'smapL2corrected_',dirL2(ii).name(7:end-4),'_',orb]
	save(output_file,'SSS_corr', 'totalcorrection','SST0', 'WS0', 'SSS_random','tSSS0','sss_qc_smap');
	netcdf.close(nc)
end
