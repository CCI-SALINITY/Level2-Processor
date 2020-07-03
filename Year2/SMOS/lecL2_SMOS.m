%Ce code permet de lire les donnees SMOS corriges et non corriges et estimer la correction appliquee 

clear all;
close all;

load ('../../auxilary/latlon_ease.mat') %fichier grille ease

output_dir='/net/nfs/tmp15/chakroun/L2_output/Level2_intermediate/latSSTcorrected_smos/';
corr_L2='/net/nfs/tmp15/tmpJLV/Meriem/smos/file_mat_full_corr_SST_v4/';
uncorr_L2='/net/nfs/tmp15/tmpJLV/packCCI/CCI_soft_year1/data/file_mat_full/';

nyears=length([2010:2019]);
nmonths=12;

for orb=['A' 'D']
	for yy=2:nyears
		for mm=1:nmonths
			year=2009+yy;
			if (mm>=10)
				corr_list=dir([corr_L2,'smos',orb,'_',num2str(year),num2str(mm),'*.mat']);
				uncorr_list=dir([uncorr_L2,'smos',orb,'_',num2str(year),num2str(mm),'*.mat']);
			else
				corr_list=dir([corr_L2,'smos',orb,'_',num2str(year),'0',num2str(mm),'*.mat']);
				uncorr_list=dir([uncorr_L2,'smos',orb,'_',num2str(year),'0',num2str(mm),'*.mat']);
			end	
			ndays=length(corr_list);
			for dd=1:ndays
				SSS0=[];correction=[];
				uncorr_fic=([uncorr_L2,uncorr_list(dd).name]);
				day=uncorr_fic(end-5:end-4);
				load(uncorr_fic);
				SSS_uncorr=SSS0;
				Acard=[];Acard_mod=[];Dg_Suspect_ice0=[];Dg_chi2_Acard=[];SST0=[];
				SSS0=[];WS0=[];chiSSS0=[];dualfull=[];eSSS0=[];idwSSS0=[];tSSS0=[];xswath=[];
				corr_fic=([corr_L2,corr_list(dd).name]);
				load(corr_fic);
				SSS_LatSSTcorrection=SSS0-SSS_uncorr; %a adapter selon definition biais/correction
				if (mm>=10)
					output_file=([output_dir,'smosL2P_',num2str(year),num2str(mm),day,'_',orb,'.mat'])
				else
					output_file=([output_dir,'smosL2P_',num2str(year),'0',num2str(mm),day,'_',orb,'.mat'])
				end
				save(output_file,'Acard','Acard_mod','Dg_Suspect_ice0','Dg_chi2_Acard','SSS0','SST0','SSS_LatSSTcorrection','WS0','chiSSS0','dualfull','eSSS0','idwSSS0','tSSS0','flag_many_outlier', 'xswath');
			end
		end
	end
end



