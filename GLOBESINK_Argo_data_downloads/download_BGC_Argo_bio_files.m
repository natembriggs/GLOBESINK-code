function download_status = download_BGC_Argo_bio_files(bio_ix_table,BGC_Argo_data_folder,redownload_GDAC_files_if_newer)
% download_status = download_BGC_Argo_bio_files(bio_ix_table,download_home,redownload_GDAC_files_if_newer);

if nargin == 2
    redownload_GDAC_files_if_newer = 0;
end
%%
% ????????? FTP FOLDER CONTAINING ARGO DATA (DO NOT CHANGE) ?????????
remote_folder = 'ftp://ftp.ifremer.fr/ifremer/argo/';
download_status = false(height(bio_ix_table),1);

if exist(BGC_Argo_data_folder,'dir')
    %%
    str = 'y';
%     if download_data
        %% DOWNLOAD DATA containing key parameters and within latlon limits
        disp('downloading bio files')
        disp([num2str(height(bio_ix_table)) ' profiles selected'])
        disp(['checking which profiles are already downloaded'])

        is_downloaded = false(height(bio_ix_table),1); %logical array of 0's the height of bio_ix_table (just one column) 
%         if ~redownload_updated_files
            for ii = 1:min(height(bio_ix_table),Inf)
                cd(BGC_Argo_data_folder)
                sfile_name = bio_ix_table.file{ii};
                slash_ixs = find(sfile_name == '/');
                bfile_name = sfile_name; %bfile_name(slash_ixs(end)+1) = 'B';
                subfolders = bfile_name(1:slash_ixs(end));
                if exist(subfolders,'dir') && exist([BGC_Argo_data_folder bfile_name],'file')
                    if redownload_GDAC_files_if_newer
                        finfo = dir([BGC_Argo_data_folder bfile_name]);
                        is_downloaded(ii) = bio_ix_table.mtime_update(ii) <= datenum(finfo.date);
                    else
                        is_downloaded(ii) = 1;
                    end
                end
            end
%         end
        if redownload_GDAC_files_if_newer
            disp('overwriting old files if newer file available at GDAC')
        end
        disp([num2str(sum(is_downloaded)) ' out of ' num2str(height(bio_ix_table)) ' profiles already downloaded'])
        if sum(~is_downloaded) >0
            prompt = ['Download remaining ' num2str(sum(~is_downloaded)) ' profiles (~' ...
                num2str(sum(~is_downloaded)*0.25) ' MB)? y/n [n]: '];
            str = input(prompt,'s');
        end
        if isempty(str) %filling string with prompt response: take no response (just enter) as a no
            str = 'n';
        end
        if strcmp(str,'y')||strcmp(str,'Y')
            download_ixs = find(~is_downloaded); %index of the the un-downloaded profile files 
            %%
            for download_ixs_ix = 1:length(download_ixs)
                ii = download_ixs(download_ixs_ix);
                cd(BGC_Argo_data_folder)
                sfile_name = bio_ix_table.file{ii};
                slash_ixs = find(sfile_name == '/');
                bfile_name = sfile_name; %bfile_name(slash_ixs(end)+1) = 'B';
                subfolders = bfile_name(1:slash_ixs(end));
                if ~exist(subfolders,'dir')
                    mkdir(subfolders)
                end
%                 if ~exist([BGC_Argo_data_folder bfile_name],'file') || redownload_updated_files
%                     [~,status] = urlread([remote_folder 'dac/' bfile_name]);
%                     if status
%                         urlwrite([remote_folder 'dac/' bfile_name],[BGC_Argo_data_folder bfile_name]);
%                         disp(bfile_name)
%                     else
%                         disp(['remote file not found: ' remote_folder 'dac/' bfile_name])
%                     end
                    
                    try 
                        urlwrite([remote_folder 'dac/' bfile_name],[BGC_Argo_data_folder bfile_name]);
%                         websave([BGC_Argo_data_folder bfile_name],[remote_folder 'dac/' bfile_name]);
                        disp(bfile_name)
                        download_status(ii) = true;
                    catch
                        disp(['remote file not found: ' remote_folder 'dac/' bfile_name ' or local folder does not exist'])
                        disp(['local folder: ' subfolders])
    %                     bfile_name(slash_ixs(end)+2) = 'R';
    %                     try 
    %                         urlwrite([remote_folder 'dac/' bfile_name],[BGC_Argo_data_folder bfile_name]);
    % %                         websave([BGC_Argo_data_folder bfile_name],[remote_folder 'dac/' bfile_name]);
    %                         disp(bfile_name)
    %                         download_status(ii) = true;
    %                     catch
    %                         disp(['remote file not found: ' remote_folder 'dac/' bfile_name ' or local folder does not exist'])
    %                         disp(['local folder: ' subfolders])
    %                     end
%                 end
                    end
%                 end
            end
%             download_status = true;
        end
%     end
else
    disp(['folder not found: ' download_home])
end