%{
function export_results_to_tex(results, output_folder)
%EXPORT_RESULTS_TO_TEX Export transportation problem results and GA/SPMC logs to LaTeX
%
% Supports:
%   - Supply, Demand
%   - C_original, C_lfdp
%   - D_full (SPMC)
%   - W (DBAM IBFS)
%   - X (Optimal Solution)
%   - InitialCost, FinalCost
%   - u, v (dual variables)
%   - K (Opportunity Costs / Reduced Costs)
%   - ShippingList
%   - GA / Logs
%   - console_output
%
% output_folder: folder to write all .tex files

if ~exist(output_folder,'dir')
    mkdir(output_folder);
end

%% ------------------------
%% Helper function: save numeric/cell array as longtable with optional row/col labels
%% ------------------------
function save_table(name, data, row_labels, col_labels)
    if nargin<3, row_labels = {}; end
    if nargin<4, col_labels = {}; end

    tex_file = fullfile(output_folder, [name,'.tex']);
    fid = fopen(tex_file,'w');
    if fid==-1
        warning('Cannot open file %s', tex_file);
        return;
    end

    ncols = max(1,size(data,2));
    if ~isempty(row_labels), ncols = ncols + 1; end
    fprintf(fid, '\\begin{longtable}{%s}\n', repmat('c',1,ncols));

    % Column labels
    if ~isempty(col_labels)
        if ~isempty(row_labels), fprintf(fid,' & '); end
        for j = 1:length(col_labels)-1
            fprintf(fid, '%s & ', escape_latex(col_labels{j}));
        end
        fprintf(fid, '%s \\\\\n\\hline\n', escape_latex(col_labels{end}));
    end

    % Table rows
    for i = 1:size(data,1)
        if ~isempty(row_labels), fprintf(fid, '%s & ', escape_latex(row_labels{i})); end
        for j = 1:size(data,2)
            val = data(i,j);
            if isnumeric(val), fprintf(fid,'%g', val);
            elseif iscell(val)
                val2 = val{1};
                if isnumeric(val2), fprintf(fid,'%g', val2); else fprintf(fid,'%s', escape_latex(val2)); end
            else
                fprintf(fid,'%s', escape_latex(val));
            end
            if j < size(data,2), fprintf(fid,' & '); end
        end
        fprintf(fid,' \\\\\n');
    end

    fprintf(fid,'\\end{longtable}\n');
    fclose(fid);
end

%% ------------------------
%% Helper: escape LaTeX special characters
%% ------------------------
function str = escape_latex(str)
    if isnumeric(str), str = num2str(str); return; end
    if iscell(str), str = str{1}; end
    specials = {'\', '_', '&', '%', '$', '#', '{', '}', '~', '^'};
    replacements = {'\\textbackslash{}','\_','\&','\%','\$','\#','\{','\}','\textasciitilde{}','\textasciicircum{}'};
    for k = 1:length(specials), str = strrep(str, specials{k}, replacements{k}); end
end

%% ------------------------
%% 1. Input Data
%% ------------------------
if isfield(results,'supply')
    save_table('Supply', results.supply, ...
        arrayfun(@(i)sprintf('S%d',i),1:length(results.supply),'UniformOutput',false));
end
if isfield(results,'demand')
    save_table('Demand', results.demand, ...
        arrayfun(@(i)sprintf('D%d',i),1:length(results.demand),'UniformOutput',false));
end

if isfield(results,'C_original')
    save_table('Cost_Original', results.C_original, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.C_original,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.C_original,2),'UniformOutput',false));
end

if isfield(results,'C_lfdp')
    save_table('SPMC_Adjusted_Cost', results.C_lfdp, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.C_lfdp,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.C_lfdp,2),'UniformOutput',false));
end

%% ------------------------
%% 2. SPMC / Intermediate Matrices
%% ------------------------
if isfield(results,'D_full')
    if isnumeric(results.D_full) && ndims(results.D_full)==3
        for k = 1:size(results.D_full,3)
            save_table(sprintf('SPMC_Matrix_%d', k), results.D_full(:,:,k));
        end
    else
        save_table('SPMC_Matrix', results.D_full);
    end
end

%% ------------------------
%% 3. Initial Basic Feasible Solution (DBAM)
%% ------------------------
if isfield(results,'W')
    save_table('DBAM_IBFS', results.W, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.W,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.W,2),'UniformOutput',false));
end

%% ------------------------
%% 4. Initial Cost (auto-compute if missing)
%% ------------------------
if ~isfield(results,'InitialCost') && isfield(results,'W') && isfield(results,'C_original')
    results.InitialCost = sum(sum(results.W .* results.C_original));
end
if isfield(results,'InitialCost')
    fid = fopen(fullfile(output_folder,'Initial_Total_Transportation_Cost.tex'),'w');
    fprintf(fid,'%g\n', results.InitialCost);
    fclose(fid);
end

%% ------------------------
%% 5. Optimal Solution & Cost
%% ------------------------
if isfield(results,'X')
    save_table('Optimal_Shipping_Table', results.X, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.X,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.X,2),'UniformOutput',false));
end
if isfield(results,'FinalCost')
    fid = fopen(fullfile(output_folder,'Final_Total_Transportation_Cost.tex'),'w');
    fprintf(fid,'%g\n', results.FinalCost);
    fclose(fid);
end

%% ------------------------
%% 6. Dual Variables
%% ------------------------
if isfield(results,'u')
    save_table('Dual_u', results.u, arrayfun(@(i)sprintf('u%d',i),1:length(results.u),'UniformOutput',false));
end
if isfield(results,'v')
    save_table('Dual_v', results.v, arrayfun(@(i)sprintf('v%d',i),1:length(results.v),'UniformOutput',false));
end

%% ------------------------
%% 7. Reduced Costs / Opportunity Costs
%% ------------------------
if isfield(results,'K')
    save_table('Opportunity_Costs', results.K, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.K,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.K,2),'UniformOutput',false));
end

%% ------------------------
%% 8. Shipping List
%% ------------------------
if isfield(results,'ShippingList')
    save_table('Shipping_List', results.ShippingList, {}, {'Source','Destination','Quantity'});
elseif isfield(results,'X')
    [rows, cols] = find(results.X>0);
    quantities = results.X(results.X>0);
    ShippingList = [rows, cols, quantities];
    save_table('Shipping_List', ShippingList, {}, {'Source','Destination','Quantity'});
end

%% ------------------------
%% 9. GA Optimization Results
%% ------------------------
ga_fields = {'population','best_fitness_log','mean_fitness_log','diversity_log','mutation_rate_log','decoded','mode_matrix','OC'};
for f = 1:length(ga_fields)
    if isfield(results,ga_fields{f})
        save_table(['GA_' ga_fields{f}], results.(ga_fields{f}));
    end
end

%% ------------------------
%% 10. Console Outputs
%% ------------------------
if isfield(results,'console_output')
    for i = 1:length(results.console_output)
        txt_file = fullfile(output_folder, sprintf('Console_Output_%d.tex', i));
        fid = fopen(txt_file,'w');
        if fid==-1, warning('Cannot open file %s', txt_file); continue; end
        txt = strrep(results.console_output{i}, '\', '\\');
        fprintf(fid,'\\begin{verbatim}\n%s\n\\end{verbatim}\n', txt);
        fclose(fid);
    end
end

fprintf('*** All results exported successfully to %s ***\n', output_folder);

end
%}
function export_results_to_tex(results, output_folder)
%EXPORT_RESULTS_TO_TEX Export transportation problem results to LaTeX
%
% Supports:
%   - Supply, Demand
%   - C_original, C_ldp
%   - D_init (Initial distance matrix before SPMC)
%   - D_full (Final SPMC matrix after processing)
%   - X (Optimal Solution)
%   - InitialCost, FinalCost
%   - u, v (dual variables)
%   - K (Opportunity Costs / Reduced Costs)
%   - ShippingList
%   - console_output
%
% output_folder: folder to write all .tex files

if ~exist(output_folder,'dir')
    mkdir(output_folder);
end

%% ------------------------
%% Helper function: save numeric/cell array as longtable with optional row/col labels
%% ------------------------
function save_table(name, data, row_labels, col_labels)
    if nargin<3, row_labels = {}; end
    if nargin<4, col_labels = {}; end

    tex_file = fullfile(output_folder, [name,'.tex']);
    fid = fopen(tex_file,'w');
    if fid==-1
        warning('Cannot open file %s', tex_file);
        return;
    end

    ncols = max(1,size(data,2));
    if ~isempty(row_labels), ncols = ncols + 1; end
    fprintf(fid, '\\begin{longtable}{%s}\n', repmat('c',1,ncols));
    
    % Add caption
    caption_text = strrep(name, '_', ' ');
    fprintf(fid, '\\caption{%s}\\\\\n', caption_text);

    % Column labels
    if ~isempty(col_labels)
        if ~isempty(row_labels), fprintf(fid,' & '); end
        for j = 1:length(col_labels)-1
            fprintf(fid, '%s & ', escape_latex(col_labels{j}));
        end
        fprintf(fid, '%s \\\\\n\\hline\n', escape_latex(col_labels{end}));
    end

    % Table rows
    for i = 1:size(data,1)
        if ~isempty(row_labels), fprintf(fid, '%s & ', escape_latex(row_labels{i})); end
        for j = 1:size(data,2)
            val = data(i,j);
            if isnumeric(val)
                if isinf(val)
                    fprintf(fid, '$\\infty$');
                elseif val == 0
                    fprintf(fid, '0');
                else
                    fprintf(fid, '%g', val);
                end
            elseif iscell(val)
                val2 = val{1};
                if isnumeric(val2)
                    if isinf(val2)
                        fprintf(fid, '$\\infty$');
                    elseif val2 == 0
                        fprintf(fid, '0');
                    else
                        fprintf(fid, '%g', val2);
                    end
                else
                    fprintf(fid, '%s', escape_latex(val2));
                end
            else
                fprintf(fid, '%s', escape_latex(val));
            end
            if j < size(data,2), fprintf(fid,' & '); end
        end
        fprintf(fid,' \\\\\n');
    end

    fprintf(fid,'\\end{longtable}\n');
    fclose(fid);
end

%% ------------------------
%% Helper: escape LaTeX special characters
%% ------------------------
function str = escape_latex(str)
    if isnumeric(str), str = num2str(str); return; end
    if iscell(str), str = str{1}; end
    if ~ischar(str), str = num2str(str); end
    specials = {'\', '_', '&', '%', '$', '#', '{', '}', '~', '^'};
    replacements = {'\\textbackslash{}','\_','\&','\%','\$','\#','\{','\}','\textasciitilde{}','\textasciicircum{}'};
    for k = 1:length(specials), str = strrep(str, specials{k}, replacements{k}); end
end

%% ------------------------
%% 1. SPMC Matrices
%% ------------------------
%% ------------------------
%% 1. SPMC Matrices with Source/Destination Labels
%% ------------------------
if isfield(results, 'D_init')
    n_nodes = size(results.D_init, 1);
    
    % Create labels: S1, S2, ..., Sm, D1, D2, ..., Dn
    % You need to know how many sources (s) and destinations (d) there are
    if isfield(results, 's') && isfield(results, 'd')
        s = results.s;
        d = results.d;
        node_labels = cell(1, n_nodes);
        for i = 1:s
            node_labels{i} = sprintf('S%d', i);
        end
        for j = 1:d
            node_labels{s + j} = sprintf('D%d', j);
        end
    else
        % Fallback to generic N labels if s,d not provided
        node_labels = arrayfun(@(i) sprintf('N_{%d}', i), 1:n_nodes, 'UniformOutput', false);
    end
    
    % Export initial distance matrix
    save_table('Initial_Distance_Matrix', results.D_init, node_labels, node_labels);
    fprintf('   Exported: Initial_Distance_Matrix.tex\n');
end

if isfield(results, 'D_full')
    n_nodes = size(results.D_full, 1);
    
    % Create labels: S1, S2, ..., Sm, D1, D2, ..., Dn
    if isfield(results, 's') && isfield(results, 'd')
        s = results.s;
        d = results.d;
        node_labels = cell(1, n_nodes);
        for i = 1:s
            node_labels{i} = sprintf('S%d', i);
        end
        for j = 1:d
            node_labels{s + j} = sprintf('D%d', j);
        end
    else
        % Fallback to generic N labels if s,d not provided
        node_labels = arrayfun(@(i) sprintf('N_{%d}', i), 1:n_nodes, 'UniformOutput', false);
    end
    
    % Export final SPMC matrix
    save_table('Final_SPMC_Matrix', results.D_full, node_labels, node_labels);
    fprintf('   Exported: Final_SPMC_Matrix.tex\n');
end

%% ------------------------
%% 2. Supply and Demand
%% ------------------------
if isfield(results,'supply')
    save_table('Supply', results.supply, ...
        arrayfun(@(i)sprintf('S%d',i),1:length(results.supply),'UniformOutput',false));
end

if isfield(results,'demand')
    save_table('Demand', results.demand, ...
        arrayfun(@(i)sprintf('D%d',i),1:length(results.demand),'UniformOutput',false));
end

%% ------------------------
%% 3. Cost Matrices
%% ------------------------
if isfield(results,'C_original')
    save_table('Cost_Original', results.C_original, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.C_original,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.C_original,2),'UniformOutput',false));
end

if isfield(results,'C_ldp')
    save_table('SPMC_Adjusted_Cost', results.C_ldp, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.C_ldp,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.C_ldp,2),'UniformOutput',false));
end

%% ------------------------
%% 4. Objective Coefficient Matrix
%% ------------------------
if isfield(results,'OC')
    save_table('Objective_Coefficient_Matrix', results.OC, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.OC,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.OC,2),'UniformOutput',false));
end

%% ------------------------
%% 5. Initial Basic Feasible Solution (ADBAM)
%% ------------------------
if isfield(results,'W')
    save_table('ADBAM_IBFS', results.W, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.W,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.W,2),'UniformOutput',false));
end

%% ------------------------
%% 6. Initial Cost
%% ------------------------
if ~isfield(results,'InitialCost') && isfield(results,'W') && isfield(results,'C_original')
    results.InitialCost = sum(sum(results.W .* results.C_original));
end
if isfield(results,'InitialCost')
    fid = fopen(fullfile(output_folder,'Initial_Total_Transportation_Cost.tex'),'w');
    fprintf(fid,'%g\n', results.InitialCost);
    fclose(fid);
end

%% ------------------------
%% 7. Optimal Solution
%% ------------------------

%% ------------------------
%% 8. Final Cost
%% ------------------------
if isfield(results,'FinalCost')
    fid = fopen(fullfile(output_folder,'Final_Total_Transportation_Cost.tex'),'w');
    fprintf(fid,'%g\n', results.FinalCost);
    fclose(fid);
end

%% ------------------------
%% 9. Dual Variables
%% ------------------------
if isfield(results,'u')
    save_table('Dual_u', results.u, arrayfun(@(i)sprintf('u%d',i),1:length(results.u),'UniformOutput',false));
end

if isfield(results,'v')
    save_table('Dual_v', results.v, arrayfun(@(i)sprintf('v%d',i),1:length(results.v),'UniformOutput',false));
end

%% ------------------------
%% 10. Opportunity Costs
%% ------------------------
if isfield(results,'K')
    save_table('Opportunity_Costs', results.K, ...
        arrayfun(@(i)sprintf('S%d',i),1:size(results.K,1),'UniformOutput',false), ...
        arrayfun(@(j)sprintf('D%d',j),1:size(results.K,2),'UniformOutput',false));
end

%% ------------------------
%% 11. Shipping List
%% ------------------------
%{
if isfield(results,'ShippingList')
    save_table('Shipping_List', results.ShippingList, {}, {'Source','Destination','Quantity'});
elseif isfield(results,'X')
    [rows, cols] = find(results.X>0);
    quantities = results.X(results.X>0);
    ShippingList = [rows, cols, quantities];
    save_table('Shipping_List', ShippingList, {}, {'Source','Destination','Quantity'});
end
%}
%% ------------------------
%% 12. Console Outputs
%% ------------------------
if isfield(results,'console_output')
    for i = 1:length(results.console_output)
        txt_file = fullfile(output_folder, sprintf('Console_Output_%d.tex', i));
        fid = fopen(txt_file,'w');
        if fid==-1, warning('Cannot open file %s', txt_file); continue; end
        txt = strrep(results.console_output{i}, '\', '\\');
        fprintf(fid,'\\begin{verbatim}\n%s\n\\end{verbatim}\n', txt);
        fclose(fid);
    end
end

%% ------------------------
%% MODI Iterations
%% ------------------------
if isfield(results, 'MODI_iterations')
    fid = fopen(fullfile(output_folder, 'MODI_Iterations.tex'), 'w');
    if fid ~= -1
        fprintf(fid, '\\begin{longtable}{lc}\n');
        fprintf(fid, '\\caption{MODI Algorithm Performance}\\\\\n');
        fprintf(fid, '\\hline\n');
        fprintf(fid, 'Metric & Value \\\\ \\hline\n');
        fprintf(fid, 'Number of Iterations & %d \\\\\n', results.MODI_iterations);
        fprintf(fid, '\\hline\n');
        fprintf(fid, '\\end{longtable}\n');
        fclose(fid);
        fprintf('   Exported: MODI_Iterations.tex\n');
    end
end
fprintf('*** All results exported successfully to %s ***\n', output_folder);

end