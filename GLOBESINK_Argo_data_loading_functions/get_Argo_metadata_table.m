function [bio_metadata_ix_table] = get_Argo_metadata_table(float_WMOs,...
    BGC_Argo_data_folder,redownload_metadata_index_file)
% [bio_metadata_ix_table] = get_Argo_metadata_table(float_WMOs,BGC_Argo_data_folder,redownload_metadata_index_file);

% redownload_metadata_index_file = 1;

if exist(BGC_Argo_data_folder,'dir')

cd(BGC_Argo_data_folder)
%%
remote_folder = 'ftp://ftp.ifremer.fr/ifremer/argo/';
ixfile_name = 'ar_index_global_meta.txt';

%% download bioargo index file
if redownload_metadata_index_file||~exist(ixfile_name,'file')
    urlwrite([remote_folder ixfile_name],ixfile_name);
end
%% import bioargo index file to Matlab
bio_metadata_ix_table = readtable(ixfile_name,'headerlines',8,'delimiter',',');
bio_folder_table = readtable(ixfile_name,'headerlines',9,'delimiter','/','readvariablenames',false);
bio_folder_table.Properties.VariableNames = {'dac','float','misc'};
bio_metadata_ix_table = [bio_metadata_ix_table bio_folder_table(:,1:2)];

%% select good floats
is_good_float = (ismember(bio_metadata_ix_table.float,float_WMOs));
bio_metadata_ix_table = bio_metadata_ix_table(is_good_float,:);

%% make dac and institution fields categorical
bio_metadata_ix_table.institution = categorical(bio_metadata_ix_table.institution);
bio_metadata_ix_table.dac = categorical(bio_metadata_ix_table.dac);

%% get mtime
bio_metadata_ix_table.mtime_update = datenum(num2str(bio_metadata_ix_table.date_update),'yyyymmddHHMMSS');
end