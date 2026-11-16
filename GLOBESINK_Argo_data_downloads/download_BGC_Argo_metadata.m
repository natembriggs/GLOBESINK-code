function download_status = download_BGC_Argo_metadata(bio_metadata_ix_table,BGC_Argo_data_folder)
% download_status = download_BGC_Argo_metadata(bio_metadata_ix_table,download_home);

% ????????? FTP FOLDER CONTAINING ARGO DATA (DO NOT CHANGE) ?????????
remote_folder = 'ftp://ftp.ifremer.fr/ifremer/argo/';
download_status = false;

if exist(BGC_Argo_data_folder,'dir')
    %%
    str = 'y';
%     if download_data
        %% DOWNLOAD DATA containing key parameters and within latlon limits
        disp([num2str(height(bio_metadata_ix_table)) ' floats selected'])
        disp(['checking which float metadata are already downloaded'])

        is_downloaded = false(height(bio_metadata_ix_table),1); % logical array of 0's the height of bio_ix_table (just one column) 
        for ii = 1:min(height(bio_metadata_ix_table),Inf)
            cd(BGC_Argo_data_folder)

%             float_root_folder = bio_metadata_ix_table.file{ii}(1:end-25);
%             subfolders = bio_ix_table_latest.file{ii}(1:end-16);
%             metafilename = [num2str(bio_metadata_ix_table.float(ii)) '_meta.nc'];
            subfolders = [char(bio_metadata_ix_table.dac(ii)) '/' num2str(bio_metadata_ix_table.float(ii))];
            metafilename = bio_metadata_ix_table.file{ii};
            if exist(subfolders,'dir') && exist([BGC_Argo_data_folder metafilename],'file')
                is_downloaded(ii) = 1;
            end
        end
        disp([num2str(sum(is_downloaded)) ' out of ' num2str(height(bio_metadata_ix_table)) ' files already downloaded'])
%         if sum(~is_downloaded) > 0
%             prompt = ['Download remaining ' num2str(sum(~is_downloaded)) ' files (~' ...
%                 num2str(sum(~is_downloaded)*0.25) ' MB)? y/n [n]: '];
%             str = input(prompt,'s');
%         end
%         if isempty(str) %filling string with prompt response: take no response (just enter) as a no
%             str = 'n';
%         end
        %%
        if strcmp(str,'y')||strcmp(str,'Y') && any(~is_downloaded)
            download_ixs = find(~is_downloaded); %index of the the un-downloaded profile files 
            %%
            for download_ixs_ix = 1:length(download_ixs)
                ii = download_ixs(download_ixs_ix);
                cd(BGC_Argo_data_folder)
                subfolders = [char(bio_metadata_ix_table.dac(ii)) '/' num2str(bio_metadata_ix_table.float(ii))];
                if ~exist(subfolders,'dir')
                    mkdir(subfolders)
                end
                metafilename = bio_metadata_ix_table.file{ii};
%                 metafilename = [num2str(bio_metadata_ix_table.float(ii)) '_meta.nc'];
                if ~exist([BGC_Argo_data_folder metafilename],'file')
%                     [~,status] = urlread([remote_folder 'dac/' bio_ix_table.file{ii}]);
%                     if status
%                         urlwrite([remote_folder 'dac/' bio_ix_table.file{ii}],[BGC_Argo_data_folder bio_ix_table.file{ii}]);
%                         disp(bio_ix_table.file{ii})
%                     else
%                         disp(['remote file not found: ' remote_folder 'dac/' bio_ix_table.file{ii}])
%                     end
                    
                    try 
                        urlwrite([remote_folder 'dac/' metafilename],[BGC_Argo_data_folder metafilename]);
                        disp([metafilename])
                    catch
                        disp(['remote file not found: ' remote_folder 'dac/' metafilename])
                    end
                end
            end
            download_status = true;
        end
%     end
else
    disp(['folder not found: ' download_home])
end