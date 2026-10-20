function Two_Phase_Pipeline()
mkdir('TEX_OUTPUT');
  clear vars; clear all; clc; tic;
    format long g
  run('dims.m');   % loads s, d, m
  % Ask if user wants to generate synthetic data or enter manually
choice = questdlg('How would you like to provide Supply and Demand data?', ...
    'Data Entry Mode', ...
    'Enter Manually', 'Use Synthetic Data', 'Enter Manually');
if isempty(choice), return; end
% If user chooses synthetic input
if strcmp(choice, 'Use Synthetic Data')
    % Ask for synthetic settings
    prompt = { ...
        'Total Supply:', ...
        'Supply Lower Bound:', ...
        'Supply Upper Bound:', ...
        'Total Demand:', ...
        'Demand Lower Bound:', ...
        'Demand Upper Bound:'};
    dlgtitle = 'Synthetic Data Settings';
    dims = [1 50];
    definput = {'500', '20', '100', '500', '20', '100'};
    response = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(response), return; end
    total_supply = str2double(response{1});
    supply_lb = str2double(response{2});
    supply_ub = str2double(response{3});
    total_demand = str2double(response{4});
    demand_lb = str2double(response{5});
    demand_ub = str2double(response{6});

    % Generate synthetic supply
    raw = randi([supply_lb, supply_ub], 1, s);
    supply = round(raw / sum(raw) * total_supply);
    supply(end) = total_supply - sum(supply(1:end-1));

    % Generate synthetic demand
    raw = randi([demand_lb, demand_ub], 1, d);
    demand = round(raw / sum(raw) * total_demand);
    demand(end) = total_demand - sum(demand(1:end-1));
  run('bal.m');

  fprintf('\nEnter the transportation cost tableau\n');
    cost_table = cell(s+1, d+1);
    for i = 1:s
        for j = 1:d
            cost_table{i,j} = '0';
        end
        cost_table{i,end} = num2str(supply(i));
    end
    for j = 1:d
        cost_table{end,j} = num2str(demand(j));
    end
    cost_table{end,end} = '';
% === Compute total size of table and controls ===
% === Compute dynamic figure size ===
max_table_view_width = 850;
max_table_view_height = 350;
table_width = 75 * d + 100;
table_height = 25 * s + 100;
fig_width = max(900, max_table_view_width + 60);
fig_height = max(650, max_table_view_height + 230);  % Enough for controls + margin
f = figure('Name', sprintf('Enter Transportation Costs'), ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Resize', 'off', ...
    'Position', [100, 100, fig_width, fig_height]);
% === Create Scrollable Panel for Table ===
panel = uipanel(f, ...
    'Units', 'pixels', ...
    'Position', [25, 230, max_table_view_width, max_table_view_height]);
% Create the uitable (hidden initially)
t = uitable('Data', cost_table, ...
    'ColumnEditable', true, ...
    'ColumnName', [arrayfun(@(j) sprintf('D%d', j), 1:d, 'UniformOutput', false), {'Supply'}], ...
    'RowName', [arrayfun(@(i) sprintf('S%d', i), 1:s, 'UniformOutput', false), {'Demand'}], ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'Parent', panel);
drawnow;  % Ensure UI components are rendered

% Ensure components are rendered
jScrollPane = findjobj(t);  % Requires findjobj.m
if isempty(jScrollPane)
    warning('Unable to attach scrollpane. Ensure findjobj.m is available.');
else
    import javax.swing.ScrollPaneConstants;
    jScrollPane.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_ALWAYS);
    jScrollPane.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
end

% === Bottom Controls Layout ===
label_names = {'Lower Bound:', 'Upper Bound:', 'Prohibited %:'};
default_vals = {'5', '50', '20'};
n_fields = numel(label_names);

row_height = 25;
col_width = 100;
edit_width = 60;
col_gap = 20;
input_gap = 10;
start_y = 110;
start_x = 30;

for i = 1:n_fields
    col = i - 1;
    label_x = start_x + col * (col_width + edit_width + col_gap);
    uicontrol(f, 'Style', 'text', 'String', label_names{i}, ...
        'Position', [label_x, start_y + row_height + input_gap, col_width, row_height], ...
        'HorizontalAlignment', 'right');

    switch i
        case 1
            lowerBox = uicontrol(f, 'Style', 'edit', 'String', default_vals{i}, ...
                'Position', [label_x + col_width, start_y + row_height + input_gap, edit_width, row_height]);
        case 2
            upperBox = uicontrol(f, 'Style', 'edit', 'String', default_vals{i}, ...
                'Position', [label_x + col_width, start_y + row_height + input_gap, edit_width, row_height]);
        case 3
            prohibitBox = uicontrol(f, 'Style', 'edit', 'String', default_vals{i}, ...
                'Position', [label_x + col_width, start_y + row_height + input_gap, edit_width, row_height]);
    end
end
% Buttons under input fields
button_width = 160;
button_height = 25;
button_gap = 20;
total_button_width = 3 * button_width + 2 * button_gap;
start_btn_x = (fig_width - total_button_width)/2;
button_y = 70;

uicontrol(f, 'Style', 'pushbutton', 'String', 'Fill (No Prohibited)', ...
    'Position', [start_btn_x, button_y, button_width, button_height], ...
    'Callback', @(src, event) fillSynthetic(t, lowerBox, upperBox, false, prohibitBox, dummy_source, dummy_dest));

uicontrol(f, 'Style', 'pushbutton', 'String', 'Fill (With Prohibited)', ...
    'Position', [start_btn_x + button_width + button_gap, button_y, button_width, button_height], ...
    'Callback', @(src, event) fillSynthetic(t, lowerBox, upperBox, true, prohibitBox, dummy_source, dummy_dest));

% Submit button
uicontrol(f, 'Style', 'pushbutton', 'String', 'Submit', ...
    'Position', [20, 10, 80, 25], ...
    'Callback', 'uiresume(gcbf);');

% Wait and capture data
uiwait(f);
data = get(t, 'Data');
close(f);
    % Parse user-filled table into numeric cost matrix
    C = zeros(s, d);
    for i = 1:s
        for j = 1:d
            val = str2double(data{i,j});
            if isnan(val), val = Inf; end
            C(i,j) = val;
        end
    end
   fprintf('\nOriginal Cost Matrix:\n');
[s, d] = size(C);  % Get size of cost matrix

% Create row and column labels
row_labels = arrayfun(@(i) sprintf('S%d', i), 1:s, 'UniformOutput', false);
col_labels = arrayfun(@(j) sprintf('D%d', j), 1:d, 'UniformOutput', false);

% Print header
fprintf('\t');
fprintf('%8s', col_labels{:});
fprintf('\n');
% Print cost matrix with row labels
for i = 1:s
    fprintf('%s\t', row_labels{i});
    fprintf('%8.2f', C(i, :));
    fprintf('\n');
end

C_original = C;
else
run('cost.m');
run('ISD.m');
total_supply = sum(supply);
total_demand = sum(demand);
dummy_source = false;
dummy_dest = false;

fprintf('\n=== Balancing Supply and Demand ===\n');
fprintf('Total Supply: %.2f\n', total_supply);
fprintf('Total Demand: %.2f\n', total_demand);
fprintf('Original C size: %d x %d\n', s, d);

if total_supply > total_demand
    % Add dummy destination
    d = d + 1;
    demand(end+1) = total_supply - total_demand;
    dummy_dest = true;
    fprintf('\nAdded dummy destination D%d with demand = %.2f.\n', d, demand(end));
    
    % ============================================
    % ADD DUMMY COLUMN TO COST MATRIX (zeros)
    % ============================================
    [rows, cols] = size(C);
    C = [C, zeros(rows, 1)];
    fprintf('Added dummy column to cost matrix (now %d x %d)\n', s, d);
    % ============================================
    
elseif total_demand > total_supply
    % Add dummy source
    s = s + 1;
    supply(end+1) = total_demand - total_supply;
    dummy_source = true;
    fprintf('\nAdded dummy source S%d with supply = %.2f.\n', s, supply(end));
    
    % ============================================
    % ADD DUMMY ROW TO COST MATRIX (zeros)
    % ============================================
    [rows, cols] = size(C);
    C = [C; zeros(1, cols)];
    fprintf('Added dummy row to cost matrix (now %d x %d)\n', s, d);
    % ============================================
    
else
    fprintf('Supply and demand are already balanced.\n');
end

fprintf('\n=== Final Dimensions After Balancing ===\n');
fprintf('Supply vector size: %d\n', length(supply));
fprintf('Demand vector size: %d\n', length(demand));
fprintf('Final C size: %d x %d\n', s, d);
fprintf('Dummy source: %d, Dummy destination: %d\n', dummy_source, dummy_dest);
fprintf('=========================================\n');

 C_original = C;% Load costs from file
end

C = C_original;
        n_nodes = s + d;
        D = inf(n_nodes);
        for i = 1:s
            for j = 1:d
                val = C(i,j);
                if isinf(val)
                    D(i, s+j) = inf;
                    D(s+j, i) = inf;
                else
                    D(i, s+j) = val;
                   D(s+j, i) = val;
                end
            end
        end
        for k = 1:n_nodes
            D(k,k) = 0;%% you can also set it to inf
        end
        D_init = D;  % ← THIS LINE IS MISSING!

% Call SPMC with the correct flag
D_full = SPMC(D);

%      D_full = SPMC(D);
LDC_Matrix = D_full(1:s, s+1:end);
C_ldp = LDC_Matrix ;

fprintf('\nLDC Matrix:\n');
% Create row and column labels
[s_penalty, d_penalty] = size(LDC_Matrix );
row_labels = arrayfun(@(i) sprintf('S%d', i), 1:s_penalty, 'UniformOutput', false);
col_labels = arrayfun(@(j) sprintf('D%d', j), 1:d_penalty, 'UniformOutput', false);

% Print header
fprintf('\t');
fprintf('%8s', col_labels{:});
fprintf('\n');

% Print matrix with row labels
for i = 1:s_penalty
    fprintf('%s\t', row_labels{i});
    fprintf('%8.2f', LDC_Matrix (i, :));
    fprintf('\n');
end

    fprintf('\nFinal Supply Vector:\n'); disp(supply);
    fprintf('Final Demand Vector:\n'); disp(demand);

   
        OC = C_original;
        ldp = C_ldp;
        mask = isinf(OC);
        OC(mask) = ldp(mask);
        % Optional: Display the matrix
    fprintf('\nFinal Objective Coefficient Matrix:\n');
    disp(OC);
        % Solve the transportation problem using ADBAM + MODI
        fprintf('\n=== Solving Transportation Problem ===\n');
        ADBAMMODI(OC, supply', demand);
    % ADD THESE LINES TO CAPTURE THE ITERATIONS
% The iterations are stored in base workspace by uvmethod_transportation
MODI_iterations = evalin('base', 'MODI_iterations_value');

fprintf('\n*** MODI completed in %d iterations ***\n', MODI_iterations);
  
%% ================================================
%  BUILD RESULTS STRUCT FOR EXPORT
%  ================================================

results = struct();

% -----------------------
% 0. Dimensions (ADD THESE)
% -----------------------
results.s = s;  % Number of sources
results.d = d;  % Number of destinations
results.n_nodes = s + d;  % Total nodes
% -----------------------
% 1. Input data
% -----------------------
results.supply = supply;
results.demand = demand;
results.C_original = C_original;   % cost matrices per
results.C_ldp = C_ldp;           % SPMC-adjusted cost matrices

% -----------------------
% 2. Intermediate results
% -----------------------
if exist('D_init','var')
    results.D_init = D_init;       % SPMC matrices
end
if exist('D_full','var')
    results.D_full = D_full;       % SPMC matrices
end

if exist('OC','var')
    results.OC = OC;
end

% -----------------------
% 3. MODI Iterations (ADD THIS SECTION)
% -----------------------
if exist('MODI_iterations', 'var')
    results.MODI_iterations = MODI_iterations;
end
% ------------------------
% 7. EXPORT TO .TEX FILES
% ------------------------
export_results_to_tex(results,fullfile(pwd, 'TEX_OUTPUT'));
fprintf('\nAll .tex longtable files exported successfully.\n');
end

function D = SPMC(D_init)
% SPMC computes the Least Detour Detour Costs (LDC) matrix
D = D_init;
n = size(D, 1);


fprintf('Initial Matrix:\n');
disp(D);

for i = 1:n
    for j = 1:n
        if i == j, continue; end  % skip diagonal
        current = D(i,j);
        min_val = current;
  %%%YOU CAN REMOVE THE COMMENTS BELOW TO SHOW WORKING
     %   fprintf('\nEvaluating D(%d,%d):\n', i, j);

        % --- Check all intermediate nodes k ---
        for k = 1:n
            if k ~= i && k ~= j
                val = D(i,k) + D(k,j);  % max-plus sum

                %%%YOU CAN REMOVE THE COMMENTS BELOW TO SHOW WORKING
            %    fprintf('  Path: D(%d,%d) via %d = D(%d,%d)+D(%d,%d) = %.2f + %.2f = %.2f\n', ...
             %           i,j,k,i,k,k,j,D(i,k),D(k,j),val);
                if val < min_val
                    min_val = val;
                end
            end
        end

        % --- Update D(i,j) if a larger detour found ---
        if min_val < current

              %%%YOU CAN REMOVE THE COMMENT BELOW TO SHOW WORKING
         %   fprintf('  Updating D(%d,%d) from %.2f to %.2f\n', i,j,current,max_val);
            D(i,j) = min_val;
             D(j,i) = min_val;
        end
    end

      %%%YOU CAN REMOVE THE COMMENT BELOW TO SHOW WORKING
   % fprintf('\nMatrix after processing row %d:\n', i);
   % disp(D);
end

fprintf('Final Least Detour Detour Cost Matrix:\n');
disp(D);
end

%%%%
function results=ADBAMMODI(A, B, C)
    % Modified ADBAM + MODI solver that accepts inputs directly
    % A = cost matrix (m x n)
    % B = supplies (column vector, m x 1)
    % C = demands (row vector, 1 x n)
    
    % Full Solver: ADBAM for IBFS + MODI (UV) Method for Optimality
   
    fprintf("=== Demand-Based Allocation + MODI Method (with Complex Loops) ===\n");

    % Check balance
    if sum(B) ~= sum(C)
        error('Unbalanced problem. Please balance supply and demand.');
    end
 R = A;                  % Preserve original cost matrix
    [m, n] = size(A);
   X = ADBAM(A, B, C);

 % Step 3: Degeneracy Check
required = m + n - 1;
epsilon = max(1e-10, min(1e-5, min(C(:))/1e5));

if nnz(X(:) > 0) < required
    added = 0;
    for i = 1:m
        for j = 1:n
            if X(i,j) == 0
                % Temporarily insert epsilon
                tempX = X;
                tempX(i,j) = epsilon;
                % Check for closed loop
                loop = find_loop_general([i, j], tempX > 0, [], true);

                % If no loop, it's a safe epsilon insertion
                if isempty(loop)
                    X(i,j) = epsilon;
                    added = added + 1;
                end
                % Stop when we have enough basic variables
                if nnz(X(:) > 0) >= required
                    break;
                end
            end
        end
        if nnz(X(:) > 0) >= required
            break;
        end
    end
end

% Step 3: MODI Optimization
fprintf('\n=== Initial Basic Feasible Solution (ADBAM) ===\n');

[s, d] = size(X);  % Get dimensions

% Create row and column labels
row_labels = arrayfun(@(i) sprintf('S%d', i), 1:s, 'UniformOutput', false);
col_labels = arrayfun(@(j) sprintf('D%d', j), 1:d, 'UniformOutput', false);

% Print header row
fprintf('\t');
fprintf('%8s', col_labels{:});
fprintf('\n');

% Print X matrix with source labels
for i = 1:s
    fprintf('%s\t', row_labels{i});
    fprintf('%8.2f', X(i, :));
    fprintf('\n');
end
% ================================
% EXPORT ADBAM IBFS TO LaTeX
% ================================

tex_folder = fullfile(pwd,'TEX_OUTPUT');
if ~exist(tex_folder,'dir')
    mkdir(tex_folder);
end

tex_file = fullfile(tex_folder,'ADBAM_Initial_IBFS.tex');
fid = fopen(tex_file,'w');

if fid ~= -1

    % Number of columns for LaTeX
    fprintf(fid,'\\begin{longtable}{l%s}\n', repmat('c',1,d));
    fprintf(fid,'\\caption{Initial Basic Feasible Solution (ADBAM)}\\\\\n');
    fprintf(fid,'\\hline\n');

    % Column headers
    fprintf(fid,'Source/Dest ');
    for j = 1:d
        fprintf(fid,' & %s', col_labels{j});
    end
    fprintf(fid,'\\\\ \\hline\n');

    % Table body
    for i = 1:s
        fprintf(fid,'%s', row_labels{i});
        for j = 1:d
            fprintf(fid,' & %.2f', X(i,j));
        end
        fprintf(fid,'\\\\\n');
    end

    fprintf(fid,'\\hline\n\\end{longtable}\n');
    fclose(fid);

    fprintf('\nLaTeX table exported: %s\n', tex_file);
else
    warning('Could not create LaTeX file for ADBAM IBFS.');
end

% Print initial cost
fprintf('\nInitial Cost = %.2f\n', sum(sum(X .* R)));

% Continue with UV optimization
uvmethod_transportation(X,R);
fprintf('--- Done. Total time: %.4f seconds ---\n', toc);
end
%%%

function uvmethod_transportation(X, C)

    [m, n] = size(C);
    iteration = 0;
     epsilon = max(1e-10, min(1e-5, min(C(:))/1e5));
    max_iterations = 100;

    while iteration < max_iterations
        iteration = iteration + 1;
        fprintf('Iteration %d:\n', iteration);
 % Step 3: Degeneracy Check
required = m + n - 1;
epsilon = max(1e-10, min(1e-5, min(C(:))/1e5));

if nnz(X(:) > 0) < required
    added = 0;
    for i = 1:m
        for j = 1:n
            if X(i,j) == 0
                % Temporarily insert epsilon
                tempX = X;
                tempX(i,j) = epsilon;
                % Check for closed loop
                loop = find_loop_general([i, j], tempX > 0, [], true);

                % If no loop, it's a safe epsilon insertion
                if isempty(loop)
                    X(i,j) = epsilon;
                    added = added + 1;
                end
                % Stop when we have enough basic variables
                if nnz(X(:) > 0) >= required
                    break;
                end
            end
        end
        if nnz(X(:) > 0) >= required
            break;
        end
    end
end

        % Calculate dual variables
        [u, v] = calculate_dual_variables(X, C, m, n, epsilon);

        % Calculate opportunity costs
        [K, minK, row, col] = calculate_opportunity_costs(X, C, u, v, epsilon);
        fprintf('Min opportunity cost: %.4f at (%d,%d)\n', minK, row, col);
        % Optimality check
        if minK >= -epsilon
            fprintf('Optimal solution found!\n');
            break;
        end
        % Adjust using stepping stone path
       marked = (X >= epsilon - 1e-12);
        X = adjust_along_loop(X, row, col, marked);
    end
  % ADD THESE 3 LINES TO STORE ITERATIONS IN THE FUNCTION
    assignin('base', 'MODI_iterations_value', iteration);
    print_optimal_solution(X, C, u, v);
    print_shipping_list(X,C);
end

function [u, v] = calculate_dual_variables(X, C, m, n, epsilon)
    u = nan(1, m);
    v = nan(1, n);
    u(1) = 0; % Fix one variable to avoid infinite solutions
    basic_cells = (X > epsilon);
    % Iterate until all variables are found
    updated = true;
    while updated
        updated = false;

        for i = 1:m
            for j = 1:n
                if basic_cells(i,j)
                    if ~isnan(u(i)) && isnan(v(j))
                        v(j) = C(i,j) - u(i); updated = true;
                    elseif isnan(u(i)) && ~isnan(v(j))
                        u(i) = C(i,j) - v(j); updated = true;
                    end
                end
            end
        end
    end
end

function [K, minK, row, col] = calculate_opportunity_costs(X, C, u, v, epsilon)
    [m, n] = size(C);
    K = inf(m, n);

    non_basic = (X <= epsilon);
    u_col = u(:);
    v_row = v(:)';
    for i = 1:m
        for j = 1:n
            if non_basic(i,j)
                K(i,j) = C(i,j) - (u_col(i) + v_row(j));
            end
        end
    end

    [minK, idx] = min(K(:));
    [row, col] = ind2sub([m, n], idx);
end

function X = adjust_along_loop(X, start_row, start_col, marked)
    [m, n] = size(X);
    marked(start_row, start_col) = true;
    loop = find_loop_general([start_row, start_col], marked, [], true);
    marked(start_row, start_col) = false;

    if isempty(loop), error('No closed loop found.'); end
    % Remove closing duplicate so the first cell is not updated twice
    if isequal(loop{1}, loop{end})
        loop(end) = [];
    end
    signs = repmat([1 -1], 1, ceil(length(loop)/2));
    signs = signs(1:length(loop));

    theta = inf;
    for k = 2:2:length(loop)
        i = loop{k}(1); j = loop{k}(2);
        theta = min(theta, X(i,j));
    end
    for k = 1:length(loop)
        i = loop{k}(1); j = loop{k}(2);
        X(i,j) = X(i,j) + signs(k)*theta;
        if abs(X(i,j)) < 1e-8
            X(i,j) = 0;
        end
    end
end

function print_optimal_solution(X, C, u, v)
    fprintf('\n=== Optimal Solution ===\n');

    [s, d] = size(X);  % Dimensions

    % Create row and column labels
    row_labels = arrayfun(@(i) sprintf('S%d', i), 1:s, 'UniformOutput', false);
    col_labels = arrayfun(@(j) sprintf('D%d', j), 1:d, 'UniformOutput', false);

    % Print header row
    fprintf('\t');
    fprintf('%8s', col_labels{:});
    fprintf('\n');

    % Print X matrix with row labels
    for i = 1:s
        fprintf('%s\t', row_labels{i});
        fprintf('%8.2f', X(i, :));
        fprintf('\n');
    end
% ================================
% EXPORT OPTIMAL SOLUTION TO LaTeX
% ================================

tex_folder = fullfile(pwd,'TEX_OUTPUT');
if ~exist(tex_folder,'dir')
    mkdir(tex_folder);
end

tex_file = fullfile(tex_folder,'Optimal_Solution_Table.tex');
fid = fopen(tex_file,'w');

if fid ~= -1

    % Begin longtable
    fprintf(fid,'\\begin{longtable}{l%s}\n', repmat('c',1,d));
    fprintf(fid,'\\caption{Optimal Shipping Solution}\\\\\n');
    fprintf(fid,'\\hline\n');

    % Column headers
    fprintf(fid,'Source/Dest ');
    for j = 1:d
        fprintf(fid,' & %s', col_labels{j});
    end
    fprintf(fid,'\\\\ \\hline\n');

    % Table rows
    for i = 1:s
        fprintf(fid,'%s', row_labels{i});
        for j = 1:d
            fprintf(fid,' & %.2f', X(i,j));
        end
        fprintf(fid,'\\\\\n');
    end

    fprintf(fid,'\\hline\n\\end{longtable}\n');
    fclose(fid);

    fprintf('\nLaTeX table exported: %s\n', tex_file);
else
    warning('Could not create LaTeX file for Optimal Solution.');
end

    % Optimal cost
    fprintf('\nOptimal Cost = %.4f\n', sum(sum(X .* C)));
    % Dual variables
    fprintf('\nDual variables (u):\n');
    for i = 1:length(u)
        fprintf('u_%d = %.4f\n', i, u(i));
    end

    fprintf('\nDual variables (v):\n');
    for j = 1:length(v)
        fprintf('v_%d = %.4f\n', j, v(j));
    end

    % =====================================
% EXPORT DUAL VARIABLES (u and v) TO LaTeX
% =====================================

tex_folder = fullfile(pwd,'TEX_OUTPUT');
if ~exist(tex_folder,'dir')
    mkdir(tex_folder);
end

tex_file = fullfile(tex_folder,'Dual_Variables.tex');
fid = fopen(tex_file,'w');

if fid ~= -1

    % Begin longtable
    fprintf(fid,'\\begin{longtable}{lc}\n');
    fprintf(fid,'\\caption{Dual Variables}\\\\\n');
    fprintf(fid,'\\hline\n');
    fprintf(fid,'Variable & Value \\\\ \\hline\n');

    % Write u variables
    for i = 1:length(u)
        fprintf(fid,'$u_{%d}$ & %.4f \\\\\n', i, u(i));
    end

    % Horizontal line between u and v
    fprintf(fid,'\\hline\n');

    % Write v variables
    for j = 1:length(v)
        fprintf(fid,'$v_{%d}$ & %.4f \\\\\n', j, v(j));
    end

    fprintf(fid,'\\hline\n');
    fprintf(fid,'\\end{longtable}\n');

    fclose(fid);
    fprintf('\nLaTeX dual variables exported: %s\n', tex_file);

else
    warning('Could not create LaTeX file for Dual Variables.');
end

    % Compute and print opportunity costs
    fprintf('\nReduced Costs (Opportunity Costs): (k_{ij} = C_{ij} - u_i - v_j):\n');
    for i = 1:s
        for j = 1:d
            if abs(X(i,j)) < 1e-12  % non-basic cell
                kij = C(i,j) - u(i) - v(j);
                fprintf('K(%d,%d) = %.4f\n', i, j, kij);
            end
        end
    end
    % ============================================
% EXPORT REDUCED COSTS (OPPORTUNITY COSTS) TO LaTeXX
% ============================================

tex_folder = fullfile(pwd,'TEX_OUTPUT');
if ~exist(tex_folder,'dir')
    mkdir(tex_folder);
end

tex_file = fullfile(tex_folder,'Opportunity_Costs.tex');
fid = fopen(tex_file,'w');

if fid ~= -1

    fprintf(fid,'\\begin{longtable}{ccc c}\n');
    fprintf(fid,'\\caption{Reduced Costs (Opportunity Costs)}\\\\\n');
    fprintf(fid,'\\hline\n');
    fprintf(fid,'Source & Destination & $K_{ij}$ & Status \\\\ \\hline\n');

    for i = 1:s
        for j = 1:d
            if abs(X(i,j)) < 1e-12   % non-basic cells only
                kij = C(i,j) - u(i) - v(j);

                % Classify cell
                if kij < 0
                    status = 'Improving';
                else
                    status = 'Optimal';
                end

                fprintf(fid,'%d & %d & %.4f & %s \\\\\n', i, j, kij, status);
            end
        end
    end

    fprintf(fid,'\\hline\n');
    fprintf(fid,'\\end{longtable}\n');
    fclose(fid);

    fprintf('\nLaTeX opportunity costs exported: %s\n', tex_file);

else
    warning('Could not create LaTeX file for Opportunity Costs.');
end

end

function print_shipping_list(X, C)
    [m, n] = size(X);

    fprintf('\n=== Shipping List ===\n');

    % Single
    fprintf('%-10s %-15s %-15s %-15s %-15s\n', ...
        'Route #', 'From (Source)', 'To (Destination)', 'Units Shipped', 'Cost');

    route_no = 1;
    total_cost = 0;

    for i = 1:m
        for j = 1:n
            if X(i,j) > 0
                shipment_cost = X(i,j) * C(i,j);
                fprintf('%-10d %-15d %-15d %-15.2f %-15.2f\n', ...
                    route_no, i, j, X(i,j), shipment_cost);
                total_cost = total_cost + shipment_cost;
                route_no = route_no + 1;
            end
        end
    end

    % ============================================
    % EXPORT SHIPPING LIST TO LaTeX
    % ============================================

    tex_folder = fullfile(pwd, 'TEX_OUTPUT');
    if ~exist(tex_folder, 'dir')
        mkdir(tex_folder);
    end

    tex_file = fullfile(tex_folder, 'Shipping_List.tex');
    fid = fopen(tex_file, 'w');

    if fid ~= -1
        % Begin LaTeX table
        fprintf(fid, '\\begin{longtable}{c c c c c}\n');
        fprintf(fid, '\\caption{Shipping List}\\\\\n');
        fprintf(fid, '\\hline\n');
        fprintf(fid, 'Route & Source & Destination & Units & Cost \\\\ \\hline\n');

        % Write data rows
        route_no_latex = 1;
        total_cost_latex = 0;

        for i = 1:m
            for j = 1:n
                if X(i,j) > 0
                    shipment_cost = X(i,j) * C(i,j);
                    fprintf(fid, '%d & %d & %d & %.2f & %.2f \\\\\n', ...
                        route_no_latex, i, j, X(i,j), shipment_cost);
                    total_cost_latex = total_cost_latex + shipment_cost;
                    route_no_latex = route_no_latex + 1;
                end
            end
        end

        % Footer with total cost
        fprintf(fid, '\\hline\n');
        fprintf(fid, '\\multicolumn{4}{r}{\\textbf{Total Cost}} & %.2f \\\\\n', total_cost_latex);
        fprintf(fid, '\\end{longtable}\n');

        fclose(fid);
        fprintf('\nLaTeX Shipping List exported: %s\n', tex_file);
    else
        warning('Could not create Shipping List LaTeX file.');
    end

    fprintf('\nTotal Transportation Cost: %.2f\n', total_cost);
end

function path = find_loop_general(pos, marked, visited, is_row_move)
    [i0, j0] = deal(pos(1), pos(2));
    visited = [visited; pos];
    path = [];

    if size(visited,1) > 3 && isequal(visited(1,:), visited(end,:))
        path = num2cell(visited, 2);
        return;
    end

    if is_row_move
        for j = 1:size(marked,2)
            if j ~= j0 && marked(i0,j)
                next = [i0, j];
                if ~ismember(next, visited, 'rows')
                    path_try = find_loop_general(next, marked, visited, ~is_row_move);
                    if ~isempty(path_try)
                        path = path_try;
                        return;
                    end
                elseif size(visited,1) >= 3 && isequal(next, visited(1,:))
                    path = num2cell([visited; next], 2);
                    return;
                end
            end
        end
    else
        for i = 1:size(marked,1)
            if i ~= i0 && marked(i,j0)
                next = [i, j0];
                if ~ismember(next, visited, 'rows')
                    path_try = find_loop_general(next, marked, visited, ~is_row_move);
                    if ~isempty(path_try)
                        path = path_try;
                        return;
                    end
                elseif size(visited,1) >= 3 && isequal(next, visited(1,:))
                    path = num2cell([visited; next], 2);
                    return;
                end
            end
        end
    end
end

% ===== END OF YOUR MAIN CODE =====
 % of run_SPMC_GUI_New
% Now paste these below:

% === Helper Functions ===

function fillSynthetic(t, lowerBox, upperBox, withProhibited, prohibitBox, dummy_source, dummy_dest)
    data = get(t, 'Data');
    [sPlus1, dPlus1] = size(data);
    s = sPlus1 - 1;
    d = dPlus1 - 1;
    lb = str2double(get(lowerBox, 'String'));
    ub = str2double(get(upperBox, 'String'));
    pval = str2double(get(prohibitBox, 'String')) / 100;
    if isnan(lb) || isnan(ub) || lb >= ub
        errordlg('Invalid lower or upper bound.');
        return;
    end
    if withProhibited && (isnan(pval) || pval < 0 || pval > 1)
        errordlg('Prohibited % must be a number between 0 and 100.');
        return;
    end
for i = 1:s
    for j = 1:d
        if dummy_source && i == s
            data{i,j} = '0';  % dummy row, untouched
        elseif dummy_dest && j == d
            data{i,j} = '0';  % dummy column, untouched
        elseif withProhibited && rand < pval
            data{i,j} = 'Inf';  % prohibited
        else
            data{i,j} = num2str(randi([lb, ub]));  % random
        end
    end
end
    set(t, 'Data', data);
end

function X = ADBAM(A, B, C)
    [m, n] = size(A);
    X = zeros(m, n);
    visited_rows = false(m, 1);
    visited_cols = false(n, 1);
    % Step 1: Select initial column with least demand
    unvisited_C = C;
    unvisited_C(visited_cols) = Inf;
    [~, j_star] = min(unvisited_C);
    % Step 2: Select row with min cost in that column
    valid_rows = find(~visited_rows);
    [~, min_row_idx] = min(A(valid_rows, j_star));
    i_star = valid_rows(min_row_idx);
    while any(~visited_rows) && any(~visited_cols)
        % Allocation
        alloc = min(B(i_star), C(j_star));
        X(i_star, j_star) = alloc;
        B(i_star) = B(i_star) - alloc;
        C(j_star) = C(j_star) - alloc;
        % Mark visited
        row_done = B(i_star) == 0;
        col_done = C(j_star) == 0;
        visited_rows(i_star) = row_done;
        visited_cols(j_star) = col_done;
        if row_done && col_done
            % Pick new min demand column and best row
            unvisited_C = C;
            unvisited_C(visited_cols) = Inf;
            if all(isinf(unvisited_C)), break; end
            [~, j_star] = min(unvisited_C);
            valid_rows = find(~visited_rows);
            [~, min_row_idx] = min(A(valid_rows, j_star));
            i_star = valid_rows(min_row_idx);
        elseif row_done
            % Move to new row in same column
            valid_rows = find(~visited_rows);
            [~, min_row_idx] = min(A(valid_rows, j_star));
            i_star = valid_rows(min_row_idx);
        elseif col_done
            % Move to new column in same row
            valid_cols = find(~visited_cols);
            [~, min_col_idx] = min(A(i_star, valid_cols));
            j_star = valid_cols(min_col_idx);
        end
    end
end