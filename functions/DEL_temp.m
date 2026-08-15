function DEL_temp(currentPath, T, ~)

if ~isfolder(currentPath)
    error('DEL_temp:InvalidRoot', 'currentPath does not exist: %s', currentPath);
end

current_tag = sprintf('%02d%03d', Get_yearLastTwo(T), day2doy(T));

remove_folder_if_exists(fullfile(currentPath, 'DATA', 'OUTPUT', 'Normal_Equation', current_tag));
remove_folder_if_exists(fullfile(currentPath, 'DATA', 'OUTPUT', 'OBS_OUT', current_tag));

input_obs_folder = fullfile(currentPath, 'DATA', 'INPUT', 'obs', ...
    sprintf('%04d', year(T)), sprintf('%03d', day2doy(T)));
remove_folder_if_exists(input_obs_folder);
prune_empty_parent(input_obs_folder, fullfile(currentPath, 'DATA', 'INPUT', 'obs'));
end

function remove_folder_if_exists(folder_path)
if exist(folder_path, 'dir')
    rmdir(folder_path, 's');
end
end

function prune_empty_parent(folder_path, stop_path)
parent_path = fileparts(folder_path);
while startsWith(parent_path, stop_path) && ~strcmp(parent_path, stop_path)
    if ~exist(parent_path, 'dir')
        parent_path = fileparts(parent_path);
        continue;
    end
    listing = dir(parent_path);
    listing = listing(~ismember({listing.name}, {'.', '..'}));
    if ~isempty(listing)
        return;
    end
    rmdir(parent_path);
    parent_path = fileparts(parent_path);
end
end
