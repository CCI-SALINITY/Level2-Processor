%Ce code permet de lire les donnees SMOS corriges et non corriges et estimer la correction appliquee
% revision JLV, 09/04/2021

clear all;
close all;

load ('F:\vergely\SMOS\CCI\livrables\CCI_soft_year3\aux_files\latlon_ease.mat') %fichier grille ease

output_dir='J:\SSS\data\sat\dataSMOS\CCI_repro2020\latSSTcorrected_smos\';
corr_L2='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corr_lat_pac_RR_new\';
uncorr_L2='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corrRR\';

if exist(output_dir)==0; mkdir(output_dir); end

dir_corr_L2=dir(corr_L2);
dir_uncorr_L2=dir(uncorr_L2);

nyears=length([2010:2019]);
nmonths=12;

for orb=['A']
    orb
    for ifile=3:length(dir_uncorr_L2)
        
        if strcmp(orb,dir_uncorr_L2(ifile).name(5))
            namesmos=dir_uncorr_L2(ifile).name;
            
            uncorr_fic=[uncorr_L2 dir_uncorr_L2(ifile).name];
            corr_fic=[corr_L2 dir_uncorr_L2(ifile).name];  % on prend le meme nom que uncorr
            datename=dir_uncorr_L2(ifile).name(end-11:end-4);
            
            load(uncorr_fic);
            SSS_uncorr=SSS0;
            % on met a NaN si la pluie > 10mm/h
            ind=find(Rain_Rate0>10/1000);  % RR en m/heure dans le produit
            
            load(corr_fic);
            SSScorrRRlat=SSScorrRR;  % corrige de la pluie et du biais lat
            SSScorrRRlat(ind)=NaN;  % SSS0 est la SSS corrigee de la pluie et corrigee latitudinalement
            SSS_LatSSTcorrection=SSScorrRRlat-SSS_uncorr; %a adapter selon definition biais/correction. On considere la correction de pluie dans le bilan.
            output_file=([output_dir 'smos' orb '_' datename '.mat'])
            
            save(output_file,'SSScorrRRlat','SSS_LatSSTcorrection');
            % save(output_file,'Acard','Acard_mod','Rain_Rate0','Dg_chi2_Acard','SSS0','SST0','SSS_LatSSTcorrection','WS0','chiSSS0','dualfull','eSSS0','idwSSS0','tSSS0','flag_many_outlier', 'xswath');
        end
    end
end

