project_root = fileparts(fileparts(mfilename('fullpath')));
get_matrix_text = fileread(fullfile(project_root, 'Get_Matrix.m'));
get_matrix_statements = matlab_executable_statements(get_matrix_text);

assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^obs_idx\s*=\s*find\s*\(\s*time_P4\s*~=\s*0\s*\)\s*;?\s*$', ...
    'once')), get_matrix_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^obs_idx\s*=\s*obs_idx\s*\(\s*1\s*:\s*ObsStride\s*:\s*end\s*\)\s*;?\s*$', ...
    'once')), get_matrix_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^n\s*=\s*numel\s*\(\s*obs_idx\s*\)\s*;?\s*$', ...
    'once')), get_matrix_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^for\s+q\s*=\s*1\s*:\s*n\s*$', ...
    'once')), get_matrix_statements)));
assert(any(cellfun(@(s) ~isempty(regexp(s, ...
    '^k\s*=\s*time_window_start\s*\+\s*obs_idx\s*\(\s*q\s*\)\s*-\s*1\s*;?\s*$', ...
    'once')), get_matrix_statements)));

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
