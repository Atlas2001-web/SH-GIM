project_root = fileparts(fileparts(mfilename('fullpath')));
main_text = fileread(fullfile(project_root, 'main_unpackdata.m'));
get_ne_text = fileread(fullfile(project_root, 'GET_NE.m'));

main_statements = matlab_executable_statements(main_text);
get_ne_statements = matlab_executable_statements(get_ne_text);

assert(~isempty(regexp(main_text, ...
    '^sh_order\s*=\s*15\s*;', 'once', 'lineanchors')));
assert(isempty(regexp(main_text, ...
    'model_mode|res_ap_h|ap_h\s*=|bg_angle|bg_ap_h|res_angle', 'once')));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^GET_NE\s*\(\s*Start_Time\s*,\s*End_Time\s*,\s*TimeResolution\s*,\s*Site_Folder\s*,\s*P4_Folder\s*,\s*Sp3File_Output_Folder\s*,\s*GNSS_Choose\s*,\s*Code_Group\s*,\s*Add_FigNum\s*,\s*R\s*,\s*Height\s*,\s*sub_mat_Folder\s*,\s*currentPath\s*,\s*SH_Folder\s*,\s*sh_order\s*,\s*Cutoff_Ele\s*;?\s*\)$', ...
    'once')), main_statements)));

assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^function\s+GET_NE\s*\(\s*Start_Time\s*,\s*End_Time\s*,\s*TimeResolution\s*,\s*Site_Folder\s*,\s*P4_Folder\s*,\s*Sp3_Folder\s*,\s*GNSS_Choose\s*,\s*Code_Group\s*,\s*Add_FigNum\s*,\s*R\s*,\s*Height\s*,\s*sub_mat_Folder\s*,\s*currentPath\s*,\s*SH_Folder\s*,\s*sh_order\s*,\s*Cutoff_Ele\s*;?\s*\)$', ...
    'once')), get_ne_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^Get_SHBackground\s*\(\s*T\s*,', 'once')), get_ne_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^GET_I_SH\s*\(\s*T\s*,', 'once')), get_ne_statements)));
assert(all(cellfun(@(s) isempty(regexp(s, ...
    'Get_SRBF|GET_R|GET_I_Multiscale|GET_I_SH_AP_Hybrid|Build_APResidualP4|Build_SHResidualP4|Get_SRBF_ResidualOnly|GET_R_ResidualOnly|model_cfg|normalize_ap_model_cfg', ...
    'once')), get_ne_statements)));

assert(exist(fullfile(project_root, 'Get_SHBackground.m'), 'file') == 2);
assert(exist(fullfile(project_root, 'GET_I_SH.m'), 'file') == 2);
assert(exist(fullfile(project_root, 'Get_SRBF.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'GET_R.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'GET_I.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'GET_I_Multiscale.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'GET_I_SH_AP_Hybrid.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'Build_APResidualP4.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'Build_SHResidualP4.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'Get_SRBF_ResidualOnly.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'GET_R_ResidualOnly.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'Get_SH_SRBF.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'Get_SH_SRBF1.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'SH_Step6.m'), 'file') ~= 2);
assert(exist(fullfile(project_root, 'functions', 'Build_Time_Continuous_Constraints.m'), 'file') == 2);
assert(exist(fullfile(project_root, 'functions', 'Build_APOnly_Time_Constraints.m'), 'file') ~= 2);

function stripped_text = strip_matlab_comments(source_text)
lines = regexp(source_text, '\r\n|\r|\n', 'split');
in_block_comment = false;
for i = 1:numel(lines)
    line = lines{i};
    if in_block_comment
        if ~isempty(regexp(line, '^\s*%\}', 'once'))
            in_block_comment = false;
        end
        lines{i} = '';
        continue
    end

    if ~isempty(regexp(line, '^\s*%\{', 'once'))
        in_block_comment = true;
        lines{i} = '';
        continue
    end

    in_string = false;
    cut_idx = 0;
    j = 1;
    while j <= numel(line)
        ch = line(j);
        if ch == ''''
            if in_string && j < numel(line) && line(j + 1) == ''''
                j = j + 2;
                continue
            end
            in_string = ~in_string;
        elseif ch == '%' && ~in_string
            cut_idx = j;
            break
        end
        j = j + 1;
    end

    if cut_idx > 0
        if cut_idx == 1
            lines{i} = '';
        else
            lines{i} = line(1:cut_idx - 1);
            if isempty(strtrim(lines{i}))
                lines{i} = '';
            end
        end
    end
end

stripped_text = strjoin(lines, newline);
end

function statements = matlab_executable_statements(source_text)
lines = regexp(strip_matlab_comments(source_text), '\r\n|\r|\n', 'split');
statements = {};
buffer = '';
for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line)
        if ~isempty(buffer)
            statements{end + 1} = buffer; %#ok<AGROW>
            buffer = '';
        end
        continue
    end

    has_continuation = endsWith(line, '...');
    if has_continuation
        line = strtrim(regexprep(line, '\.\.\.\s*$', ''));
    end

    if isempty(buffer)
        buffer = line;
    else
        buffer = [buffer, ' ', line]; %#ok<AGROW>
    end

    if ~has_continuation
        statements{end + 1} = buffer; %#ok<AGROW>
        buffer = '';
    end
end

if ~isempty(buffer)
    statements{end + 1} = buffer; %#ok<AGROW>
end
end
