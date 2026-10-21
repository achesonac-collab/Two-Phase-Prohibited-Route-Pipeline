TWO-PHASE PIPELINE FOR PROHIBITED-ROUTE TRANSPORTATION PROBLEMS


This pipeline automates the two-phase cost-transformation method for
prohibited-route transportation problems. The first stage replaces
prohibited routes with shortest-path replacement costs using the
Floyd-Warshall algorithm. The second stage solves the transformed
transportation problem using the Acheson Demand-Based Allocation Method
(ADBAM) for an initial basic feasible solution, followed by the Modified
Distribution (MODI) method for optimality. The pipeline does not use
Big-M penalties.


AUTHORS

Valentine Acheson, Joseph Ackora-Prah, Emmanuel Owusu-Ansah,
Bright Emmanuel Owusu, Francis Cornelius Ennin, Nana Ansah-Sarpong Abu

MAINTAINER / CORRESPONDING AUTHOR

Valentine Acheson - vacheson@st.knust.edu.gh
For bug reports or questions, please open an issue on the repository.


REQUIREMENTS

- MATLAB (tested with R2024b)
- No additional toolboxes required for core functionality
- The 'findjobj.m' utility is included for scrollable table support


FOLDER STRUCTURE

Two-Phase-Prohibited-Route-Pipeline-1.0.0/
├── LICENSE.txt
├── README.txt
├── Main_Scripts/
│   └── Two_Phase_Pipeline.m
├── Core_Functions/
│   ├── SPMC.m
│   ├── ADBAMMODI.m
│   ├── ADBAM.m
│   ├── find_loop_general.m
│   └── export_results_to_tex.m
├── Configuration_Files/
│   ├── dims.m
│   ├── bal.m
│   ├── cost.m
│   └── ISD.m
└── Utilities/
    └── findjobj.m

Note: The folder name uses hyphens. Add all subfolders
to the MATLAB path before running the pipeline.


HOW TO RUN

1. Open MATLAB.
2. Add all subfolders of the Two-Phase-Prohibited-Route-Pipeline-1.0.0 folder to the MATLAB
   path (right-click the folder -> Add to Path -> Selected Folders and
   Subfolders).
3. At the MATLAB prompt, type:

   Two_Phase_Pipeline

4. A dialog box asks how to provide supply and demand data:
   - Option 1: Enter Manually (load from cost.m and ISD.m)
   - Option 2: Use Synthetic Data (generate random data)

The number of sources s and destinations d is always read from dims.m
before either mode starts.


MODE 1: ENTER MANUALLY

1. The script loads:
   - Cost matrix from cost.m (size s x d)
   - Supply and demand vectors from ISD.m

2. The script automatically balances supply and demand:
   - If total supply > total demand: adds a dummy destination
   - If total demand > total supply: adds a dummy source
   - If balanced: proceeds directly

3. The pipeline then:
   - Computes shortest-path replacement costs via SPMC.m
   - Displays the replacement cost matrix
   - Solves the transformed problem with ADBAMMODI.m
   - Exports LaTeX tables to TEX_OUTPUT/


MODE 2: USE SYNTHETIC DATA

1. Enter synthetic data settings:
   - Total Supply, Supply Lower Bound, Supply Upper Bound
   - Total Demand, Demand Lower Bound, Demand Upper Bound

2. The script generates random supply and demand vectors that sum to
   the requested totals, then calls bal.m to balance the problem.

3. An interactive GUI appears for cost-matrix entry:
   - Enter costs manually in the table
   - "Fill (No Prohibited)" generates random costs
   - "Fill (With Prohibited)" generates random costs with prohibited
     routes
   - Set lower/upper bounds for random costs
   - Set prohibited percentage (e.g., 20%)

4. The pipeline then runs the same steps as Mode 1.


GUI CONTROLS

| Control                | Description                                      |
|------------------------|--------------------------------------------------|
| Lower Bound            | Minimum random cost value                        |
| Upper Bound            | Maximum random cost value                        |
| Prohibited %           | Percentage of routes to mark as prohibited       |
| Fill (No Prohibited)   | Random costs without prohibited routes           |
| Fill (With Prohibited) | Random costs with prohibited routes              |
| Submit                 | Submits the table and proceeds to optimization   |


ALGORITHM WORKFLOW

1. DATA ENTRY
   - Manual: load cost.m and ISD.m
   - Synthetic: generate supply/demand, then enter costs in the GUI

2. BALANCE SUPPLY AND DEMAND (bal.m)
   - Add a dummy destination if supply exceeds demand
   - Add a dummy source if demand exceeds supply
   - Proceed directly if balanced

3. CONSTRUCT THE BIPARTITE NETWORK
   - Sources S1..Ss and destinations D1..Dd
   - Direct costs from the cost matrix
   - Prohibited routes marked as Inf

4. COMPUTE REPLACEMENT COSTS (SPMC.m)
   - Floyd-Warshall all-pairs shortest paths
   - Replace prohibited routes with shortest-path replacement costs
   - Extract the s x d replacement cost matrix

5. REPLACE PROHIBITED COSTS
   - Replace Inf entries in the objective coefficient matrix with the
     corresponding replacement costs

6. SOLVE THE TRANSPORTATION PROBLEM (ADBAMMODI.m)
   - ADBAM generates an initial basic feasible solution
   - MODI computes dual variables u and v, reduced costs, and performs
     pivots until all reduced costs are non-negative
   - Repeats until optimal or until the iteration limit is reached

7. EXPORT RESULTS
   - ADBAM_Initial_IBFS.tex
   - Optimal_Solution_Table.tex
   - Dual_Variables.tex
   - Opportunity_Costs.tex
   - Shipping_List.tex


OUTPUT

All LaTeX tables are written to TEX_OUTPUT/ in the current working
directory:

   ADBAM_Initial_IBFS.tex      Initial basic feasible solution
   Optimal_Solution_Table.tex  Optimal shipping solution
   Dual_Variables.tex          Dual variables u and v
   Opportunity_Costs.tex       Reduced costs
   Shipping_List.tex           Shipping list with per-route costs

All tables use the longtable environment.


FILE DESCRIPTIONS

| File                     | Description                                      |
|--------------------------|--------------------------------------------------|
| Two_Phase_Pipeline.m     | Main script (run this)                           |
| SPMC.m                   | Shortest-Path Metric Closure                     |
| ADBAMMODI.m              | ADBAM + MODI solver                              |
| ADBAM.m                  | Demand-Based Allocation Method                   |
| find_loop_general.m      | Loop-finding for the transportation simplex      |
| export_results_to_tex.m  | Exports results to LaTeX                         |
| dims.m                   | Dimensions s and d                               |
| bal.m                    | Balancing script                                 |
| cost.m                   | Manual cost matrix                               |
| ISD.m                    | Manual supply and demand                         |
| findjobj.m               | Java object finder (third-party utility)         |


CONFIGURATION FILES

dims.m
-------
s = number of sources
d = number of destinations

Example:
   s = 3;
   d = 4;

cost.m
-------
Cost matrix of size s x d. Use Inf for prohibited routes.

Example:
   C = [10 20 Inf 15;
        30 15 25 10;
        Inf 20 18 12];

ISD.m
------
Supply (column) and demand (row) vectors.

Example:
   supply = [100; 150; 120];
   demand = [80 110 100 80];

bal.m
------
Balances supply and demand by adding a dummy source or destination.
Called automatically from the main script.


TROUBLESHOOTING

| Issue                                    | Solution                                           |
|------------------------------------------|----------------------------------------------------|
| "Unable to attach scrollpane"            | Ensure findjobj.m is on the MATLAB path.           |
| "Unbalanced problem"                     | bal.m should balance automatically; check that    |
|                                          | bal.m is on the path.                              |
| "No closed loop found"                   | The solver inserts epsilon values to maintain     |
|                                          | non-degeneracy. If this persists, check the cost  |
|                                          | matrix for Inf entries that were not replaced.     |
| LaTeX tables not generated               | Ensure TEX_OUTPUT/ exists or is writable.         |
| "dummy_source undefined"                 | Occurs in synthetic mode before balancing; ensure |
|                                          | dummy_source and dummy_dest are initialised       |
|                                          | before the GUI opens.                              |
| "Index exceeds matrix dimensions"        | Check that cost.m matches s and d in dims.m, and  |
|                                          | that supply and demand lengths match.              |
| "Undefined function or variable"         | Add all subfolders to the MATLAB path.             |
| "Error using questdlg"                   | questdlg requires MATLAB's desktop; it may not    |
|                                          | work in -nodisplay mode.                          |


CUSTOMIZATION

- Synthetic dimensions: edit s and d in dims.m
- Manual cost matrix: edit cost.m (use Inf for prohibited routes)
- Manual supply/demand: edit ISD.m
- Balancing method: edit bal.m
- Epsilon for degeneracy handling: in ADBAMMODI.m,
     epsilon = max(1e-10, min(1e-5, min(C(:))/1e5));
  Apply after prohibited entries have been replaced.
- MODI iteration limit: in uvmethod_transportation, change
     max_iterations = 100;


MATHEMATICAL FORMULATION

The replacement cost stage uses the Floyd-Warshall recurrence:

   D_k(i,j) = min( D_{k-1}(i,j), D_{k-1}(i,k) + D_{k-1}(k,j) )

for k = 1, 2, ..., n, where D_0 is the initial direct cost matrix with
Inf for prohibited routes. The s x d block of the final matrix gives
the replacement costs used in the transportation problem.

The transportation problem is then solved with ADBAM for an initial
basic feasible solution and MODI for optimality.


WHAT THIS CODE DOES NOT DO

- It does not claim optimality guarantees beyond those of the underlying
  transportation solver (ADBAM + MODI).
- It does not handle multi-commodity flows.
- It assumes a weakly connected source-destination graph for feasible
  instances; unreachable required pairs are flagged as infeasible.
- It does not use Big-M penalties.


LICENSE

MIT License (see LICENSE.txt).


CITATION

If you use this code, please cite:

Acheson, V. (2026). Two-Phase Pipeline for Prohibited-Route Transportation Problems (Version v1.0.0) [Computer software].
Zenodo. https://doi.org/10.5281/zenodo.23493305

and the original two-phase method:

Ackora-Prah, J., Acheson, V., Barnes, B., Takyi, I., &
Owusu-Ansah, E. (2022). A two-phase method for solving transportation
models with prohibited routes. Pakistan Journal of Statistics and
Operation Research, 18(3), 749-758.



ACKNOWLEDGEMENTS

findjobj.m is a third-party utility by Yair Altman (MATLAB Central File
Exchange). It is included solely to enable scrollable viewing of the
cost-entry table and is not part of the algorithm.




Thank you for using this pipeline. If you find it useful, please cite the software record above and the original
two-phase method. If you use the results in a publication, please also cite the accompanying manuscript.
